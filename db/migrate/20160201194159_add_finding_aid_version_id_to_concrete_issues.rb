class AddFindingAidVersionIdToConcreteIssues < ActiveRecord::Migration[4.2]
  def change
    add_reference :concrete_issues, :finding_aid_version, index: true, null: false
  end
end
