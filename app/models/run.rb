require 'java'

# A process consisting of the following steps, repeated over
# the current version of each FindingAid:
#
# 1. Execute schematron checker against finding aid
# 2. Record ConcreteIssues against FindingAidVersions
# 3. Apply relevant Fixes to finding aids, producing amended XML
# 4. Record ProcessingEvents (this step happens during fix application)
# 5. Save final XML result to file
#
# Steps 2-4 may happen repeatedly if necessary
class Run < ActiveRecord::Base
  # Directory to output files as ingested
  INPUT_DIR =  File.join(Rails.root, 'public', 'input')

  # Directory to output processed files
  OUTPUT_DIR = File.join(Rails.root, 'public', 'output')

  # Maximum number of additional passes of checker/fixes to run
  # after preflights and initial pass
  MAX_PASSES = ENV.fetch('MAX_PASSES', 5)

  belongs_to :schematron
  has_and_belongs_to_many :finding_aid_versions
  has_many :concrete_issues, dependent: :destroy
  has_many :processing_events, dependent: :destroy

  # Run checker over a set of provided faids, storing information
  # on found errors in the database
  def perform_analysis(faids)
    @checker = Checker.new(schematron, self)
    faids.each do |faid|
      faid = faid.current if faid.is_a? FindingAid
      ActiveRecord::Base.transaction do
        @checker.check(faid).each do |h|
          ConcreteIssue.create!(h)
        end
        self.finding_aid_versions << faid
        self.increment! :eads_processed
      end
    end
  end

  # Helper method that performs one step of reduction
  def apply_fix(xml, fix, pe = nil)
    begin
      pre_fix_xml = xml.dup
    # HAX: Swallow mysterious namespace failure, come ON Noko
    rescue Java::OrgW3cDom::DOMException => e
      pre_fix_xml = Nokogiri::XML(xml.serialize, nil, 'UTF-8') {|config| config.nonet}
    end

    begin # In case of failure, catch the XML
      fix.(xml)
    rescue Fixes::Failure, StandardError => e
      pe.update(failed: true) if pe
      logger.tagged('Fixes') {
        logger.warn { "Failed with #{e.class}: #{e.message}" }
        logger.warn {"ProcessingEvent: #{pe.id}, Issue identifier: #{pe.issue.identifier}" }
        logger.warn { "Locations:\n#{e.backtrace.grep(/fixes\//).map {|el| "\t" + el}.join("\n")}" }
      }
      pre_fix_xml
    end
  end

  # Take an analyzed run, and process the finding aids through all
  # relevant fixes.  Record events in ProcessingEvents table.
  def perform_processing!
    raise "This run is already processed!" if run_for_processing
    update(run_for_processing: true)
    outdir = File.join(OUTPUT_DIR, "#{id}").shellescape
    indir =  File.join(INPUT_DIR,  "#{id}").shellescape
    Dir.mkdir(outdir, 0755) unless File.directory?(outdir)
    Dir.mkdir(indir, 0755) unless File.directory?(indir)

    # Stream input files to zip
    zout_in = java.util.zip.ZipOutputStream.new(File.open(File.join(indir, 'input.zip'), 'wb', 0644).to_outputstream)
    zout_out = java.util.zip.ZipOutputStream.new(File.open(File.join(outdir, 'out.zip'), 'wb', 0644).to_outputstream)

    finding_aid_versions
      .joins(:finding_aid, :concrete_issues => :issue)
      .select('finding_aid_versions.*,
               finding_aids.eadid,
               ARRAY_AGG(DISTINCT issues.identifier) AS identifiers')
      .group('finding_aids.eadid,finding_aid_versions.id')
      .each do |fa|
        add_to_zip(zout_in, fa.eadid, fa.file)

        # Preflight XML
        fa_xml = Fixes.preflights.values.reduce(fa.xml) do |xml, fix|
          apply_fix(xml, fix)
        end

        # Apply all relevant fixes to Finding Aid
        repaired = Fixes
                   .to_h
                   .select {|identifier, _| fa.identifiers.include? identifier}
                   .reduce(fa_xml) do|xml, (identifier, fix)|
          pe = processing_events.create(issue_id: schematron.issues.find_by(identifier: identifier).id,
                                        finding_aid_version_id: fa.id)
          apply_fix(xml, fix, pe)

        end # end of .reduce

        # Any problems which have fixes that exist now should theoretically
        # be things that were shadowed by the first pass, so take additional passes
        # untill either no known issues or MAX_PASSES
        MAX_PASSES.times do
          remaining_problems = schematron.issues.where(id: @checker.check_str(repaired.serialize(encoding: 'UTF-8')).map {|el| el[:issue_id]}.uniq).pluck(:identifier) & Fixes.to_h.keys

          # Run a second round of fixing if there are remaining problems
          break if remaining_problems.blank?
          repaired = Fixes
                     .to_h
                     .select {|identifier, _| remaining_problems.include? identifier}
                     .reduce(repaired) do |xml, (identifier, fix)|
            pe = processing_events.create(issue_id: schematron.issues.find_by(identifier: identifier).id,
                                          finding_aid_version_id: fa.id)
            apply_fix(xml, fix, pe)
          end
        end


        # Add notice of processing to revisiondesc
        today = DateTime.now.in_time_zone

        rd = repaired.at_xpath('/ead/eadheader/revisiondesc') || repaired.at_xpath('/ead/eadheader').add_child('<revisiondesc />').first
        rd.prepend_child(Nokogiri::XML::DocumentFragment.new(repaired, "\n" + <<-FRAGMENT.strip_heredoc + "\n"))
          <change>
            <date calendar="gregorian" era="ce" normal="#{today.strftime('%Y%m%d')}">#{today.strftime('%m/%d/%Y')}</date>
            <item>This resource was modified by the ArchivesSpace Preprocessor developed by the Harvard Library (https://github.com/harvard-library/archivesspace-preprocessor)</item>
          </change>
        FRAGMENT

        File.open(File.join(outdir, "#{fa.eadid}.xml"), 'w', 0644) do |f|
          repaired.write_xml_to(f, encoding: 'UTF-8')
        end

        add_to_zip(zout_out, fa.eadid, File.open(File.join(outdir, "#{fa.eadid}.xml"), 'r'))
    end

    update(completed_at: DateTime.now)
  ensure
    close_zipfiles(zout_in, zout_out)
  end

  # Convenience method for doing analysis and processing in one go.
  def perform_processing_run(faids)
    perform_analysis(faids)
    perform_processing!
  end

  # Convenience method for adding to zip
  # @param zout [Java::Util::Zip::ZipOutputStream] the zip being written to
  # @param eadid [String] the eadid, used to construct filename in zip
  # @param file [File] an open file containing to add to zip
  def add_to_zip(zout, eadid, file)
    zout.put_next_entry(java.util.zip.ZipEntry.new("#{eadid}.xml"))
    file.binmode
    file.each_line do |line|
      bytes = line.to_java_bytes
      zout.write(bytes, 0, bytes.length)
    end
    file.close
  end

  # Convenience method for closing zipfiles
  # @param zouts [Array<Java::Util::Zip::ZipOutputStream>] zipfiles what need closing
  def close_zipfiles(*zouts)
    zouts.each do |zout|
      begin
        zout.close
      rescue java.io.IOException => e
        # already closed, nothing to do here
      end
    end
  end

end
