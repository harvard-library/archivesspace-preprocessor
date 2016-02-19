# Actual implementations for fixes to Finding Aids
class Fixes
  FILE_DIR = File.join(Rails.root, 'system', 'fixes')

  # All fixes known by the system
  # Populated by initializer on system start
  @@fixes ||= {}.with_indifferent_access

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
  def self.[](name)
    @@fixes[name]
  end

  # Define an individual fix
  def fix_for name, &block
    @@fixes[name] = -> (xml) { @xml = xml; yield }
  end

  def self.refresh_fixes
    Fixes.definitions do
      Dir[File.join(FILE_DIR, '*.rb')].each do |fname|
        name = fname[0...fname.index(/.rb$/)]
        fix_for name do
          load fname
        end
      end
    end
  end
end
