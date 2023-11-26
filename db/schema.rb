# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_11_26_181056) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "plpgsql"

  create_table "bets", id: :serial, force: :cascade do |t|
    t.string "prediction"
    t.integer "match_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_bet_id"
    t.index ["match_id"], name: "index_bets_on_match_id"
    t.index ["user_bet_id"], name: "idx_bets_user_bet_id"
  end

  create_table "fixture_bets", id: :serial, force: :cascade do |t|
    t.integer "fixture_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "league_bet_id"
    t.index ["fixture_id"], name: "index_fixture_bets_on_fixture_id"
  end

  create_table "fixtures", id: :serial, force: :cascade do |t|
    t.integer "number"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "league_id"
    t.integer "association_id"
    t.boolean "is_open"
    t.index ["league_id"], name: "idx_fixtures_league_id"
  end

  create_table "league_bets", id: :serial, force: :cascade do |t|
    t.integer "league_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_league_bets_on_league_id"
  end

  create_table "leagues", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "season"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "association_id"
  end

  create_table "matches", id: :serial, force: :cascade do |t|
    t.string "score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fixture_id"
    t.integer "home_team_id"
    t.integer "away_team_id"
    t.integer "association_id"
    t.datetime "date"
    t.float "home_odds"
    t.float "away_odds"
    t.index ["away_team_id"], name: "away_team_id_pkey"
    t.index ["fixture_id"], name: "idx_matches_fixture_id"
    t.index ["home_team_id"], name: "home_team_id_pkey"
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "association_id"
    t.integer "one_id"
    t.index ["one_id"], name: "index_teams_on_one_id"
  end

  create_table "user_bets", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "bet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fixture_bet_id"
    t.index ["bet_id"], name: "index_user_bets_on_bet_id"
    t.index ["user_id"], name: "index_user_bets_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "email"
    t.string "auth_token"
  end

  add_foreign_key "bets", "matches"
  add_foreign_key "fixture_bets", "fixtures"
  add_foreign_key "fixtures", "leagues", name: "fixtures_league_id_fkey"
  add_foreign_key "league_bets", "leagues"
  add_foreign_key "matches", "fixtures", name: "matches_fixture_id_fkey"
  add_foreign_key "matches", "teams", column: "away_team_id", name: "matches_away_team_id_fkey"
  add_foreign_key "matches", "teams", column: "home_team_id", name: "matches_home_team_id_fkey"
  add_foreign_key "user_bets", "bets"
  add_foreign_key "user_bets", "fixture_bets", name: "user_bets_fixture_bet_id_fkey"
  add_foreign_key "user_bets", "users"
end
