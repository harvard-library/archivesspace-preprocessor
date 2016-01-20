# Class representing the file containing schematron
#
# Should be considered immutable in principle after creation - in principle,
# there's not a simple way to render a File object stateless.
#
# Delegates most operations to File object.
class SchematronFile < SimpleDelegator
  # Directory that processed schematron files are stored in
  FILE_DIR = File.join(Rails.root, 'public', 'schematrons')

  # Slug to prepend to File in console description of object
  INSPECT_SLUG = 'Schematron'

  include DigestedFile
  #@!parse include DigestedFile
  #@!parse extend DigestedFile::ClassMethods

  # Return an array of hashes of issue attribute values suitable
  #   for passing in as nested attributes to Schematron constructor
  #
  # @return [Array<Hash>] A representation of the XML content for use
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
          rule_label: label,
          rule_context: context,
          manual: manual, #rule stuff
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

end
