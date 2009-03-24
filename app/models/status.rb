class Status < SpeciesSchemaModel
  has_many :harvest_events_taxa
  has_many :data_objects_harvest_events
  
  def self.inserted
    YAML.load(Rails.cache.fetch('statuses/inserted') do
      Status.find_by_label('inserted').to_yaml
    end)
  end

  def self.updated
    YAML.load(Rails.cache.fetch('statuses/updated') do
      Status.find_by_label('updated').to_yaml
    end)
  end

  def self.unchanged
    YAML.load(Rails.cache.fetch('statuses/unchanged') do
      Status.find_by_label('unchanged').to_yaml
    end)
  end

end

# == Schema Info
# Schema version: 20081002192244
#
# Table name: statuses
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null

# == Schema Info
# Schema version: 20081020144900
#
# Table name: statuses
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null

