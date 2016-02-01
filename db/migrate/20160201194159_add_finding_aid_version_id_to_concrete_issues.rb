class AddFindingAidVersionIdToConcreteIssues < ActiveRecord::Migration
  def change
    add_reference :concrete_issues, :finding_aid_version, index: true, null: false
  end
end
