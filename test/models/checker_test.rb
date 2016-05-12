require 'test_helper'

class CheckerTest < ActiveSupport::TestCase
  before do
    @sch_count = Dir[File.join(SchematronFile::FILE_DIR, '*.xml')].count
    @faid_count = Dir[File.join(FindingAidFile::FILE_DIR, '*.xml')].count

    @sch_file = SchematronFile.new(sch_content)

    @sch = Schematron.create_from_file(@sch_file)

    @faid = FindingAidVersion.create!(digest: FindingAidFile.new(faid_content).digest)
    @run = Run.create!(name: 'Test Run', schematron: @sch, run_for_processing: false)
  end

  describe Checker do
    let(:sch_content) {
      IO.read(File.join(Rails.root, 'test', 'test_data', 'test_schematron.xml'))
    }
    let(:faid_content) {
      IO.read(File.join(Rails.root, 'test', 'test_data', 'test_ead.xml'))
    }

    let(:checker) {
      Checker.new(@sch, @run)
    }

    it "can run over a finding aid and return useful values" do
      output = checker.check(@faid)
      output.must_be_kind_of(Array)
      output.first.must_be_kind_of(Hash)
      output.first.keys.sort.must_equal([:diagnostic_info, :finding_aid_version_id, :issue_id, :line_number, :location, :run_id])
      assert output.map(&:values).map {|v| v.none?(&:nil?)}.all?, "all values are not populated"
      assert output.map {|h| ConcreteIssue.new(h)}.map(&:save).all?, "all ConcreteIssues did not save"
    end

  end

  after do
    @run.destroy!
    @sch.destroy!
    @faid.destroy!

    if Dir[File.join(SchematronFile::FILE_DIR, '*.xml')].count > @sch_count
      raise "Detritus SchematronFiles left over after test"
    end


    if Dir[File.join(FindingAidFile::FILE_DIR, '*.xml')].count > @faid_count
      raise "Detritus FindingAidFiles left over after test"
    end
  end
end
