require 'test_helper'

class FindingAidVersionTest < ActiveSupport::TestCase
  before do
    @population = FindingAidFile.all.count
    @faf = FindingAidFile.new( IO.read(File.join(Rails.root, 'test', 'test_data', 'test_ead.xml')) )
    @finding_aid_version = FindingAidVersion.create( digest: @faf.digest )
  end

  describe FindingAidVersion do
    it "can save a FindingAid version" do
      faid = FindingAidVersion.find(@finding_aid_version.id)
      faid.touch
      assert faid.save, "FindingAidVersion failed with: #{faid.errors.keys.join(', ')}"
    end
  end

  after do
    @finding_aid_version.destroy!
    unless Dir[File.join(FindingAidFile::FILE_DIR, '*.xml')].count == @population
      raise "Detritus FindingAidFiles left by test"
    end
  end
end
