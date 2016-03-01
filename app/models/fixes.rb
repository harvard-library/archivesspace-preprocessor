# Actual implementations for fixes to run over Finding Aids
#
# Individual fixes are essentially lambdas which take an XML object, yield it
# to a block provided by the user, and returning the same XML object
class Fixes
  # Directory that fix files are stored in
  FILE_DIR = File.join(Rails.root, 'system', 'fixes')

  # All fixes known by the system
  # Populated by initializer on system start
  @@fixes ||= {}.with_indifferent_access

  # Definitions block, which sets the context to a Fix instantiation
  def self.definitions(&block)
    instance = new
    instance.instance_eval(&block)
  end

  # Make the class enumberable to support iteration over fixes
  class << self
    include Enumerable

    def each(&block)
      return @@fixes.to_enum unless block_given?
      @@fixes.each do |member|
        yield member
      end
    end
  end

  # Convenience accessor - Fixes[:name] gets back the fix in question
  # @param name [Symbol, String] identifier this fix is associated
  # @return [Lambda] the lambda associated with this identifier
  def self.[](name)
    @@fixes[name]
  end

  # Define an individual fix
  # @param name [String, Symbol] key for retrieving the fix, should match an identifier in Issues
  # @param block [Block] implementation of the fix
  # @return [Lambda] the lambda defined by this fix_for
  def fix_for(name, &block)
    @@fixes[name] = -> (xml) do
      @xml = xml
      yield
      @xml
    end
  end

  # For each file in the FILE_DIR, create or replace a fix
  # Uses the file's name to determine fix name
  def self.refresh_fixes()
    definitions do
      Dir[File.join(FILE_DIR, '*.rb')].each do |fname|
        name = File.basename(fname).sub(/.rb$/, '')
        fix_for name do
          eval IO.read(fname)
        end
      end
    end
  end
end
