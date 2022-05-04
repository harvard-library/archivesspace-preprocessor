class AddTagsToIssue < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :tags, :jsonb
  end
end
