require 'test_helper'

class RunTest < ActiveSupport::TestCase
  before do
    @sch_population = SchematronFile.all.count
    @sf = SchematronFile.new( IO.read(File.join(Rails.root, 'test', 'test_data', 'test_schematron.xml')))
    @schematron = Schematron.create( digest: @sf.digest, issues_attributes: @sf.issue_attrs)
    @faids = Dir[File.join(Rails.root, *%w|test test_data test_ead_dir *.xml|)].map do |fname|
      FindingAidVersion.create_from_file(File.open(fname))
    end
  end

  describe Run do
    it "can be run for analysis" do
      Run.create(name: 'Test Run', schematron: @schematron).perform_analysis(@faids)
    end
  end

  after do
    # Classes with files attached (and Run due to fkey into Schematron)
    # need to be destroyed, so their files will be rm'd
    [Run, Schematron, FindingAid].each do |klass|
      klass.destroy_all
    end
  end
end
