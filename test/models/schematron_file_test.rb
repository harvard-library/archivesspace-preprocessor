require 'test_helper'

::SchematronFile::SCH_FILE_DIR = File.join(Rails.root, 'test', 'sch_file_dir')

class SchematronFileTest < ActiveSupport::TestCase
  before do
    @population = Dir[File.join(SchematronFile::SCH_FILE_DIR, '*.xml')].count
    @sf = SchematronFile.new(content)
  end

  describe SchematronFile do
    let(:content) {"<test></test>"}
    let(:expected_digest) {Digest::SHA256.hexdigest(content)}
    let(:expected_path) {File.join(SchematronFile::SCH_FILE_DIR,
                                 "#{expected_digest}.xml")}

    it "creates file at expected location" do
      assert File.exist?(expected_path)
      @sf.path.must_equal expected_path
      @sf.must_respond_to :read
      @sf.read.must_equal content
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
  end

  after do
    File.unlink @sf
    raise "Detritus SchematronFiles left by test" unless Dir[File.join(SchematronFile::SCH_FILE_DIR, '*.xml')].count == @population
  end
end
