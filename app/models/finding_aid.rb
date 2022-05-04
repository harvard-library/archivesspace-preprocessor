# An archival finding aid
#
# This is a logical representation, which represents all versions
# of an EAD file regardless of changes in content
class FindingAid < ApplicationRecord
  belongs_to :repository
  has_many :finding_aid_versions, dependent: :destroy
  has_many :runs, through: :finding_aid_versions

  # @visibility private
  def to_param
    eadid
  end

  # Gets most recent version of this FindingAid
  #
  # @return [FindingAidVersion] the most recent version of this FindingAid
  def current
    finding_aid_versions.order(created_at: :desc).first
  end
end
