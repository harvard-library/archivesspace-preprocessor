class AddManualToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :manual, :boolean, null: false, default: false
  end
end
