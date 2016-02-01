namespace :ingest do
  desc "Ingest new schematron file"
  task :schematron => :environment do
    Schematron.create_from_file(File.open(File.expand_path(ENV['FILE'])))
  end
end
