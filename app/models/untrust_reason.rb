class UntrustReason < SpeciesSchemaModel
  
  has_many :actions_histories_untrust_reasons
  
  def self.misidentified
    cached_find(:label, 'Misidentified')
  end

  def self.incorrect
    cached_find(:label, 'Incorrect')
  end

  def self.poor
    cached_find(:label, 'Poor')
  end

  def self.duplicate
    cached_find(:label, 'Duplicate')
  end

  def self.other
    cached_find(:label, 'Other')
  end
end
