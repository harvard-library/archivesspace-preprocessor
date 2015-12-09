# An archival finding aid
#
# This is a logical representation, which represents all versions
# of an EAD file regardless of changes in content
class FindingAid < ActiveRecord::Base
  belongs_to :repository
  has_many :finding_aid_versions
  has_many :runs, through: :finding_aid_versions
end
