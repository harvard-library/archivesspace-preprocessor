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

ActiveRecord::Schema.define(version: 20160104173356) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "concrete_issues", force: :cascade do |t|
    t.integer  "run_id",                       null: false
    t.integer  "issue_id",                     null: false
    t.text     "location",                     null: false
    t.integer  "line_number",                  null: false
    t.text     "diagnostic_info", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "concrete_issues", ["issue_id"], name: "index_concrete_issues_on_issue_id", using: :btree
  add_index "concrete_issues", ["run_id"], name: "index_concrete_issues_on_run_id", using: :btree

  create_table "finding_aid_versions", force: :cascade do |t|
    t.integer  "finding_aid_id",             null: false
    t.string   "digest",         limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finding_aid_versions", ["digest"], name: "index_finding_aid_versions_on_digest", using: :btree
  add_index "finding_aid_versions", ["finding_aid_id"], name: "index_finding_aid_versions_on_finding_aid_id", using: :btree

  create_table "finding_aid_versions_runs", id: false, force: :cascade do |t|
    t.integer "finding_aid_version_id", null: false
    t.integer "run_id",                 null: false
  end

  create_table "finding_aids", force: :cascade do |t|
    t.integer  "repository_id"
    t.string   "eadid",         limit: 255, null: false
    t.string   "ext_id",        limit: 255
    t.string   "ext_id_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finding_aids", ["eadid"], name: "index_finding_aids_on_eadid", using: :btree
  add_index "finding_aids", ["repository_id"], name: "index_finding_aids_on_repository_id", using: :btree

  create_table "issues", force: :cascade do |t|
    t.integer  "schematron_id",                                  null: false
    t.string   "identifier",         limit: 255,                 null: false
    t.string   "alternate_issue_id", limit: 255
    t.text     "rule_context"
    t.text     "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb    "tags"
    t.text     "rule_label"
    t.boolean  "manual",                         default: false, null: false
  end

  add_index "issues", ["identifier", "schematron_id"], name: "index_issues_on_identifier_and_schematron_id", using: :btree
  add_index "issues", ["schematron_id"], name: "index_issues_on_schematron_id", using: :btree

  create_table "processing_events", force: :cascade do |t|
    t.integer  "remediation_id"
    t.integer  "run_id"
    t.integer  "finding_aid_version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "remediations", force: :cascade do |t|
    t.string   "issue_identifier", limit: 255, null: false
    t.string   "identifier",       limit: 255, null: false
    t.text     "description",                  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "remediations", ["issue_identifier"], name: "index_remediations_on_issue_identifier", using: :btree

  create_table "repositories", force: :cascade do |t|
    t.string   "code",       limit: 255, null: false
    t.string   "name",       limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "runs", force: :cascade do |t|
    t.integer  "schematron_id",                  null: false
    t.datetime "completed_at"
    t.integer  "eads_processed",     default: 0, null: false
    t.boolean  "run_for_processing",             null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "runs", ["schematron_id"], name: "index_runs_on_schematron_id", using: :btree

  create_table "schematrons", force: :cascade do |t|
    t.string   "digest",     limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "schematrons", ["digest"], name: "index_schematrons_on_digest", using: :btree

  add_foreign_key "concrete_issues", "issues"
  add_foreign_key "concrete_issues", "runs"
  add_foreign_key "finding_aid_versions", "finding_aids"
  add_foreign_key "finding_aids", "repositories"
  add_foreign_key "issues", "schematrons"
  add_foreign_key "runs", "schematrons"
end
