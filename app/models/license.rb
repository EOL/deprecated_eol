class License < ActiveRecord::Base
  uses_translations
  # this is only used in testing. For some translted models we only want to create one instance for a particular
  # label in a language. For example we only want one English DataType.image or one Rank.species. But other
  # models like License is translating a description which isn't unique. We can have several Licences with
  # description 'all rights reserved'. We need to know this when creating test data
  TRANSLATIONS_ARE_UNIQUE = false
  has_many :data_objects
  has_many :resources

  attr_accessible :title, :source_url, :version, :logo_url, :show_to_content_partners

  # NOTE - "Normally" I would look for translations that already exist, but in this case, the Translation is on description,
  # which needn't be unique, so I just create a translation for every one, whether or not it already exists.
  def self.create_defaults
    [ {:title => 'public domain',
       :description => 'No rights reserved',
       :source_url => 'http://creativecommons.org/licenses/publicdomain/',
       :logo_url => ''},
      {:title => 'all rights reserved',
       :description => '&#169; All rights reserved',
       :source_url => '',
       :logo_url => '',
       :show_to_content_partners => 0, },
      {:title => 'cc-by-nc 3.0',
       :description => 'Some rights reserved',
       :source_url => 'http://creativecommons.org/licenses/by-nc/3.0/',
       :logo_url => 'cc_by_nc_small.png'},
      {:title => 'cc-by 3.0',
       :description => 'Some rights reserved',
       :source_url => 'http://creativecommons.org/licenses/by/3.0/',
       :logo_url => 'cc_by_small.png'},
      {:title => 'cc-by-sa 3.0',
       :description => 'Some rights reserved',
       :source_url => 'http://creativecommons.org/licenses/by-sa/3.0/',
       :logo_url => 'cc_by_sa_small.png'},
      {:title => 'cc-by-nc-sa 3.0',
       :description => 'Some rights reserved',
       :source_url => 'http://creativecommons.org/licenses/by-nc-sa/3.0/',
       :logo_url => 'cc_by_nc_sa_small.png'},
      {:title => 'cc-zero 1.0',
       :description => 'Public Domain',
       :source_url => 'http://creativecommons.org/publicdomain/zero/1.0/',
       :logo_url => 'cc_zero_small.png'},
      {:title => 'no known copyright restrictions',
       :description => 'No known copyright restrictions',
       :source_url => 'http://www.flickr.com/commons/usage/',
       :logo_url => '',},
      {:title => 'not applicable',
       :description => 'License not applicable',
       :source_url => '',
       :logo_url => '',
       :show_to_content_partners => 0}].each do |default|
        desc = default.delete(:description)
        lic = License.find_by_title(default[:title])
        lic ||= License.create(default.reverse_merge(:version => 1))
        TranslatedLicense.find_or_create_by_description_and_language_id_and_license_id(desc, Language.default.id, lic.id)
    end
  end

  def small_logo_url
    return logo_url if logo_url =~ /_small/ # already there!
    return logo_url.sub(/\.(\w\w\w)$/, "_small.\\1")
  end

  def self.valid_for_user_content
    find_all_by_show_to_content_partners(1).collect {|c| [c.title, c.id] }
  end

  def self.public_domain
    cached_find(:title, 'public domain')
  end
  class << self
    alias default public_domain
  end

  def self.cc
    cached_find(:title, 'cc-by 3.0')
  end

  def self.by_nc
    cached_find(:title, 'cc-by-nc 3.0')
  end

  def self.by_nc_sa
    cached_find(:title, 'cc-by-nc-sa 3.0')
  end

  def self.by_sa
    cached_find(:title, 'cc-by-sa 3.0')
  end

  def self.no_known_restrictions
    @@no_known_restrictions ||= cached_find(:title, 'no known copyright restrictions')
  end

  # we have several different licenses with the title public domain
  # NOTE - this *does* work in other languages (I checked), though I'm honestly not sure why; I didn't dig.
  def is_public_domain?
    self.title == 'public domain'
  end

  def show_rights_holder?
    !(is_public_domain? || self.id == License.no_known_restrictions.id)
  end
end
