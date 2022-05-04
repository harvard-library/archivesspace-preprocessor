# Schematron-based XSLT checker that finds and reports errors in EAD files
class Checker
  # Patch till saxon-xslt includes more things and also maybe has a real API for nodesets and junk
  Saxon::S9API.class_eval do
    java_import 'net.sf.saxon.s9api.Axis'
  end

  AXIS_ARGS = [Saxon::S9API::Axis::CHILD, Saxon::S9API::QName.new('http://purl.oclc.org/dsdl/svrl', 'diagnostic-reference')]
  DIAGNOSTIC = Saxon::S9API::QName.new('diagnostic')
  LOCATION = Saxon::S9API::QName.new('location')
  def initialize(stron = ->() {Schematron.current}, run = nil)
    @schematron = stron.kind_of?(Proc) ? stron.call : stron
    @issue_ids = stron.issues.pluck(:identifier, :id).to_h
    @checker = Schematronium.new(@schematron.file)
    @run = run
  end

  # @param faid [FindingAid, FindingAidVersion] An input EAD to be checked via Schematron
  # @return [Array] Issues found, elements of array are suitable for passing to ConcreteIssues constructor
  def check(faid)
    # Resolve down to concrete FindingAidFile for passing to Schematronium
    faid = faid.current if faid.is_a? FindingAid

    s_xml = Saxon.XML(faid.file)
    xml = @checker.check(faid.file, nokogiri: false)

    errs = xml.xpath('//*:failed-assert | //*:successful-report')

    results = []
    errs.each do |el|
      diag = el.axis_iterator(*AXIS_ARGS).first
      location = Saxon::S9API::QName.new('location')
      out = {
        run_id: @run.try(:id),
        finding_aid_version_id: faid.id,
        issue_id: @issue_ids[diag.get_attribute_value(DIAGNOSTIC)],
        location: el.get_attribute_value(LOCATION),
        line_number: s_xml.xpath(el.get_attribute_value(LOCATION)).get_line_number,
        diagnostic_info: diag.get_string_value
      }
      if block_given?
        yield out
      else
        results << out
      end
    end
    block_given? ? true : results
  end

  # Note: Separate str version exists because saxon XML can't provide line numbers when run on a str not backed by a file
  # @param xmlstr [String] An input string containing EAD content to be checked via Schematron
  # @return [Array<Hash>] Issues found, elements of array are suitable for passing to ConcreteIssues constructor
  def check_str(xmlstr)
    xml = @checker.check(xmlstr, nokogiri: false)
    errs = xml.xpath('//*:failed-assert | //*:successful-report')

    errs.map do |el|
      diag = el.axis_iterator(*AXIS_ARGS).first
      {
        run_id: @run.try(:id),
        issue_id: @issue_ids[diag.get_attribute_value(Saxon::S9API::QName.new('diagnostic'))],
        location: el.get_attribute_value(Saxon::S9API::QName.new('location')),
        line_number: -1,
        diagnostic_info: diag.get_string_value
      }
    end
  end
end
