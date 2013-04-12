# A curated, translated relationship between a URI and a "human-readable" string describing the intent of the URI.
# I'm going to use Curatable for now, even though vetted probably won't ever be used. ...It might be, and it makes
# this easier than splitting up that class.
class KnownUri < ActiveRecord::Base

  include EOL::CuratableAssociation

  uses_translations

  self.per_page = 100

  belongs_to :vetted
  belongs_to :visibility

  has_many :translated_known_uris
  has_many :user_added_data

  attr_accessible :uri, :visibility_id, :vetted_id, :visibility, :vetted, :translated_known_uri,
    :translated_known_uris_attributes

  accepts_nested_attributes_for :translated_known_uris

  validates_presence_of :uri
  validates_uniqueness_of :uri
  validate :uri_must_be_uri

  before_validation :default_values

  def self.create_for_language(options = {})
    uri = KnownUri.create(uri: options.delete(:uri))
    if intent.valid?
      trans = TranslatedKnownUri.create(options.merge(known_uri: uri))
    end
    uri
  end

  private

  def default_values
    self.vetted ||= Vetted.unknown
    self.visibility ||= Visibility.visible
  end

  def uri_must_be_uri
    errors.add('uri', :must_be_uri) unless EOL::Sparql.is_uri?(self.uri)
  end

end
