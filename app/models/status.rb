class Status < SpeciesSchemaModel
  has_many :harvest_events_taxa
  has_many :data_objects_harvest_events
  
    def self.inserted
      Rails.cache.fetch(:inserted_status) do
        Status.find_by_label('inserted')
      end
    end

    def self.updated
      Rails.cache.fetch(:updated_status) do
        Status.find_by_label('updated')
      end
    end

    def self.unchanged
      Rails.cache.fetch(:unchanged_status) do
        Status.find_by_label('unchanged')
      end
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

