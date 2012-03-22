class Language < ActiveRecord::Base
  uses_translations(:foreign_key => 'original_language_id')
  has_many :data_objects
  has_many :users
  has_many :taxon_concept_names

  def self.find_active
    cached("active_languages") do
      self.find(:all, :conditions => ['activated_on <= ?', Time.now.to_s(:db)], :order => 'sort_order ASC, source_form ASC')
    end
  end

  def self.approved_languages
    approved_language_iso_codes = APPROVED_LANGUAGES rescue ['en', 'es', 'ar']
    cached("approved_languages") do
      self.find_all_by_iso_639_1(approved_language_iso_codes, :order => 'sort_order ASC, source_form ASC')
    end
  end

  def self.scientific
    cached_find_translated(:label, 'Scientific Name')
  end

  def self.with_iso_639_1
    cached("all_languages_with_iso_639_1") do
      Language.find(:all, :conditions => "iso_639_1 != '' AND iso_639_1 IS NOT NULL")
    end
  end

  def self.from_iso(iso, params={})
    cached_find(:iso_639_1, iso)
  end

  def self.find_by_iso_exclusive_scope(iso)
    with_exclusive_scope do
      find_by_iso_639_1(iso)
    end
  end

  # Migrations make it possible that the 'en' will either be in the languages table or its translated table.  This
  # ensures we grab it from whichever place is currently appropriate. This method will also create English is it does
  # not already exist
  def self.english_for_migrations
    eng_lang = nil
    eng_lang = find_by_iso_exclusive_scope('en')
    unless eng_lang
      eng_lang = Language.create(:iso_639_1 => 'en', :iso_639_2 => 'eng', :iso_639_3 => 'eng',
        :source_form => 'English', :sort_order => 1)
      TranslatedLanguage.create(:label => 'English', :original_language_id => eng_lang.id, :language_id => eng_lang.id)
    end
    eng_lang
  end

  def self.id_from_iso(iso_code)
    cached("id_from_iso_#{iso_code}") do
      # NOT using ActiveRecord here because I want to avoid the after_initialize callback
      # this is very important - the after_initialize callback for languages creates an infinite loop
      result = connection.select_values("SELECT id FROM languages WHERE iso_639_1='#{iso_code}'")
      result.empty? ? nil : result[0].to_i
    end
  end

  def self.default
    cached('default') do
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

  # this is only to be used, and should only work, in the test environment
  def self.create_english
    e = Language.gen_if_not_exists(:iso_639_1 => 'en', :source_form => 'English')
    TranslatedLanguage.gen_if_not_exists(:label => 'English', :original_language_id => e.id)
  end

  def display_code
    iso_code.upcase
  end

  def iso_code
    iso_639_1
  end
end
