class AddRuleLabelToIssues < ActiveRecord::Migration[4.2]
  def change
    add_column :issues, :rule_label, :text
  end
end
