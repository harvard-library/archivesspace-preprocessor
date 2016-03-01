require 'test_helper'
class RootTest < ActionDispatch::IntegrationTest

  describe "root path" do
    it "exists and has content" do
      visit "/"
      page.must_have_content('ArchivesSpace Preprocessor')
    end

  end
end
