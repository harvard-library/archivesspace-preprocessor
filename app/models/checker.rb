# Schematron-based XSLT checker that finds and reports errors in EAD files
class Checker
  def initialize(stron = ->() {Schematron.current}, run = nil)
    @schematron = stron.kind_of?(Proc) ? stron.call : stron
    @checker = Schematronium.new(@schematron.file)
    @run = run
  end

  # @param faid [FindingAid, FindingAidVersion] An input EAD to be checked via Schematron
  # @return [Array] Issues found when running schematron over an EAD file, in the form of
  #   an Array of Hashes that are suitable for passing to ConcreteIssues constructor
  def check(faid)
    # Resolve down to concrete FindingAidFile for passing to Schematronium
    faid = faid.current if faid.is_a? FindingAid

    s_xml = Saxon.XML(faid.file)
    xml = @checker.check(faid.file)
    xml.remove_namespaces!
    errs = xml.xpath('//failed-assert | //successful-report')


    errs.map do |el|
      diag =  el.xpath('./diagnostic-reference').first
      {
        run_id: @run.try(:id),
        finding_aid_version_id: faid.id,
        issue_id: Issue.find_by(schematron_id: @schematron.id,
                                identifier: diag['diagnostic']).id,
        location: el['location'],
        line_number: s_xml.xpath(el['location']).get_line_number,
        diagnostic_info: diag.inner_html
      }
    end
  end
end
