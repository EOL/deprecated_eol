# TODO - ADD COMMENTS
class Mapping < SpeciesSchemaModel
  belongs_to :collection
  belongs_to :name

  delegate :ping_host?, :to => :collection

  def ping_host_url
    return collection.ping_host_url.gsub(/%ID%/, foreign_key)
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: mappings
#
#  id            :integer(4)      not null, primary key
#  collection_id :integer(3)      not null
#  name_id       :integer(4)      not null
#  foreign_key   :string(600)     not null

