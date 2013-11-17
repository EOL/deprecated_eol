class LinkType < ActiveRecord::Base

  uses_translations
  has_many :data_objects_link_type
  has_many :data_objects, :through => :data_objects_link_type

  include Enumerated
  enumerated :label, ['Blog', 'News', 'Organization', 'Paper', 'Multimedia', 'Citizen Science']

  def self.create_defaults
    ['Blog', 'News', 'Organization', 'Paper', 'Multimedia', 'Citizen Science'].each do |label|
      unless TranslatedLinkType.exists?(label: label, language_id: Language.default.id)
        link_type = LinkType.create
        TranslatedLinkType.create(link_type: link_type, label: label, language: Language.default)
      end
    end
  end

  def to_s
    label
  end

end
