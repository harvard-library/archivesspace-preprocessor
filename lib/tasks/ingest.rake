namespace :ingest do
  desc "Ingest new schematron file"
  task :schematron => :environment do
    file = SchematronFile.new( IO.read(File.expand_path(ENV['FILE'])))
    Schematron.create(
      digest: file.digest,
      issues_attributes: file.issue_attrs
    )
  end
end
