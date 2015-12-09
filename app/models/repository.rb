# An institution the produces finding aids
class Repository < ActiveRecord::Base
  has_many :finding_aids
end
