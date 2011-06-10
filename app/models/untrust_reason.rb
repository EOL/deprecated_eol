class UntrustReason < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :curator_activity_logs

  def self.misidentified
    cached_find_translated(:label, 'Misidentified')
  end

  def self.incorrect
    cached_find_translated(:label, 'Incorrect')
  end

  def self.poor
    cached_find_translated(:label, 'Poor')
  end

  def self.duplicate
    cached_find_translated(:label, 'Duplicate')
  end

  def self.other
    cached_find_translated(:label, 'Other')
  end
end
