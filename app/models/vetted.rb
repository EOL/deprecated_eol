class Vetted < SpeciesSchemaModel
  set_table_name "vetted"
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :data_objects
  has_many :taxon_concepts
  has_many :hierarchy_entries

  def self.untrusted
    cached_find_translated(:label, 'Untrusted')
  end
  
  def self.trusted
    cached_find_translated(:label, 'Trusted')
  end
  
  def self.unknown
    cached_find_translated(:label, 'Unknown')
  end

  def self.trusted_ids  
    self.trusted.id.to_s
  end
  
  def self.untrusted_ids
    [self.untrusted.id,self.unknown.id].join(',') 
  end

  def sort_weight
    weights = vetted_weight
    return weights.has_key?(id) ? weights[id] : 4
  end

  def to_action
    return 'unreviewed' if label.downcase == 'unknown'
    return label.downcase
  end
  
private

  def vetted_weight
    @@vetted_weight = {Vetted.trusted.id => 1, Vetted.unknown.id => 2, Vetted.untrusted.id => 3} if
      ENV['RAILS_ENV'] =~ /test/ # Set it every time, because it changes a lot in the test env!
    @@vetted_weight ||= {Vetted.trusted.id => 1, Vetted.unknown.id => 2, Vetted.untrusted.id => 3}
  end
 
end
