require 'test_helper'

class SchematronTest < ActiveSupport::TestCase
  before do
    @population = Dir[File.join(SchematronFile::FILE_DIR, '*.xml')].count

    @schematron = Schematron.create_from_file(
      File.open(File.join(Rails.root, 'test', 'test_data', 'test_schematron.xml'))
    )
  end

  describe Schematron do
    it "can save a schematron" do
      stron = Schematron.find(@schematron.id)
      stron.touch
      assert stron.save, "Schematron failed with: #{stron.errors.keys.join(', ')}"
    end
  end

  after do
    @schematron.destroy!
    unless Dir[File.join(SchematronFile::FILE_DIR, '*.xml')].count == @population
      raise "Detritus SchematronFiles left by test"
    end
  end
end
