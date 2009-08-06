# A Collection represents... uhhh... a distinct collection (!) of data that a given Agent has.  For exampe,
# one website (one Agent) may have a collection of butterflie data as well as a collection of shark data.
# This object allows us to distinquish the two. This is important for citing a data object: the URI for the
# butterflies may be very different than the URI to sharks.
class Collection < SpeciesSchemaModel
  belongs_to :agent
  belongs_to :resource
  has_many   :mappings
  has_and_belongs_to_many :collection_types

  #TODO - Make logo associated with agents instead of a hardcoded field in the database called "logo_url" (so image can be moved to content server)
  
  # Fishbase is a collection that we reference often and have specific behaviours for
  def self.fishbase
    Rails.cache.fetch('collections/fishbase') do
      Collection.find_by_title('FishBase species detail')
    end
  end

  # A particular TocEntry is created for these guys:
  def self.ligercat
    Rails.cache.fetch('collections/ligercat') do
      Collection.find_by_title('LigerCat')
    end
  end

  # Some collections want us to "ping" them every time a DataObject they authored is referenced on our site.
  def ping_host?
    return false if self[:ping_host_url].blank?
    return true
  end
  
  # override the logo_url column in the database to contruct the path on the content server
  def logo_url(size='large')
    prefix=self.attributes['logo_cache_url']
    if prefix.blank?
       #self.logo.url # this is the "paperclip" plugin attached image, but it might only be on one of the application servers
       result="/images/blank.gif"
    else    
       logo_size = (size == "large") ? "_large.png" : "_small.png"
       result="#{ContentServer.next}" + $CONTENT_SERVER_AGENT_LOGOS_PATH + "#{prefix.to_s + logo_size}"
    end
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

