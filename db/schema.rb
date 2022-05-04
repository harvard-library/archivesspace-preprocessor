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

ActiveRecord::Schema.define(version: 2022_05_04_005245) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "concrete_issues", id: :serial, force: :cascade do |t|
    t.integer "run_id", null: false
    t.integer "issue_id", null: false
    t.text "location", null: false
    t.integer "line_number", null: false
    t.text "diagnostic_info", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.jsonb "tags"
    t.integer "finding_aid_version_id", null: false
    t.index ["finding_aid_version_id"], name: "index_concrete_issues_on_finding_aid_version_id"
    t.index ["issue_id"], name: "index_concrete_issues_on_issue_id"
    t.index ["run_id"], name: "index_concrete_issues_on_run_id"
  end

  create_table "finding_aid_versions", id: :serial, force: :cascade do |t|
    t.integer "finding_aid_id", null: false
    t.string "digest", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "unittitle"
    t.string "unitid"
    t.index ["digest"], name: "index_finding_aid_versions_on_digest"
    t.index ["finding_aid_id"], name: "index_finding_aid_versions_on_finding_aid_id"
  end

  create_table "finding_aid_versions_runs", id: false, force: :cascade do |t|
    t.integer "finding_aid_version_id", null: false
    t.integer "run_id", null: false
  end

  create_table "finding_aids", id: :serial, force: :cascade do |t|
    t.integer "repository_id"
    t.string "eadid", null: false
    t.string "ext_id"
    t.string "ext_id_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["eadid"], name: "index_finding_aids_on_eadid"
    t.index ["repository_id"], name: "index_finding_aids_on_repository_id"
  end

  create_table "issues", id: :serial, force: :cascade do |t|
    t.integer "schematron_id", null: false
    t.string "identifier", null: false
    t.string "alternate_issue_id"
    t.text "rule_context"
    t.text "message"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "rule_label"
    t.boolean "manual", default: false, null: false
    t.text "test", null: false
    t.index ["identifier", "schematron_id"], name: "index_issues_on_identifier_and_schematron_id"
    t.index ["schematron_id"], name: "index_issues_on_schematron_id"
  end

  create_table "processing_events", id: :serial, force: :cascade do |t|
    t.integer "run_id"
    t.integer "finding_aid_version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "issue_id", null: false
    t.boolean "failed", default: false, null: false
    t.index ["issue_id"], name: "index_processing_events_on_issue_id"
  end

  create_table "repositories", id: :serial, force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "runs", id: :serial, force: :cascade do |t|
    t.integer "schematron_id", null: false
    t.datetime "completed_at"
    t.integer "eads_processed", default: 0, null: false
    t.boolean "run_for_processing", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "name", null: false
    t.jsonb "data"
    t.index ["schematron_id"], name: "index_runs_on_schematron_id"
  end

  create_table "schematrons", id: :serial, force: :cascade do |t|
    t.string "digest", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["digest"], name: "index_schematrons_on_digest"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "concrete_issues", "issues"
  add_foreign_key "concrete_issues", "runs"
  add_foreign_key "finding_aid_versions", "finding_aids"
  add_foreign_key "finding_aids", "repositories"
  add_foreign_key "issues", "schematrons"
  add_foreign_key "runs", "schematrons"
end
