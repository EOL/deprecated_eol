class UntrustReason < SpeciesSchemaModel
  def self.misidentified
    Rails.cache.fetch('untrust_reasons/misidentified') do
      UntrustReason.find_by_label('Misidentified')
    end
  end

  def self.incorrect
    Rails.cache.fetch('untrust_reasons/incorrect') do
      UntrustReason.find_by_label('Incorrect')
    end
  end

  def self.poor
    Rails.cache.fetch('untrust_reasons/poor') do
      UntrustReason.find_by_label('Poor')
    end
  end

  def self.duplicate
    Rails.cache.fetch('untrust_reasons/duplicate') do
      UntrustReason.find_by_label('Duplicate')
    end
  end

  def self.other
    Rails.cache.fetch('untrust_reasons/other') do
      UntrustReason.find_by_label('Other')
    end
  end
end