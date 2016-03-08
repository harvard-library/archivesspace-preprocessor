# A specific version of an archival finding aid.
#
# This is a concrete representation, specified by file content
class FindingAidVersion < ActiveRecord::Base
  before_create :find_or_create_faid

  # Internal validator class (preferred over validates_each bc YARD can't see validates_each)
  class FindingAidFileValidator < ActiveModel::EachValidator
    # FindingAidFile exists with digest == value
    def validate_each(record, attribute, value)
      record.errors.add(attribute, "must be associated with an extant FindingAidFile") unless FindingAidFile[value].is_a? FindingAidFile
    end
  end

  belongs_to :finding_aid
  has_and_belongs_to_many :runs
  has_many :concrete_issues, dependent: :destroy
  has_many :processing_events

  after_destroy :delete_file

  validates :digest,
            length: {is: 64},
            format: {with: /[a-zA-Z0-9]+/},
            presence: true,
            uniqueness: true,
            finding_aid_file: true

  # @return [FindingAidFile] the FindingAidFile associated with this record
  def file
    FindingAidFile[digest]
  end

  def xml
    Nokogiri.XML(file, nil, 'UTF-8') {|config| config.nonet;config.noent}
  end

  private
  # Callback to delete related FindingAidFile
  def delete_file
    File.unlink file
  end

  # Callback to associate or create and associate FindingAid
  def find_or_create_faid
    faid = FindingAid.find_or_create_by(file.faid_attr)
    self.finding_aid_id = faid.id
  end

end
