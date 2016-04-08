# An institution the produces finding aids
class Repository < ActiveRecord::Base
  has_many :finding_aids

  # PrettyPrint repo name and code for display
  # @return [String] format: name (code)
  def pp_name
    "#{name} (#{code})"
  end
end
