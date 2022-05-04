class AddFailedToProcessingEvents < ActiveRecord::Migration[4.2]
  def change
    add_column :processing_events, :failed, :boolean, null: false, default: false
  end
end
