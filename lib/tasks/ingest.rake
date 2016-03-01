namespace :aspace do
  namespace :ingest do
    desc "Ingest new schematron file"
    task :schematron => :environment do
      raise "Must have 'FILE' provided in ENV" unless ENV.has_key? 'FILE'
      Schematron.create_from_file(File.open(File.expand_path(ENV['FILE'])))
    end

    desc "Ingest a finding aid version"
    task :finding_aid => :environment do
      raise "Must have EITHER 'FILE' or 'DIR' provided in ENV" unless %w|FILE DIR|.map {|k| ENV.has_key? k}.reject(&:!).count == 1
      if ENV['DIR']
        directory = File.expand_path(ENV['DIR'])
        raise "'DIR' argument is not a directory" unless File.directory?(directory)
        Dir[File.join(directory, "*.xml")].map do |f|
          FindingAidVersion.find_or_create_by(digest: FindingAidFile.new(IO.read(f)).digest)
        end
      elsif ENV['FILE']
        file = File.expand_path(ENV['FILE'])
        raise "'FILE' argument is not a file" unless File.file?(file)
        FindingAidVersion.find_or_create_by(digest: FindingAidFile.new(IO.read(file)).digest)
      end
    end
  end
end
