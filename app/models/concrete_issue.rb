# An expression of an Issue in a particular FindingAidVersion on a particular Run.
class ConcreteIssue < ApplicationRecord
  belongs_to :run
  belongs_to :issue
  belongs_to :finding_aid_version
end
