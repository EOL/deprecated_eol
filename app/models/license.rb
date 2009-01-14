class License < SpeciesSchemaModel
  has_many :data_objects
  has_many :resources

  def small_logo_url
    return logo_url if logo_url =~ /_small/ # already there!
    return logo_url.sub(/\.(\w\w\w)$/, "_small.\\1")
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: licenses
#
#  id          :integer(2)      not null, primary key
#  description :string(400)     not null
#  logo_url    :string(255)     not null
#  source_url  :string(255)     not null
#  title       :string(255)     not null
#  version     :string(6)       not null

