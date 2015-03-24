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

  include Enumerated
  enumerated :title, [
    { public_domain: 'public domain' },
    { all_right_reserved: 'all rights reserved' },
    { cc: 'cc-by 3.0' },
    { by_sa: 'cc-by-sa 3.0' },
    { by_nc: 'cc-by-nc 3.0' },
    { by_nc_sa: 'cc-by-nc-sa 3.0' },
    { cc_zero: 'cc-zero 1.0' },
    { no_known_restrictions: 'no known copyright restrictions' },
    { na: 'not applicable' },
  ]

  scope :show_to_content_partners, -> { where(show_to_content_partners: true) }

  class << self
    alias default public_domain
  end

  # NOTE: this is used by Tramea, not "pure" EOL.
  # NOTE: The license image URL isn't included, but I think that's a Good Thing.
  def self.params_from_data_object(data)
    {
      license: data.license.source_url,
      rights: data.rights_statement_for_display ||
        data.license.description,
      rights_holder: data.rights_holder_for_display ||
        (data.added_by_user? ? data.users_data_object.user.full_name : nil),
      ratings: data.rating_summary.merge(weighted_average: data.average_rating)
    }
  end

  def self.create_enumerated
    enumeration_creator(
      defaults:
        { show_to_content_partners: 1, version: 1 },
      public_domain:
        { title: 'public domain',
          description: 'No rights reserved',
          source_url: 'http://creativecommons.org/licenses/publicdomain/',
          logo_url: '' },
      all_right_reserved:
        { title: 'all rights reserved',
          description: '&#169; All rights reserved',
          source_url: '',
          logo_url: '',
          show_to_content_partners: 0 },
      by_nc:
        { title: 'cc-by-nc 3.0',
          description: 'Some rights reserved',
          source_url: 'http://creativecommons.org/licenses/by-nc/3.0/',
          logo_url: 'cc_by_nc_small.png' },
      cc:
        { title: 'cc-by 3.0',
          description: 'Some rights reserved',
          source_url: 'http://creativecommons.org/licenses/by/3.0/',
          logo_url: 'cc_by_small.png' },
      by_sa:
        { title: 'cc-by-sa 3.0',
          description: 'Some rights reserved',
          source_url: 'http://creativecommons.org/licenses/by-sa/3.0/',
          logo_url: 'cc_by_sa_small.png' },
      by_nc_sa:
        { title: 'cc-by-nc-sa 3.0',
          description: 'Some rights reserved',
          source_url: 'http://creativecommons.org/licenses/by-nc-sa/3.0/',
          logo_url: 'cc_by_nc_sa_small.png' },
      cc_zero:
        { title: 'cc-zero 1.0',
          description: 'Public Domain',
          source_url: 'http://creativecommons.org/publicdomain/zero/1.0/',
          logo_url: 'cc_zero_small.png' },
      no_known_restrictions:
        { title: 'no known copyright restrictions',
          description: 'No known copyright restrictions',
          source_url: 'http://www.flickr.com/commons/usage/',
          logo_url: '' },
      na:
        { title: 'not applicable',
          description: 'License not applicable',
          source_url: '',
          logo_url: '',
          show_to_content_partners: 0 }
    )
  end

  def self.valid_for_user_content
    show_to_content_partners.map { |c| [c.title, c.id] }
  end

  def self.for_data
    @@for_data ||= [License.no_known_restrictions, License.na, License.cc_zero, License.public_domain]
  end

  # def small_logo_url
  #   return logo_url if logo_url =~ /_small/ # already there!
  #   return logo_url.sub(/\.(\w\w\w)$/, "_small.\\1")
  # end

  # we have several different licenses with the title public domain
  # NOTE - this *does* work in other languages (I checked), though I'm honestly not sure why; I didn't dig.
  def is_public_domain?
    self.title == 'public domain'
  end

  def show_rights_holder?
    !(is_public_domain? || self.id == License.no_known_restrictions.id)
  end

end
