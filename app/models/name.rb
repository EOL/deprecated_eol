# Name is used for storing different variations of names of species (TaxonConcept)
#
# These names are not "official."  If they have a CanonicalForm, the 
# CanonicalForm is the "accepted" scientific name for the species.
#
class Name < SpeciesSchemaModel

  belongs_to :canonical_form

  has_many :taxon_concept_names
  has_many :taxa
  has_many :hierarchy_entries
  has_many :normalized_links
  has_many :mappings

  validates_presence_of :string
  validates_presence_of :italicized
  validates_presence_of :canonical_form

  def taxon_concepts
    return taxon_concept_names.collect {|tc_name| tc_name.taxon_concept}.flatten
  end

  def canonical
    return canonical_form.nil? ? 'not assigned' : canonical_form.string
  end

  def italicized_canonical
    # hoping these short-circuit messages help with debugging ... likely due to bad/incomplete fixture data?
    # return "(no canonical form, tc: #{ taxon_concepts.map(&:id).join(',') })" unless canonical_form
    return 'not assigned' unless canonical_form and canonical_form.string and not canonical_form.string.empty?
    return "<i>#{canonical_form.string}</i>"
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: names
#
#  id                  :integer(4)      not null, primary key
#  canonical_form_id   :integer(4)      not null
#  namebank_id         :integer(4)      not null
#  canonical_verified  :integer(1)      not null
#  italicized          :string(300)     not null
#  italicized_verified :integer(1)      not null
#  string              :string(300)     not null

