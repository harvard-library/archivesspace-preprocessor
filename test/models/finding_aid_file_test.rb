require 'test_helper'

class FindingAidFileTest < ActiveSupport::TestCase
  before do
    @population = Dir[File.join(FindingAidFile::FILE_DIR, '*.xml')].count
    @fa = FindingAidFile.new(content)
  end

  describe FindingAidFile do
    let(:content) {
      IO.read(File.join(Rails.root, 'test', 'test_data', 'test_ead.xml'))
    }
    let(:expected_digest) {Digest::SHA256.hexdigest(content)}
    let(:expected_path) {File.join(FindingAidFile::FILE_DIR,
                                 "#{expected_digest}.xml")}

    it "creates file at expected location" do
      assert File.exist?(expected_path)
      @fa.path.must_equal expected_path
      @fa.must_respond_to :read
      @fa.read.must_equal content
    end

    it "is named based on digest, and digest is correct" do
      @fa.digest.must_equal expected_digest
      @fa.path.must_equal(File.join(FindingAidFile::FILE_DIR,
                                    "#{@fa.digest}.xml"))
    end

    it "can fetch file from registry" do
      me = FindingAidFile[expected_digest]
      me.path.must_equal @fa.path
    end

    it "does not create new file if file exists already" do
      beforetimes = DateTime.now
      dup_stronfile = FindingAidFile.new(content)
      dup_stronfile.ctime.must_equal @fa.ctime
      assert dup_stronfile.ctime < beforetimes
    end

    it "can list all FindingAidFiles" do
      assert FindingAidFile.all.map(&:digest).include?(@fa.digest), "does not contain @fa"
    end

    it "can list paths of all finding aid files containing test object" do
      assert FindingAidFile.filenames.include? @fa.path
    end

    it "can list all digests that including the digest of test object" do
      assert FindingAidFile.digests.include? @fa.digest
    end
  end

  after do
    File.unlink @fa
    unless Dir[File.join(FindingAidFile::FILE_DIR, '*.xml')].count == @population
      raise "Detritus FindingAidFiles left by test"
    end
  end
end
