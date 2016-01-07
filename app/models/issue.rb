# A particular problem that can occur in EAD files
class Issue < ActiveRecord::Base
  belongs_to :schematron
  has_many :concrete_issues, dependent: :destroy

  validates *attribute_names, presence: true # All fields required

end
