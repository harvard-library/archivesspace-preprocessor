# Class representing the file containing schematron
#
# Should be considered immutable in principle after creation - in principle,
# there's not a simple way to render a File object stateless.
#
# Delegates most operations to File object.
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
    schematron_content =  if obj.respond_to?(:read)
                            obj.read
                          else
                            obj
                          end

    @digest = Digest::SHA256.hexdigest(schematron_content)

    @fname = File.join(SCH_FILE_DIR, "#{@digest}.xml")

    File.open(@fname, 'w', 0444) do |f|
      f.write(schematron_content)
    end unless File.exist? @fname

    @del_target = File.new(@fname, 'r')

    super(@del_target)
  end

  # Several methods to make SchematronFiles present as such in Pry et alia

  # @visibility private
  def inspect
    @del_target.inspect.insert(2, "Schematron")
  end

  # @visibility private
  def to_s
    out = read
    rewind
    out
  end

  # @visibility private
  def pretty_print(pp)
    pp.text inspect
  end

  # Return an array of hashes of issue attribute values suitable
  #   for passing in as nested attributes to Schematron constructor
  #
  # @return [Hash] A representation of the XML content for use
  #   in constructing DB representations of individual issues
  def issue_attrs
    rep = {}
    xml = Nokogiri::XML(self)
    xml.remove_namespaces!
    diags = xml.xpath('//diagnostic')
    xml.xpath('//rule').map do |rule|
      label = rule.xpath('./comment()').text.strip
      context = rule['context']
      manual = rule.ancestors('pattern').first['id'].match(/-manual\Z/) ? true : false
      issues = rule.xpath('./assert').map do |assert|
        {
          rule_label: label, rule_context: context, manual: manual, #rule stuff
          identifier: assert['diagnostics'],
          test: assert['test'],
          message: assert.content.strip,
          alternate_issue_id: diags.filter("[@id='#{assert['diagnostics']}']")
            .first
            .content
            .match(/(?<=Ref-number: ).*$/)[0]
        }
      end
    end.flatten
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

  # Filenames of all Schematron files in directory
  #
  # @return [Array<String>] filenames
  def self.filenames
    Dir[File.join(SCH_FILE_DIR, '*.xml')].sort_by { |fn| File.ctime fn }
  end

  # SHA digests of all Schematron files in directory
  #
  # @return [Array<String>] SHA256 digests
  def self.digests
    filenames.map {|f| File.basename(f).sub(/\.xml$/, '') }
  end

  # All SchematronFiles in directory
  #
  # @return [Array<SchematronFile>] All known SchematronFiles
  def self.all
    digests.map {|d| self[d] }
  end

end
