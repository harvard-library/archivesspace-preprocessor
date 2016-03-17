# A process consisting of the following steps, repeated over
# the current version of each FindingAid:
#
# 1. Execute schematron checker against finding aid
# 2. Record ConcreteIssues against FindingAidVersions
# 3. Apply relevant Fixes to finding aids, producing amended XML
# 4. Record ProcessingEvents (this step happens fix application)
# 5. Save final XML result to file
class Run < ActiveRecord::Base
  # Directory to output processed files
  OUTPUT_DIR = File.join(Rails.root, 'system', 'output')

  belongs_to :schematron
  has_and_belongs_to_many :finding_aid_versions
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
        self.finding_aid_versions << faid
        self.increment! :eads_processed
      end
    end

  end

  # Take an analyzed run, and process the finding aids through all
  # relevant fixes.  Record events in ProcessingEvents table.
  def perform_processing!
    raise "This run is already processed!" if run_for_processing
    update(run_for_processing: true)
    outdir = File.join(OUTPUT_DIR, "#{id}")
    Dir.mkdir(outdir, 0700) unless File.directory?(outdir)

    finding_aid_versions
      .joins(:finding_aid, :concrete_issues => :issue)
      .select('finding_aid_versions.*,
               finding_aids.eadid,
               ARRAY_AGG(DISTINCT issues.identifier) AS identifiers')
      .group('finding_aids.eadid,finding_aid_versions.id')
      .each do |fa|
        # Apply all relevant fixes to Finding Aid
      repaired = Fixes
                 .to_h
                 .select {|issue_id, _| fa.identifiers.include? issue_id}
                 .reduce(fa.xml) do|xml, (issue_id, fix)|
        processing_events.create(issue_id: Issue.find_by(identifier: issue_id).id,
                                 finding_aid_version_id: fa.id)
        fix.(xml)
      end

      File.open(File.join(outdir, "#{fa.eadid}.xml"), 'w') do |f|
        repaired.write_xml_to(f, encoding: 'UTF-8')
      end
    end

  end

  # Convenience method for doing analysis and processing in one go.
  def perform_processing_run(faids)
    perform_analysis(faids)
    perform_processing!
  end
end
