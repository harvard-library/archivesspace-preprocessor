require 'test_helper'

# This is a crude method of testing any installed fixes that
# might be present.  To use:
#
#   1. Put your "we use it in production" schematron at /test/test_data/individual_fixes/schematron.xml
#   2. Put finding aids that contain the errors your fixes correct into /test/test_data/individual_fixes/eads/,
#          making sure to name them after the issue they present that you mean to test.
#   3. Fixes will be picked up from the application's system/fixes directory, as in dev/production
# Example: to test a fix for an issue with identifier "squirrel-7", you would need:
#
#   1. A schematron covering issue "squirrel-7", located at /test/test_data/individual_fixes/schematron.xml
#
class IndividualFixesTest < ActiveSupport::TestCase
  # HAX: This setup needs to be done at load time, because, it needs to be
  #      available to the metaprogramming below

  # HAX: Use actual installed fixes, not test fixes, for metaprogramming below
  Fixes.refresh_fixes(File.join(Rails.root, 'system', 'fixes'))

  # File directory to pull EADs from
  FILE_DIR = File.join(Rails.root,
                       *%w|test test_data individual_fixes eads *.xml|)
  FAIDS_LIST = Dir[FILE_DIR].map do|fname|
    File.basename(fname).sub(/\.xml$/, '')
  end

  describe "individual fixes" do
    before do
      Fixes.refresh_fixes(File.join(Rails.root, 'system', 'fixes'))
      @faids = Dir[FILE_DIR].map do|fname|
        [File.basename(fname).sub(/\.xml$/, ''),
         FindingAidVersion.create_from_file(File.open(fname))]
      end.to_h

      @sf = Schematron.create_from_file(
        File.open(File.join(Rails.root,
                            *%w|test
                                test_data
                                individual_fixes
                                schematron.xml|)))
      @checker = Checker.new(@sf)
    end


    Fixes.to_h.each do |k,v|
      if FAIDS_LIST.include? k
        it "tests that fix '#{k}' works" do
          issue_id = Issue.find_by(schematron: @sf, identifier: k).id
          pre = @checker.check(@faids[k])
          post = @checker.check(FindingAidVersion.find_or_create_by(digest:
                                                                      FindingAidFile.new(
                                                                     Fixes[k].(
                                                                       Nokogiri.XML(@faids[k].file.read)).to_s
                                                                   ).digest))
          assert(pre.any? {|hsh| hsh[:issue_id] == issue_id}, "no issues present in test case '#{k}.xml' before processing")
          assert(post.none? {|hsh| hsh[:issue_id] == issue_id}, "issues present in test case '#{k}.xml' after processing")
        end
      end
    end

    after do
      Fixes.refresh_fixes
      FindingAid.destroy_all
      Schematron.destroy_all
    end
  end

  Fixes.refresh_fixes # HAX: Needs to be returned to normal post metaprogramming
end
