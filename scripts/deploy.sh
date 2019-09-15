#!/usr/bin/env bash

BUILD_VERSION=`git rev-parse HEAD`
LABEL=""`date +%s`
DOCKERFILE="${DOCKERFILE:=Dockerfile}"
WHOAMI=`whoami`
PROJECT_ID="betting-prod"
CLUSTER_NAME="standard-cluster-1"
TAG=us.gcr.io/$PROJECT_ID/betting-server:$LABEL
DEPLOYMENT_NAME="betting-server-prod"
DATABASE_INSTANCE="betting-prod:us-east1:database"
GCLOUD_POSTGRES_USER="${GCLOUD_POSTGRES_USER:=postgres}"
GCLOUD_POSTGRES_DB="${GCLOUD_POSTGRES_DB:=betting}"

function read_input {
  declare -n ret=$1
  prompt_text=$2
  default_value=$3
  force=${4:-false}

  if [[ "$AUTO" != "1" || "$force" = true ]]; then
    read -s -p "$prompt_text" input_value
  fi
  ret=${input_value:=$default_value}
}

function read_confirm {
  declare -n ret=$1
  prompt_text=$2
  default_value=${3:-y}
  force=${4:-false}

  if [[ "$AUTO" != "1" || "$force" = true ]]; then
    read -p "$prompt_text" input_value
  fi
  input_value=${input_value:=$default_value}
  if echo "$input_value" | grep -iq "^n$"; then
    ret=false
  elif echo "$input_value" | grep -iq "^y$"; then
    ret=true
  else
    ret=false
  fi
}

function step_run_migrations {
  database_instance=$1
  database_user=$2
  database_name=$3

  echo "STEP 3: run database migrations and backup"
  read_confirm check_migrations "Do you want to check for database migrations/views? [Y/n] "

  if [ "$check_migrations" = true ]; then
  (
    source ./scripts/gcloud-sql-tunnel $database_instance && \
    gcloud_sql_tunnel_open && \
    (
    if [ "$GCLOUD_SQL_TUNNEL_PORT" -gt "32767" ]; then
      echo
      read_input database_password "Enter database password [default]: " $GCLOUD_POSTGRES_PASSWD true
      export DATABASE_URL=postgres://$database_user:$database_password@localhost:$GCLOUD_SQL_TUNNEL_PORT/$database_name

      echo
      RAILS_ENV=production rake db:migrate
      echo
    else
      echo "ERROR: failed to open SQL tunnel to database"
      exit
    fi
    )
    gcloud_sql_tunnel_close
  ) || error 13
  fi
  echo
}

function step_prepare_docker_image {
  tag=$1
  dockerfile=$2

  echo "Building Docker image from git repository"
  echo
  (
    docker build -t $tag -f $dockerfile . && \
    gcloud docker -- push $tag
  ) || error 12
  echo
}

function step_configure_container {
  project_id=$1
  cluster_name=$2
  deployment_name=$3
  tag=$4

  echo "Applying application image to container"
  
  echo
  (
    gcloud container clusters get-credentials $cluster_name --zone us-east1-b --project $project_id && \
    kubectl set image deployment/$deployment_name betting-server=$tag --record && \
    kubectl get pods --show-labels && \
    kubectl rollout status deployments $deployment_name && \
    kubectl describe pod $deployment_name
    kubectl get pods --show-labels
  ) || error 14
  echo
}

step_prepare_docker_image $TAG $DOCKERFILE && \
step_run_migrations $DATABASE_INSTANCE $GCLOUD_POSTGRES_USER $GCLOUD_POSTGRES_DB && \
step_configure_container $PROJECT_ID $CLUSTER_NAME $DEPLOYMENT_NAME $TAG && \
echo "DONE."