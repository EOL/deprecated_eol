class Status < SpeciesSchemaModel
  has_many :harvest_events_taxa
  has_many :data_objects_harvest_events
  
    def self.inserted
      @@inserted ||= Status.find_by_label('inserted')
    end

    def self.updated
      @@updated ||= Status.find_by_label('updated')
    end

    def self.unchanged
      @@unchanged ||= Status.find_by_label('unchanged')
    end

end# == Schema Info
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

