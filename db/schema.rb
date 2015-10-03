# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150915114146) do

  create_table "bets", force: :cascade do |t|
    t.string   "prediction"
    t.integer  "match_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "user_bet_id"
  end

  add_index "bets", ["match_id"], name: "index_bets_on_match_id"

  create_table "fixture_bets", force: :cascade do |t|
    t.integer  "fixture_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "league_bet_id"
  end

  add_index "fixture_bets", ["fixture_id"], name: "index_fixture_bets_on_fixture_id"

  create_table "fixtures", force: :cascade do |t|
    t.integer  "number"
    t.date     "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "league_id"
  end

  create_table "league_bets", force: :cascade do |t|
    t.integer  "league_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "league_bets", ["league_id"], name: "index_league_bets_on_league_id"

  create_table "leagues", force: :cascade do |t|
    t.string   "name"
    t.string   "season"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "matches", force: :cascade do |t|
    t.string   "score"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "fixture_id"
    t.integer  "home_team_id"
    t.integer  "away_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_bets", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "bet_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "fixture_bet_id"
  end

  add_index "user_bets", ["bet_id"], name: "index_user_bets_on_bet_id"
  add_index "user_bets", ["user_id"], name: "index_user_bets_on_user_id"

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "password_digest"
    t.string   "email"
  end

end
