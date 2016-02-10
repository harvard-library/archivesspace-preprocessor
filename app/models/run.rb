# A process consisting of the following steps, repeated over
# the current version of each FindingAid:
#
# 1. Execute schematron checker against each finding aid
# 2. Record ConcreteIssues against FindingAidVersions
# 3. Apply Remediations to finding aids to produce amended versions
# 4. Record ProcessingEvents
class Run < ActiveRecord::Base
  belongs_to :schematron
  has_many :concrete_issues, dependent: :destroy
  has_many :processing_events, dependent: :destroy

  # Run checker over a set of provided faids, storing information
  # on found errors in the database
  def perform_analysis(faids)
    checker = Checker.new(schematron, self)
    faids.each do |faid|
      faid = faid.current if faid.is_a? FindingAid
      ActiveRecord::Base.transaction do
        checker.check(faid).each do |h|
          ConcreteIssue.create!(h)
        end
        self.increment! :eads_processed
      end
    end

  end
end
