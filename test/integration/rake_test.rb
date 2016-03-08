require 'test_helper'
class RakeIngestTest < ActionDispatch::IntegrationTest
  def rake(name)
    Rake::Task[name].invoke
  ensure
    Rake::Task[name].reenable
    [Schematron.all, FindingAidVersion.all, FindingAid.all].each { |rel| rel.reload }
  end

  before do
    @population = SchematronFile.all.count
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

  after do
    %w|FILE DIR|.each { |k| ENV.delete(k) }
    Schematron.destroy_all
    FindingAid.destroy_all
    unless Dir[File.join(SchematronFile::FILE_DIR, '*.xml')].count == @population
      raise "Detritus SchematronFiles left by test"
    end
  end

end
