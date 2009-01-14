# TODO - ADD COMMENTS
class Collection < SpeciesSchemaModel
  belongs_to :agent
  has_many   :mappings

  #TODO - Make logo associated with agents instead of a hardcoded field in the database called "logo_url" (so image can be moved to content server)
  
  def self.fishbase
    @@fishbase ||= Collection.find_by_title('FishBase species detail')
  end

  def ping_host?
    return id == Collection.fishbase.id
  end

  def ping_host_url
    return 'http://www.fishbase.ca/utility/log/eol/record.php?id=%ID%'
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: collections
#
#  id          :integer(3)      not null, primary key
#  agent_id    :integer(4)      not null
#  description :string(300)     not null
#  link        :string(255)     not null
#  logo_url    :string(255)     not null
#  title       :string(150)     not null
#  uri         :string(255)     not null
#  vetted      :integer(1)      not null

