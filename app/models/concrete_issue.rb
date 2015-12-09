# An expression of an Issue in a particular FindingAidVersion on a particular Run.
class ConcreteIssue < ActiveRecord::Base
  belongs_to :run
  belongs_to :issue
end
