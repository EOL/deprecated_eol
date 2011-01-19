class Language < SpeciesSchemaModel
  has_many :data_objects
  has_many :users
  has_many :taxon_concept_names

  named_scope :find_active, lambda { { :conditions => ['activated_on <= ?', Time.now.to_s(:db)], :order => 'sort_order ASC' } }

  def self.scientific
    Language.find_by_label('Scientific Name')
  end
  
  def self.with_iso_639_1
    Language.find_by_sql("select * from languages where iso_639_1 != ''") 
  end

  def self.english # because it's a default.  No other language will have this kind of method.
    Language.find_by_iso_639_1('en')
  end

  def self.unknown
    @@unknown_language ||= Language.find_by_label("Unknown")
  end
  
  def display_code
    iso_639_1.upcase
  end

  def abbr
    iso_639_1.downcase
  end

end
