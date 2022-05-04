require 'test_helper'
require 'rake'
class RakeIngestTest < ActionDispatch::IntegrationTest
  def rake(name)
    Rake::Task[name].invoke
  ensure
    Rake::Task[name].reenable
    [Schematron.all, FindingAidVersion.all, FindingAid.all].each { |rel| rel.reload }
  end

  before do
    @s_population = Dir[File.join(SchematronFile::FILE_DIR, '*.xml')].count
    @f_population = Dir[File.join(FindingAidFile::FILE_DIR, '*.xml')].count
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
      run.name.must_equal("test_ead_dir")
      run.run_for_processing.must_equal(false)
      run.processing_events.count.must_equal(0)
    end

    it "can set name explicitly" do
      ENV['FILE'] = @sch_fname
      rake "aspace:ingest:schematron"

      ENV['EADS'] = @fa_dir
      ENV['NAME'] = 'Charles'
      rake "aspace:process:analyze"

      Run.first.name.must_equal('Charles')
    end

    it "can process EADs" do
      skip('slow') if ENV['SKIP_SLOW_TESTS']

      Fixes.definitions do
        fix_for "didm-4" do
          @xml.xpath("/ead/archdesc/*[not(local-name(.) = 'did')]//did[count(./unitdate|./unittitle) = 0]").each do |did|
            if head = did.at_xpath('./head')
              ut = Nokogiri::XML::Node.new "unittitle", @xml
              ut.children = head.children
              did.add_child ut
            else
              insert_us = Nokogiri::XML::NodeSet.new(@xml)
              cursor = did.ancestors('c,archdesc').first

              # Walk up until we hit a c or archdesc with relevant content
              while (insert_us.empty? && cursor)
                insert_us += cursor.xpath('./did/unittitle|./did/unitdate')
                cursor = cursor.ancestors('c,archdesc').first
              end

              if !insert_us.empty?
                insert_us = Nokogiri::XML::NodeSet.new(
                  @xml,
                  insert_us.map do |el|
                    me = el.dup
                    me['id'] = "#{SecureRandom.hex}__copy_of__#{el['id']}" if el['id']
                    me
                  end
                )
                did.children += insert_us
              else
                raise Fixes::Failure
              end
            end
          end
        end
      end

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
    %w|FILE DIR EADS NAME|.each { |k| ENV.delete(k) }

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
