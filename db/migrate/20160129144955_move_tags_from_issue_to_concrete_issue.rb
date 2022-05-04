class MoveTagsFromIssueToConcreteIssue < ActiveRecord::Migration[4.2]
  class ConcreteIssue < ActiveRecord::Base
    # Guard class for use in migration
  end

  def change
    remove_column :issues, :tags
    add_column :concrete_issues, :tags, :jsonb

    reversible do |dir|
      dir.up do
        ConcreteIssue.reset_column_information
        ConcreteIssue.all.each do |ci|
          ci.tags = ci.diagnostic_info
                    .split("\n")
                    .map {|s| s.match(/([^\s:]+): (.+)/)}
                    .reject(&:blank?)
                    .map {|m| m[1..2]}
                    .to_h
          ci.save!
        end
      end
    end

  end
end
