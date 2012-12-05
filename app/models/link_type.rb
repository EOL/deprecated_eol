class LinkType < ActiveRecord::Base
  uses_translations
  has_many :data_objects_link_type
  has_many :data_objects, :through => :data_objects_link_type

  def to_s
    label
  end

  def self.blog
    cached_find_translated(:label, 'Blog')
  end

  def self.multimedia
    cached_find_translated(:label, 'Multimedia')
  end

  def self.news
    cached_find_translated(:label, 'News')
  end

  def self.organization
    cached_find_translated(:label, 'Organization')
  end

  def self.paper
    cached_find_translated(:label, 'Paper')
  end

end
