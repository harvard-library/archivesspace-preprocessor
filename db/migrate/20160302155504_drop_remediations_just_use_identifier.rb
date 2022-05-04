class DropRemediationsJustUseIdentifier < ActiveRecord::Migration[4.2]
  def change
    drop_table :remediations do |t|
      t.string :issue_identifier, null: false, index: :unique # effective FKey to issues.identifier
      t.string :identifier, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_reference :processing_events, :issue, index: true, null: false
    remove_column :processing_events, :remediation_id, :integer, index: true
  end
end
