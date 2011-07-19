class Language < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  uses_translations(:foreign_key => 'original_language_id')
  has_many :data_objects
  has_many :users
  has_many :taxon_concept_names
  
  def self.find_active
    cached("active_languages") do
      self.find(:all, :conditions => ['activated_on <= ?', Time.now.to_s(:db)], :order => 'sort_order ASC')
    end
  end
  
  def self.create_english
    e = Language.gen_if_not_exists(:iso_639_1 => 'en', :source_form => 'English')
    TranslatedLanguage.gen_if_not_exists(:label => 'English', :original_language_id => e.id)
    e
  end

  def self.scientific
    cached_find_translated(:label, 'Scientific Name')
  end

  def self.with_iso_639_1
    Language.find_by_sql("select * from languages where iso_639_1 != ''")
  end

  def self.from_iso(iso, params={})
    cached_find(:iso_639_1, iso)
  end

  def self.find_by_iso_exclusive_scope(iso)
    with_exclusive_scope do
      find_by_iso_639_1(iso)
    end
  end

  def self.id_from_iso(iso_code)
    cached("id_from_iso_#{iso_code}") do
      # NOT using ActiveRecord here because I want to avoid the after_initialize callback
      # this is very important - the after_initialize callback for languages creates an infinite loop
      result = connection.select_values("SELECT id FROM languages WHERE iso_639_1='#{iso_code}'")
      result.empty? ? nil : result[0].to_i
    end
  end

  def self.english # because it's a default.  No other language will have this kind of method.
    cached("english") do
      self.find_by_iso_exclusive_scope('en')
    end
  end

  def self.unknown
    @@unknown_language ||= cached_find_translated(:label, "Unknown")
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
