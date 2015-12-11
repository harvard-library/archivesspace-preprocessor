# Class representing the file containing schematron
#
# Delegates most operations to File object for reasons.
class SchematronFile < SimpleDelegator
  # Directory that processed schematron files are stored in
  SCH_FILE_DIR = File.join(Rails.root, 'public', 'schematrons')

  # @return [String] the SHA256 digest of the file's content in hex format
  attr_reader :digest

  # Looks up existing Schematron file from filesystem or else creates a schematron file
  #
  # @param obj [String, #read] a schematron
  # @return [SchematronFile]
  def initialize(obj)
    if obj.responds_to? :read
      obj = obj.read
    end

    @digest = Digest::SHA256.hexdigest(obj)

    @fname = File.join(SCH_FILE_DIR, "#{@digest}.xml")

    File.open(@fname, 'w', 0444) do |f|
      f.write(obj)
    end unless File.exists? @fname

    obj = File.new(@fname, 'r')
    super
  end

  # Convenience method for fetching file
  #
  # @param [String] digest SHA256 digest in hex format
  # @return [SchematronFile, nil] the file or nil
  def self.[](digest)
    @fname = File.join(SCH_FILE_DIR, "#{digest}.xml")
    if File.exists? @fname
      new(File.open(@fname, 'r'))
    else
      nil
    end
  end

end
