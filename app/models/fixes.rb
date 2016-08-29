# Singleton representing a collection of arbitrary transformations to apply to
# Finding Aids, with dependency resolution.
#
# Each "fix" is a key-value pair, with the key consisting of a string that matches an
# Issue.identifier, and the value consisting of a lambda
#
# Within a fix, the instance variable `@xml` represents the current state of the
# finding aid being altered.
#
# To get all the Fixes in the order that they should be run.
class Fixes
  # Directory that fix files are stored in
  FILE_DIR = File.join(Rails.root, 'system', 'fixes')

  # All fixes known by the system
  # Populated by initializer on system start
  @@fixes       ||= {}.with_indifferent_access

  # Constraints on fixes
  # Represents a depends_on relationship, represented as
  # basically a big ol' list of graph edges
  #   [[x, y], [x, z]] means y and z depend on x
  @@constraints ||= []

  # Special "preflight" fixes that run unconditionally over
  # every finding aid, prior to any other fixes
  @@preflights ||= {}.with_indifferent_access

  # Expose preflights variable for use in Run
  # @return [Hash{String => Lambda}] preflights
  def self.preflights
    @@preflights
  end

  # Make the class enumerable to support iteration over fixes
  class << self
    include Enumerable

    # Iterates over fixes as hash
    def each(&block)
      return @@fixes.to_enum unless block_given?
      @@fixes.each do |member|
        yield member
      end
    end

  end

  # Delegate #key? on the class to the internal hash
  # @param key [Symbol, String] key to check for
  # @return [Boolean] whether key is present
  def self.key?(key)
    @@fixes.key?(key)
  end

  # Definitions block, which sets the context to a Fix instantiation
  # Within this block, {#fix_for} can be used to define new fixes.
  def self.definitions(&block)
    instance = new
    instance.instance_eval(&block)
    @@fixes = reorder
  end

  # Ensures that order-dependent fixes are ordered properly
  # Depends on Ruby's ordered hash semantics
  # For implementation details, search on "topological sort" and "Kahn's Algorithm"
  # @return [Hash{String => Lambda}] fixes
  def self.reorder
    order = {}.with_indifferent_access
    edges = @@constraints.dup
    incoming = edges.map(&:last).uniq
    nodes = edges.flatten.uniq
    s = Set.new(nodes.reject{|e| incoming.include? e})
    while !s.empty?
      n = s.first
      s.delete n
      order[n] = @@fixes[n]
      nodes.each do |m|
        if edges.member? [n,m]
          edges.delete [n,m]
          s.add m if edges.none? {|(_,y)| y == m}
        end
      end
    end
    raise(<<-ERROR_TXT) if edges.any?
Cyclical dependency found in your fixes.  Please inspect your @depends_on statements.
The following edges remain in your dependency graph after processing:
  #{edges}
    ERROR_TXT

    # Add fixes without dependency concerns
    @@fixes.keys.reject {|fix_id| order.key? fix_id}.each do |fix_id|
      order[fix_id] = @@fixes[fix_id]
    end

    order
  end

  # Convenience accessor - Fixes[:name] gets back the fix in question
  # @param identifier [Symbol, String] identifier this fix is associated
  # @return [Lambda] the lambda associated with this identifier
  def self.[](identifier)
    @@fixes[identifier]
  end

  # Define an individual fix
  #
  # {#fix_for} is always called with a block.  The contents of this block constiutute a
  # transformation to be applied later to finding aids.
  #
  # Within this block, the instance variable `@xml` refers to a
  # [Nokogiri::XML::Document] that represents the current state of a finding aid.
  # Any changes made to `@xml` will be applied to the eventual output.
  #
  # @param identifier [String, Symbol] key for retrieving the fix, should match an {Issue} identifier
  # @param depends_on [Array?] fixes that must be run before this fix
  # @param preflight [Boolean] Whether a fix should be run unconditionally prior to run
  # @param block [Block] implementation of the fix
  # @return [Lambda] the fix
  def fix_for(identifier, depends_on: [], preflight: false, &block)
    unless preflight
      depends_on.each do |dep|
        @@constraints << [dep, identifier]
      end

      @@fixes[identifier] = -> (xml) do
        @xml = xml
        yield
        @xml
      end
    else
      @@preflights[identifier] = -> (xml) do
        @xml = xml
        yield
        @xml
      end
    end
  end

  # For each file in the FILE_DIR, create or replace a fix
  # Uses the file's name to determine fix name
  # @param dir [String?] directory name to refresh fixes from, defaults to Fixes::FILE_DIR at runtime
  def self.refresh_fixes(dir = nil)
    @@fixes.clear
    @@constraints.clear
    @@preflights.clear
    definitions do
      Dir[File.join(dir || FILE_DIR, '*.rb')].each do |fname|
        fixes_content = IO.read(fname)
        raise "File `#{fname}` does not contain fixes" unless fixes_content.index('fix_for')
        eval fixes_content, nil, fname, 1
      end
    end
  end

  # Custom error to throw when a fix doesn't work right
  class Failure < StandardError
    # No additional features to StandardError
  end
end
