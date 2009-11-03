class TaxonConceptName < SpeciesSchemaModel
  belongs_to :name
  belongs_to :taxon_concept
  belongs_to :language
  set_primary_keys :name_id, :taxon_concept_id, :source_hierarchy_entry_id

  has_many :taxa, :through => :names

  named_scope :common_preferred, :conditions => { :vern => 1, :preferred => 1 }
  named_scope :scientific_preferred, :conditions => { :vern => 0, :preferred => 1 }

  # We are having trouble using Rails' built-in update_attribute and/or setting the value and using save, so this
  # method uses raw SQL to accomplish the same thing using syntax we know will work.
  #
  # Returns the number of rows affected.  (Should always be either 1 or 0 because of PKs.)
  def set_preferred(val)
    raise "Cannot set the Preferred value to anything other than 1 or 0)" unless val == 0 or val == 1 # detaint
    connection.execute(%Q{
      UPDATE taxon_concept_names
      SET preferred = #{val}
      WHERE name_id = #{name_id.to_i} AND taxon_concept_id = #{taxon_concept_id.to_i}
        AND source_hierarchy_entry_id = #{source_hierarchy_entry_id.to_i} AND language_id = #{language_id.to_i}
    }) # to_i should be adequate de-tainting for injection attacks... which shouldn't hit this model anyway.
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: taxon_concept_names
#
#  language_id               :integer(4)      not null
#  name_id                   :integer(4)      not null
#  source_hierarchy_entry_id :integer(4)      not null
#  taxon_concept_id          :integer(4)      not null
#  preferred                 :integer(1)      not null
#  vern                      :integer(1)      not null

