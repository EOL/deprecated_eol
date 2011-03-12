class Language < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  has_many :data_objects
  has_many :users
  has_many :taxon_concept_names

  named_scope :find_active, lambda { { :conditions => ['activated_on <= ?', Time.now.to_s(:db)], :order => 'sort_order ASC' } }

  def self.scientific
    cached_find(:label, 'Scientific Name')
  end
  
  def self.with_iso_639_1
    Language.find_by_sql("select * from languages where iso_639_1 != ''") 
  end
  
  def self.from_iso(iso_code, params={})
    cached_find(:iso_639_1, iso_code)
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
    self.from_iso('en')
  end

  def self.unknown
    @@unknown_language ||= cached_find(:label, "Unknown")
  end
  
  def display_code
    iso_639_1.upcase
  end

  def abbr
    iso_639_1.downcase
  end

end
