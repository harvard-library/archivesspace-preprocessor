require 'test_helper'

class FindingAidVersionTest < ActiveSupport::TestCase
  before do
    @population = FindingAidFile.all.count
    @faf = FindingAidFile.new( IO.read(File.join(Rails.root, 'test', 'test_data', 'test_ead.xml')) )
    @finding_aid_version = FindingAidVersion.create( @faf.fav_attr )
  end

  describe FindingAidVersion do
    it "can save a FindingAid version" do
      faid = FindingAidVersion.find(@finding_aid_version.id)
      faid.touch
      assert faid.save, "FindingAidVersion failed with: #{faid.errors.keys.join(', ')}"
    end

    it "can return an XML representation of itself" do
      xml = @finding_aid_version.xml
      xml.must_be_kind_of(Nokogiri::XML::Document)
      xml.at_xpath("//eadid")["identifier"].must_equal "007903030"
    end

    it "will not create a finding_aid_version without a valid digest" do
      record = FindingAidVersion.create
      record.persisted?.must_equal false
    end
  end

  after do
    @finding_aid_version.destroy!
    unless Dir[File.join(FindingAidFile::FILE_DIR, '*.xml')].count == @population
      raise "Detritus FindingAidFiles left by test"
    end
  end
end
