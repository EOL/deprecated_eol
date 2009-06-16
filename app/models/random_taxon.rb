#
# ... why is this a model / table?
#
# Why isn't this just TaxonConcept.random?
#
class RandomTaxon < SpeciesSchemaModel
  belongs_to :language
  belongs_to :data_object
  belongs_to :taxon_concept
  
  delegate :quick_scientific_name, :to => :taxon_concept
  delegate :quick_common_name, :to => :taxon_concept

  @@min     = nil
  @@max     = nil
  @@cl4_min = nil
  @@cl4_max = nil
  @@last_cleared = nil
  @@count = nil
  @@looping = false

  def self.random_set(limit = 10)
    list = []
    RandomTaxon.reset_count
    starting_id = rand(@@count - limit).floor
    starting_id = 0 if starting_id > (@@count - limit) # This only applies when there are very few RandomTaxa.
    list = RandomTaxon.find_by_sql(['SELECT * FROM random_taxa LIMIT ?, ?', starting_id, limit])
    raise "Found no Random Taxa in the database (#{starting_id}, #{limit})" if list.blank?
    return list
  end
  
  # The first one takes a little longer, since it needs to populate the class variables.  But after that, it's quite fast:
  def self.random()
    return self.random_set(1)[0]
  end

  # NOTE - This is difficult to test with specs.  To test manually:
  # 1) script/console
  # 2) RandomTaxon.random should give you a taxon.
  # 3) mysql; delete from random_taxa;
  # 4) RandomTaxon.random should raise "There are no Random Taxa in the database".  DO NOT close your console!
  # 5) rake denormal:build_random_taxa
  # 6) RandomTaxon.random should give you a taxon again.

  
  def self.reset_count
    if @@last_cleared.blank? || @@last_cleared.advance(:hours=>1) < Time.now
      @@last_cleared = Time.now()
      @@count = SpeciesSchemaModel.connection.select_value('select count(*) count from random_taxa').to_i
    end
  end

  # So, if we just called name(), return our cached version; otherwise, delegate to HE.
  def name(*args)
    args.empty? ? self[:name] : taxon_concept.name(args[0], args[1])
  end
  
  def smart_thumb
    self.data_object.smart_thumb
  end
  
  def smart_medium_thumb
    #return thumb_url.sub(/_small\.png/, '_medium.png')
    self.data_object.smart_medium_thumb
  end
  
  def smart_image
    return image_url
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: random_taxa
#
#  id               :integer(4)      not null, primary key
#  data_object_id   :integer(4)      not null
#  language_id      :integer(4)      not null
#  name_id          :integer(4)      not null
#  taxon_concept_id :integer(4)
#  common_name_en   :string(255)     not null
#  common_name_fr   :string(255)     not null
#  content_level    :integer(4)      not null
#  image_url        :string(255)     not null
#  name             :string(255)     not null
#  thumb_url        :string(255)     not null
#  created_at       :timestamp       not null

