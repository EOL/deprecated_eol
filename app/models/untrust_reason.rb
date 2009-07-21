class UntrustReason < SpeciesSchemaModel
  def self.misidentified
    YAML.load(Rails.cache.fetch('untrust_reasons/misidentified') do
      self.find_by_label('Misidentified').to_yaml
    end)
  end

  def self.incorrect
    YAML.load(Rails.cache.fetch('untrust_reasons/incorrect') do
      self.find_by_label('Incorrect').to_yaml
    end)
  end

  def self.poor
    YAML.load(Rails.cache.fetch('untrust_reasons/poor') do
      self.find_by_label('Poor').to_yaml
    end)
  end

  def self.duplicate
    YAML.load(Rails.cache.fetch('untrust_reasons/duplicate') do
      self.find_by_label('Duplicate').to_yaml
    end)
  end

  def self.other
    YAML.load(Rails.cache.fetch('untrust_reasons/other') do
      self.find_by_label('Other').to_yaml
    end)
  end
end