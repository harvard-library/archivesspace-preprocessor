# A particular problem that can occur in EAD files
class Issue < ApplicationRecord
  belongs_to :schematron, inverse_of: :issues
  has_many :concrete_issues, dependent: :destroy
  has_many :processing_events

  validates *%w{ identifier
                 alternate_issue_id
                 rule_context
                 message
                 rule_label
                 test }, presence: true
  validates :manual, inclusion: {in: [true, false]}
end
