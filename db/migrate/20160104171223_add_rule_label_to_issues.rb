class AddRuleLabelToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :rule_label, :text
  end
end
