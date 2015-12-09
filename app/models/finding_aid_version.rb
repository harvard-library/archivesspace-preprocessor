# A specific version of an archival finding aid.
#
# This is a concrete representation, specified by file content
class FindingAidVersion < ActiveRecord::Base
  belongs_to :finding_aid
  has_and_belongs_to_many :runs
end
