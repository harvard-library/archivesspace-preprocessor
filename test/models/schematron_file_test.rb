require 'test_helper'

class SchematronFileTest < ActiveSupport::TestCase
  before do
    @population = Dir[File.join(SchematronFile::SCH_FILE_DIR, '*.xml')].count
    @sf = SchematronFile.new(content)
  end

  describe SchematronFile do
    let(:content) {
      IO.read(File.join(Rails.root, 'test', 'test_data', 'test_schematron.sch'))
    }
    let(:expected_digest) {Digest::SHA256.hexdigest(content)}
    let(:expected_path) {File.join(SchematronFile::SCH_FILE_DIR,
                                 "#{expected_digest}.xml")}

    it "creates file at expected location" do
      assert File.exist?(expected_path)
      @sf.path.must_equal expected_path
      @sf.must_respond_to :read
      @sf.read.must_equal content
    end

    it "is named based on digest, and digest is correct" do
      @sf.digest.must_equal expected_digest
      @sf.path.must_equal(File.join(SchematronFile::SCH_FILE_DIR,
                                    "#{@sf.digest}.xml"))
    end

    it "can fetch file from registry" do
      me = SchematronFile[expected_digest]
      me.path.must_equal @sf.path
    end

    it "does not create new file if file exists already" do
      beforetimes = DateTime.now
      dup_stronfile = SchematronFile.new(content)
      dup_stronfile.ctime.must_equal @sf.ctime
      assert dup_stronfile.ctime < beforetimes
    end

    it "can list all SchematronFiles" do
      assert SchematronFile.all.map(&:digest).include?(@sf.digest), "does not contain @sf"
    end

    it "can list paths of all schematron files containing test object" do
      assert SchematronFile.filenames.include? @sf.path
    end

    it "can list all digests that including the digest of test object" do
      assert SchematronFile.digests.include? @sf.digest
    end
  end

  after do
    File.unlink @sf
    raise "Detritus SchematronFiles left by test" unless Dir[File.join(SchematronFile::SCH_FILE_DIR, '*.xml')].count == @population
  end
end
