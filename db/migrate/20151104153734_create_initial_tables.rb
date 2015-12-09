class CreateInitialTables < ActiveRecord::Migration
  def change

    # Schematron versions, identified by hash of file contents
    create_table :schematrons do |t|
      t.string :digest, index: :unique, null: false

      t.timestamps
    end

    # Institutions that produce EAD files
    create_table :repositories do |t|
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps
    end

    # Runs of the software against a corpus of EAD files
    create_table :runs do |t|
      t.references :schematron, index: true, foreign_key: true, null: false

      t.datetime :completed_at, null: true
      t.integer :eads_processed, default: 0, null: false
      t.boolean :run_for_processing, null: false

      t.timestamps
    end

    # Possible errors that can be found in EAD files
    create_table :issues do |t|
      t.references :schematron, index: true, foreign_key: true, null: false

      t.string :identifier, null: false
      t.string :alternate_issue_id
      t.string :rule_context
      t.string :message

      t.timestamps
    end

    add_index :issues, [:identifier, :schematron_id]

    # Errors found in particular EAD files
    create_table :concrete_issues do |t|
      t.references :run, index: true, foreign_key: true, null: false
      t.references :issue, index: true, foreign_key: true, null: false

      t.string :location, null: false
      t.integer :line_number, null: false
      t.text :diagnostic_info, null: false, default: ""

      t.timestamps
    end

    # EAD Finding aids (logical representation thereof, identified by EADID)
    create_table :finding_aids do |t|
      t.references :repository, index: true, foreign_key: true

      t.string :eadid, null: false, index: :unique
      t.string :ext_id
      t.string :ext_id_type

      t.timestamps
    end

    # Particular version of a finding aid, identified by hash of file contents
    create_table :finding_aid_versions do |t|
      t.references :finding_aid, index: true, foreign_key: true, null: false

      t.string :digest, index: :unique, null: false

      t.timestamps
    end

    # Possible fixes than can be applied to EADs to fix particular issues
    create_table :remediations do |t|
      t.string :issue_identifier, null: false, index: :unique # effective FKey to issues.identifier
      t.string :identifier, null: false
      t.string :description, null: false

      t.timestamps
    end

    # List of fixes applied to individual finding aids
    create_table :processing_events do |t|
      t.references :remediation
      t.references :run
      t.references :finding_aid_version

      t.timestamps
    end

    create_join_table :finding_aid_versions, :runs

  end
end
