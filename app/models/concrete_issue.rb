# An expression of an Issue in a particular FindingAidVersion on a particular Run.
class ConcreteIssue < ActiveRecord::Base
  belongs_to :run
  belongs_to :issue
  belongs_to :finding_aid_version

  before_save :generate_tags_from_diagnostic_info

  # Process the raw <diagnostic_info> into a hash suitable for JSON storage
  #
  # @returns [Hash]
  def generate_tags_from_diagnostic_info
    self.tags = diagnostic_info
                .split("\n")
                .map {|s| s.match(/([^\s:]+): (.+)/)}
                .reject(&:blank?)
                .map {|m| m[1..2]}
                .to_h
  end
end
