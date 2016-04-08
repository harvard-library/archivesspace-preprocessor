class AddFailedToProcessingEvents < ActiveRecord::Migration
  def change
    add_column :processing_events, :failed, :boolean, null: false, default: false
  end
end
