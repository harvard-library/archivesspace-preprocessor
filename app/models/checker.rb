# Schematron-based XSLT checker that finds and reports errors in EAD files
class Checker
  def initialize
    @checker = Schematronium.new(Schematron.current.file)
  end

  # @param faid [FindingAid, FindingAidVersion, FindingAidFile] An input EAD file to be checked via Schematron
  # @return [Array] Issues found when running schematron over an EAD file, in the form of
  #   an Array of Hashes suitable for passing to ConcreteIssue constructor
  def check(faid)
    # Resolve down to concrete FindingAidFile for passing to Schematronium
    faid = faid.current if faid.is_a? FindingAid
    faid = faid.file if faid.is_a? FindingAidVersion

    xml = @checker.check(faid)
    xml.remove_namespaces!
    errs = xml.xpath('//failed-assert | //successful-report')

    # start here


  end
end
