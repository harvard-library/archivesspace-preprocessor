fix_for "test-1" do
  @xml.at_xpath('ead')['level'] = "testlevel"
end
