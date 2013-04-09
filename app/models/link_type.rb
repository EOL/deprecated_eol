class LinkType < ActiveRecord::Base
  uses_translations
  has_many :data_objects_link_type
  has_many :data_objects, :through => :data_objects_link_type

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

  def self.blog
    @@blog ||= cached_find_translated(:label, 'Blog')
  end

  def self.multimedia
    @@multimedia ||= cached_find_translated(:label, 'Multimedia')
  end

  def self.news
    @@news ||= cached_find_translated(:label, 'News')
  end

  def self.organization
    @@organization ||= cached_find_translated(:label, 'Organization')
  end

  def self.paper
    @@paper ||= cached_find_translated(:label, 'Paper')
  end

  def self.citizen_science
    @@citizen_science ||= cached_find_translated(:label, 'Citizen Science')
  end

end
