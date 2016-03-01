ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'minitest-metadata'
require 'minitest/pride'
require 'poltergeist/suppressor'
require 'stringio'

Capybara.javascript_driver = :poltergeist

SchematronFile # make sure Rails loads SchematronFile

# Set test schematron, fixes, and finding aid file dirs for tests
$stderr = StringIO.new # silence stderr

::SchematronFile::FILE_DIR = File.join(Rails.root, 'test', 'sch_file_dir')
::FindingAidFile::FILE_DIR = File.join(Rails.root, 'test', 'faid_file_dir')
::Fixes::FILE_DIR = File.join(Rails.root, 'test', 'test_data', 'fixes')

$stderr = STDERR       # noisify stderr

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  # Expose Capybara DSL for integration tests
  include Capybara::DSL
  include Capybara::Assertions
  include MiniTest::Metadata



  before do
    if metadata[:js] == true
      Capybara.current_driver = Capybara.javascript_driver
    end

    DatabaseCleaner.strategy = metadata[:js] ? :truncation : :transaction
    DatabaseCleaner.start
  end

  after do
    Capybara.current_driver = Capybara.default_driver
    DatabaseCleaner.clean
  end

end
