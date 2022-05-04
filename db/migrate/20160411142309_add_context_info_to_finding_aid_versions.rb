class AddContextInfoToFindingAidVersions < ActiveRecord::Migration[4.2]
  class FindingAidVersion < ActiveRecord::Base
    # guard class
  end

  def change
    add_column :finding_aid_versions, :unittitle, :string
    add_column :finding_aid_versions, :unitid, :string

    reversible do |dir|
      dir.up do
        FindingAidVersion.reset_column_information

        FindingAidVersion.all.each do |fav|
          xml = Nokogiri.XML(FindingAidFile[fav.digest], nil, 'UTF-8') {|config| config.nonet;config.noent}
          attrs = {}
          if ut  = xml.at_xpath('/ead/archdesc/did/unittitle')
            attrs[:unittitle] =  ut.content.gsub(/\s+/, ' ').sub(/[\s,]+$/, '')
          end
          if uid = xml.at_xpath('/ead/archdesc/did/unitid')
            attrs[:unitid]    = uid.content.rstrip
          end

          unless attrs.blank?
            fav.update(attrs)
          end
        end
      end

      dir.down do
        # do nothing, columns get dropped
      end
    end
  end
end
