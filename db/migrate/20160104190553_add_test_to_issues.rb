class AddTestToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :test, :text, null: false
  end
end
