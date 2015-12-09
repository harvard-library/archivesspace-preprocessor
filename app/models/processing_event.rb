# A record of an action the system has taken, in response to a ConcreteIssue
# found in a FindingAidVersion during the course of a Run
class ProcessingEvent < ActiveRecord::Base
  belongs_to :remediation
  belongs_to :finding_aid_version
  has_one :schematron, through: :runs
  belongs_to :run
end
