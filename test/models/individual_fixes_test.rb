require 'test_helper'

# This is a crude method of testing any installed fixes that
# might be present.  To use:
#
#   1. Put your "we use it in production" schematron at /test/test_data/individual_fixes/schematron.xml
#   2. Put finding aids that contain the errors your fixes correct into /test/test_data/individual_fixes/eads/,
#          making sure to name them after the issue they present that you mean to test.
#   3. Fixes will be picked up from the application's system/fixes directory, as in dev/production
#
# To provide a concrete example: to test a fix for an issue with identifier "squirrel-7", you would need:
#
#   1. A schematron covering issue "squirrel-7", located at /test/test_data/individual_fixes/schematron.xml
#   2. A finding aid with the problem described by "squirrel-7", located at
#      /test/test_data/individual_fixes/eads/suirrel-7.xml
#   3. A fix, located at ROOT_DIR/system/fixes
#
# Note: These test methods run ONLY the fix in question, not "that fix and its dependencies"
#       Therefore, your test data should be designed so that any dependent fixes would not need
#       to be run.
class IndividualFixesTest < ActiveSupport::TestCase
  # HAX: This setup needs to be done at load time, because, it needs to be
  #      available to the metaprogramming below

  # Use actual installed fixes, not test fixes, for metaprogramming below
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

    # Metaprogramming ahoy! This loop and if run at file load, and are the reason for HAX above
    Fixes.to_h.each do |k,v|
      if FAIDS_LIST.include? k
        it "tests that fix '#{k}' works" do
          # Note: Multiple issues SHOULD NOT be associated with one identifier, but CAN BE.
          #       Any fix should fix all problems which share an identifier, and ideally,
          #       DON'T DO THIS, reporting will be subtly incorrect
          issue_ids = Issue.where(schematron: @sf, identifier: k).pluck(:id)

          # State of the Finding Aid before fix
          pre = @checker.check(@faids[k])

          # State of the finding Aid after fix
          fa_xml = Nokogiri.XML(@faids[k].file.read)
          fixed_file = FindingAidFile.new(Fixes[k].(fa_xml).to_s)
          fixed_fa = FindingAidVersion.find_or_create_by(digest: fixed_file.digest)
          post = @checker.check(fixed_fa)

          assert(pre.any? {|hsh| issue_ids.include? hsh[:issue_id]}, "no issues present in test case '#{k}.xml' before processing")
          assert(post.none? {|hsh| issue_ids.include? hsh[:issue_id]}, "issues present in test case '#{k}.xml' after processing")
        end
      end
    end

    after do
      Fixes.refresh_fixes

      # Make destroy callbacks run on tables with associated files
      FindingAid.destroy_all
      Schematron.destroy_all
    end
  end

  Fixes.refresh_fixes # Needs to be returned to normal in case other tests use test fixes
end
