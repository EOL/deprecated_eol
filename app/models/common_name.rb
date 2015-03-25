# This is a class used by Tramea.
class CommonName < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :summary,
    primary_key: "taxon_concept_id",
    foreign_key: "taxon_concept_id"
  has_many :name_sources

  def self.from_taxon_concept_name(tcn)
    return find_by_taxon_concept_id_and_name_and_language(
      tcn.taxon_concept_id,
      tcn.name.string,
      tcn.language.iso_639_1) if
      exists?(
        taxon_concept_id: tcn.taxon_concept_id,
        name: tcn.name.string,
        language: tcn.language.iso_639_1
      )
    common_name = create(
      taxon_concept_id: tcn.taxon_concept_id,
      language: tcn.language.iso_639_1,
      name: tcn.name.string,
      trusted: tcn.vetted_id == Vetted.trusted.id,
      preferred: tcn.preferred?,
      hidden: tcn.visibility_id == Visibility.invisible.id
    )
    # NOTE: I'm duplicating logic from TaxaHelper#common_name_display_attribution
    common_name.name_sources = tcn.agents.map do |agent|
      if agent.user
        NameSource.create(
          name: agent.user.full_name,
          source: agent.user,
          common_name: common_name
        )
      else
        NameSource.create(
          name: agent.full_name,
          source: agent,
          common_name: common_name
        )
      end
    end
    common_name.name_sources += tcn.hierarchies.map do |hierarchy|
      NameSource.create(
        name: hierarchy.resource.title,
        # NOTE: content_partner is a METHOD on hierarchy, not an association:
        content_partner_id: hierarchy.content_partner.id,
        source: hierarchy.resource,
        common_name: common_name
      )
    end
    # OMG. ...If a name has no other attribution, it's considered to be uBio.
    # Yes, really. THIS IS SO LAME.  TODO: fix this in the db (then clean up
    # the code in the helper, at least)
    if common_name.name_sources.empty?
      common_name.name_sources <<
        NameSource.create(
          name: "uBio",
          source: Hierarchy.ubio,
          common_name: common_name
        )
    end
    common_name
  end
end
