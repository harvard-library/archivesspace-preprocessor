# Processor configuration
# ========================
Saxon::Processor.default.config[:line_numbering] = true

# Disable a bunch of stuff in parser to prevent XXE vulnerabilities
parser_options = Saxon::Processor.default.to_java.getUnderlyingConfiguration.parseOptions
parser_options.add_parser_feature("http://apache.org/xml/features/disallow-doctype-decl", true)
parser_options.add_parser_feature("http://xml.org/sax/features/external-general-entities", false)
parser_options.add_parser_feature("http://xml.org/sax/features/external-parameter-entities", false)
