class AddManualToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :manual, :boolean, null: false, default: false
  end
end
