class Vetted < SpeciesSchemaModel
  
  has_many :data_objects
  set_table_name "vetted"
  
  @@unknown = nil
  # These are just the class methods to grab the ones you want, without hitting the DB every time...


  def self.untrusted
    @@untrusted ||= Vetted.find_by_label('Untrusted')
  end
  
  def self.trusted
    @@trusted ||= Vetted.find_by_label('Trusted')
  end
  
  def self.unknown
    return @@unknown unless @@unknown.nil?
    @@unknown = Vetted.find_by_label('Unknown')
    # The ID *must* be 0 (PHP hard-coded; it also makes /sense/).  If it's not, we fix it now:
    if @@unknown.id != 0
      Vetted.connection.execute("UPDATE vetted SET id = 0 WHERE id = #{@@unknown.id}")
      @@unknown = Vetted.find_by_label('Unknown')
    end
    return @@unknown
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

