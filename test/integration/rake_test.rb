require 'test_helper'
class RakeIngestTest < ActionDispatch::IntegrationTest
  def rake(name)
    Rake::Task[name].invoke
  ensure
    Rake::Task[name].reenable
    [Schematron.all, FindingAidVersion.all, FindingAid.all].each { |rel| rel.reload }
  end

  before do
    @s_population = SchematronFile.all.count
    @f_population = FindingAidFile.all.count
    @sch_fname  = File.join(Rails.root, *%w|test test_data test_schematron.xml|)
    @sch_sha    = Digest::SHA256.file(@sch_fname).hexdigest
    @fa_fname   = File.join(Rails.root, *%w|test test_data test_ead.xml|)
    @fa_dir     = File.join(Rails.root, *%w|test test_data test_ead_dir|)
    @fa_sha     = Digest::SHA256.file(@fa_fname).hexdigest
  end

  describe "aspace:ingest:schematron" do
    it "throws if no FILE is provided" do
      begin
        rake "aspace:ingest:schematron"
      rescue RuntimeError => e
         e.message.must_equal("Must have 'FILE' provided in ENV", "should throw if no FILE provided")
      end
    end

    it "can ingest a schematron file" do
      ENV['FILE'] = @sch_fname
      rake "aspace:ingest:schematron"
      Schematron.last.digest.must_equal(@sch_sha)
    end
  end

  describe "aspace:ingest:finding_aid" do
    it "throws if neither FILE nor DIR is provided" do
      begin
        rake "aspace:ingest:finding_aid"
      rescue RuntimeError => e
        e.message.must_equal("Must have EITHER 'FILE' or 'DIR' provided in ENV")
      end
    end

    it "throws if both FILE and DIR are provided" do
      ENV['FILE'] = ENV['DIR'] = @fa_fname
      begin
        rake "aspace:ingest:finding_aid"
      rescue RuntimeError => e
       e.message.must_equal("Must have EITHER 'FILE' or 'DIR' provided in ENV")
      end
    end

    it "can ingest a single finding aid file" do
      ENV['FILE'] = @fa_fname
      rake "aspace:ingest:finding_aid"
      FindingAidVersion.last.digest.must_equal(@fa_sha)
    end

    it "can ingest several finding aid files in a directory" do
      ENV['DIR'] = @fa_dir
      rake "aspace:ingest:finding_aid"
      FindingAidVersion.count.must_equal(Dir[File.join(@fa_dir,"*")].count)
      FindingAidVersion.all.each do |fa|
        fa.digest.must_equal Digest::SHA256.file(File.join(@fa_dir, "#{fa.finding_aid.eadid}.xml")).hexdigest
      end
    end

  end

  describe "aspace:process:analyze" do
    it "can analyze EADs" do
      ENV['FILE'] = @sch_fname
      rake "aspace:ingest:schematron"

      ENV['EADS'] = @fa_dir
      rake "aspace:process:analyze"
      Run.count.must_equal(1)

      run = Run.first
      run.finding_aid_versions.count.must_equal(Dir[File.join(@fa_dir, "*")].count)
      run.run_for_processing.must_equal(false)
      run.processing_events.count.must_equal(0)
    end

    it "can process EADs" do

      # set up "fix" for issue known to exist in ajp00002.xml
      Fixes.definitions do
        fix_for "didm-4" do
          @xml.at_xpath('/ead')['didm4-got-done'] = "true"
        end
      end

      skip('slow') if ENV['SKIP_SLOW_TESTS']
      ENV['FILE'] = @sch_fname
      rake "aspace:ingest:schematron"

      ENV['EADS'] = @fa_dir
      rake "aspace:process:analyze_and_fix"
      Run.count.must_equal(1)

      run = Run.first
      run.run_for_processing.must_equal(true)

      run.processing_events.count.must_equal 2
      assert(
        run.processing_events.map {|e| e.issue.identifier}.all? {|i| i = 'didm-4'},
        "all issues should be didm-4"
      )

    end
  end

  after do
    # Clear input values out of ENV
    %w|FILE DIR EADS|.each { |k| ENV.delete(k) }

    # Classes with files attached (and Run, because of FKey issues)
    # need to be destroyed so the file will get rm'd
    [Run, Schematron, FindingAid].each { |klass| klass.destroy_all }

    unless Dir[File.join(SchematronFile::FILE_DIR, '*.xml')].count == @s_population
      raise "Detritus SchematronFiles left by test"
    end
    unless Dir[File.join(FindingAidFile::FILE_DIR, '*.xml')].count == @f_population
      raise "Detritus FindingAidFiles left by test"
    end
  end

end
