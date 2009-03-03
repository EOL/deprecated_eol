class Vetted < SpeciesSchemaModel
  
  has_many :data_objects
  set_table_name "vetted"
  
  def self.untrusted
    Rails.cache.fetch(:untrusted_vet) do
      Vetted.find_by_label('Untrusted')
    end
  end
  
  def self.trusted
    Rails.cache.fetch(:trusted_vet) do
      Vetted.find_by_label('Trusted')
    end
  end
  
  def self.unknown
    Rails.cache.fetch(:unknown_vet) do
      unknown = Vetted.find_by_label('Unknown')
      # The ID *must* be 0 (PHP hard-coded; it also kinda makes sense, though I might have allowed nulls).
      # If it's not, we fix it now:
      if unknown.id != 0
        Vetted.connection.execute("UPDATE vetted SET id = 0 WHERE id = #{unknown.id}")
        unknown = Vetted.find_by_label('Unknown')
      end
      unknown
    end
  end

  def self.trusted_ids  
    self.trusted.id.to_s
  end
  
  def self.untrusted_ids
    [self.untrusted.id,self.unknown.id].join(',') 
  end
 
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: vetted
#
#  id         :integer(4)      not null, primary key
#  label      :string(255)     default("")
#  created_at :datetime
#  updated_at :datetime

