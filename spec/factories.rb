require 'factory_girl'

Factory.define :hierarchy_entry do |he|
  he.remote_id        ''
  he.depth            2
  he.ancestry         ''
  he.lft              1
  he.rank_id          184
  he.parent_id        0
  he.association      :name
  he.association      :taxon_concept
  he.rgt              2
  he.identifier       ''
  he.association      :hierarchy
end

Factory.define :taxon_concept do |tc|
  tc.published      0
  tc.vetted_id      { Vetted.trusted.id }
  tc.supercedure_id 0
end

Factory.define :taxon_concept_name do |tcn|
  tcn.preferred              1
  tcn.vern                   0
  tcn.source_hierarchy_entry {|he| he.association(:hierarchy_entry) }
  tcn.language_id            { Language.scientific.id }
  tcn.association            :name
  tcn.association            :taxon_concept
end

Factory.define :name do |name|
  name.italicized          '<i>Somethia specificus</i> Posford & R. Ram'
  name.canonical_form      {|cform| cform.association(:canonical_form, :string => 'Somethia specificus')}
  name.string              'Somethia specificus Posford & R. Ram'
  name.canonical_verified  0
  name.italicized_verified 0
  name.namebank_id         0
end

Factory.define :canonical_form do |cform|
  cform.string 'Cononica idenitifii'
end

Factory.define :hierarchy do |hierarchy|
  hierarchy.label                   "A nested structure of divisions related to their probable evolutionary descent"
  hierarchy.url                     ""
  hierarchy.hierarchy_group_version 0
  hierarchy.hierarchy_group_id      1 # TODO - associate
  hierarchy.description             ""
  hierarchy.agent_id                11 # TODO - associate
end
