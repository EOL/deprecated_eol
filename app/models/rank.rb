class Rank < SpeciesSchemaModel
  has_many :hierarchy_entries
  
  def self.italicized_ids
    @@italicized_ids ||= self.italicized_ids_sub
  end
  
  def self.italicized_ids_sub
    ids = []
    ids << Rank.find_by_label('species').id
    ids << Rank.find_by_label('infraspecies').id
    ids << Rank.find_by_label('subspecies').id
    ids << Rank.find_by_label('variety').id
    ids << Rank.find_by_label('form').id
    
    ids
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: ranks
#
#  id            :integer(2)      not null, primary key
#  rank_group_id :integer(2)      not null
#  label         :string(50)      not null

