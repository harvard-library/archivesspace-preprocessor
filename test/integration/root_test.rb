class RootTest < ActionDispatch::IntegrationTest

  describe "root path" do
    it "exists and has content" do
      visit "/"
      page.must_have_content('Welcome aboard')
    end

    it "works with js", js: true do
      visit "/"
      page.must_have_content('Javascript added here')
    end
  end
end
