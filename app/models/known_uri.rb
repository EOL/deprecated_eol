# A curated, translated relationship between a URI and a "human-readable" string describing the intent of the URI.
# I'm going to use Curatable for now, even though vetted probably won't ever be used. ...It might be, and it makes
# this easier than splitting up that class.
class KnownUri < ActiveRecord::Base

  uses_translations

  self.per_page = 100

  accepts_nested_attributes_for :translated_known_uri

  has_many :user_added_data

  attr_accessible :uri, :visibility_id, :vetted_id, :visibility, :vetted

  validates_presence_of :uri
  validates_uniqueness_of :uri

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
    self.vetted = Vetted.unknown
    self.visibility = Visibility.visible
  end

end
