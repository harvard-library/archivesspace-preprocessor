namespace :aspace do
  namespace :process do
    desc "Analyze all finding aids in directory with current schematron"
    task :analyze => :environment do
      raise "EADS environment variable must be set to directory with input EADs" unless ENV['EADS']
      run = Run.create(schematron: Schematron.current)
      run.perform_analysis(
        Dir[File.join(File.expand_path(ENV['EADS']), "*.xml")].map do |f|
          FindingAidVersion.find_or_create_by(digest: FindingAidFile.new(IO.read(f)).digest)
        end
      )
    end
  end
end
