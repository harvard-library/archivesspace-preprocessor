# A particular problem that can occur in EAD files
class Issue < ActiveRecord::Base
  belongs_to :schematron, inverse_of: :issues
  has_many :concrete_issues, dependent: :destroy

  validates *%w{ identifier
                 alternate_issue_id
                 rule_context
                 message
                 rule_label
                 test }, presence: true
  validates :manual, inclusion: {in: [true, false]}
end
