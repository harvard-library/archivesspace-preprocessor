class AddTagsToIssue < ActiveRecord::Migration
  def change
    add_column :issues, :tags, :jsonb
  end
end
