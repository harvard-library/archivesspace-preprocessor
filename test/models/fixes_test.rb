require 'test_helper'

class FixesTest < ActiveSupport::TestCase
  describe Fixes do
    let :xml do Nokogiri.XML(<<-XML.strip, nil, 'UTF-8') {|config| config.nonet}
      <?xml version="1.0" encoding="UTF-8" ?>
      <ead>
      </ead>
    XML
    end

    before do
      Fixes.class_variable_set('@@fixes', {})
    end

    it "can define a fix" do
      Fixes.definitions do
        fix_for 'test-2' do
          @xml.at_xpath('ead')['level'] = 'testlevel'
        end
      end
      Fixes.to_h.keys.must_include('test-2')
      Fixes['test-2'].must_be_kind_of(Proc)
      Fixes['test-2'].(xml).at_xpath('ead')['level'].must_equal 'testlevel'
    end

    it "can pick up fixes from files" do
      Fixes.refresh_fixes
      Fixes['test-1'].must_be_kind_of(Proc)
      Fixes['test-1'].(xml).at_xpath('ead')['level'].must_equal 'testlevel'
    end

    after do
      Fixes.class_variable_set('@@fixes', {})
    end
  end
end
