# A record of an action the system has taken, in response to a ConcreteIssue
# found in a FindingAidVersion during the course of a Run
class ProcessingEvent < ApplicationRecord
  belongs_to :issue
  belongs_to :finding_aid_version
  has_one :schematron, through: :runs
  belongs_to :run
end
