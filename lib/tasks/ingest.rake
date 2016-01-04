namespace :ingest do
  desc "Ingest new schematron file"
  task :schematron => :environment do
    Schematron.create(
      digest: SchematronFile.new( IO.read(File.expand_path(ENV['FILE']))).digest
    )
  end
end
