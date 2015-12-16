require 'test_helper'

class SchematronFileTest < ActiveSupport::TestCase
  before do
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
  end

  after do
    File.unlink @sf
  end
end
