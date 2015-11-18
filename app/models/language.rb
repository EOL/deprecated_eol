# TODO - remove activated_on ...or start using it.
class Language < ActiveRecord::Base
  uses_translations(foreign_key: 'original_language_id')
  belongs_to :language_group, foreign_key: :language_group_id
  has_many :data_objects
  has_many :users
  has_many :taxon_concept_names

  attr_accessible :iso_639_1, :iso_639_2, :iso_639_3, :source_form, :sort_order, :activated_on, :language_group_id

  scope :not_blank, -> { where("iso_639_1 != '' AND source_form != ''") }

  def to_s
    iso_639_1
  end

  def self.find_active
    cached("active_languages") do
      Language.where("activated_on < ?", Time.now).order('sort_order ASC, source_form ASC')
    end
  end

  def self.approved_languages
    approved_language_iso_codes = Rails.configuration.active_languages rescue ['en', 'es', 'ar']
    @@approved_languages ||= cached("approved_languages") do
      self.find_all_by_iso_639_1(approved_language_iso_codes,
                                 order: 'sort_order ASC, source_form ASC')
    end
  end

  def self.scientific
    cached_find_translated(:label, 'Scientific Name')
  end

  def self.with_iso_639_1
    cached("all_languages_with_iso_639_1") do
      Language.find(:all, conditions: "iso_639_1 != '' AND iso_639_1 IS NOT NULL")
    end
  end

  # NOTE: Sorry, black magic here. I don't care. Lost all hope of avoiding SQL
  # around here. :| This command creates a hash of ids and their iso codes, then
  # looks up the value in that hash based on the id passed in.
  def self.iso_code(id)
    @iso_by_id ||= Hash[*(Language.connection.select_rows("SELECT id, "\
      "iso_639_1 FROM languages WHERE iso_639_1 != ''").flatten)]
    @iso_by_id[id]
  end

  def self.from_iso(iso)
    @@from_iso ||= {}
    @@from_iso[iso] ||= cached_find(:iso_639_1, iso)
  end

  def self.find_by_iso_exclusive_scope(iso)
    with_exclusive_scope do
      find_by_iso_639_1(iso)
    end
  end

  def self.find_closest_by_iso(iso)
    if l = from_iso(iso)
      return l
    elsif matches = iso.match(/^([a-z]{2,})-([a-z]{2,})/i)
      return from_iso(matches[1])
    end
  end

  # Migrations make it possible that the 'en' will either be in the languages table or its translated table.  This
  # ensures we grab it from whichever place is currently appropriate. This method will also create English is it does
  # not already exist
  def self.english_for_migrations
    eng_lang = nil
    eng_lang = find_by_iso_exclusive_scope('en')
    unless eng_lang
      eng_lang = Language.create(iso_639_1: 'en', iso_639_2: 'eng', iso_639_3: 'eng',
                                 source_form: 'English', sort_order: 1, activated_on: 2.days.ago)
    end
    unless TranslatedLanguage.exists?(label: 'English', original_language_id: eng_lang.id)
      TranslatedLanguage.create(label: 'English', original_language_id: eng_lang.id, language_id: eng_lang.id)
    end
    eng_lang
  end
  class << self
    alias :create_english :english_for_migrations
  end

  def self.id_from_iso(iso_code)
    cached("id_from_iso_#{iso_code}") do
      # NOT using ActiveRecord here because I want to avoid the after_initialize callback
      # this is very important - the after_initialize callback for languages creates an infinite loop
      result = connection.select_values("SELECT id FROM languages WHERE iso_639_1='#{iso_code}'")
      result.empty? ? nil : result[0].to_i
    end
  end

  def self.default_code
    Language.default.iso_639_1
  end

  def self.default
    @@default ||= cached('default') do
      self.english_for_migrations # Slightly weird, but... as it implies... needed for migrations.
    end
  end
  class << self
    alias english default
  end

  def self.unknown
    @@unknown_language ||= cached_find_translated(:label, "Unknown")
  end

  def self.all_unknowns
    @@all_unknown_languages ||= cached("unknown_languages") do
      unknown_languages = []
      ['unknown', 'unspecified', 'undetermined', 'common name', 'miscellaneous languages', 'multiple languages'].each do |l|
        if lang = cached_find_translated(:label, l)
          unknown_languages << lang
        end
      end
      unknown_languages
    end
  end

  def self.common_name
    cached_find_translated(:label, "Common name")
  end

  def display_code
    iso_code.upcase
  end

  def iso_code
    iso_639_1
  end

  def all_ids
    return [ self.id ] if language_group.blank?
    return language_group.languages.collect{ |l| l.id }
  end

  def representative_language
    return self if language_group.blank?
    return language_group.representative_language
  end

  def known_language?
    !(iso_639_1.blank? && iso_639_2.blank?)
  end

end
