# An action the system can take in response to an Issue
# that it finds in a FindingAidVersion
class Remediation < ActiveRecord::Base
  has_many :processing_events
  has_many :issues, foreign_key: :issue_identifier, primary_key: :identifier
end
