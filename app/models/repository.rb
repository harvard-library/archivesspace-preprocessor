# An institution the produces finding aids
class Repository < ApplicationRecord
  has_many :finding_aids

  # PrettyPrint repo name and code for display
  # @return [String] format: name (code)
  def pp_name
    "#{name} (#{code})"
  end
end
