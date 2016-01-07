class AddTestToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :test, :text, null: false
  end
end
