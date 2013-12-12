class Taxa::CommunitiesController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @communities = @taxon_concept.communities
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_communities, taxon_concept_id: @taxon_concept.id)
    @rel_canonical_href = taxon_communities_url(@taxon_page)
  end

  def collections
    @collections = @taxon_concept.collections.select{ |c| c.published? && !c.watch_collection? }
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_collections, taxon_concept_id: @taxon_concept.id)
    @rel_canonical_href = collections_taxon_communities_url(@taxon_page)
  end

  def curators
    @curators = @taxon_concept.data_object_curators
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_curators, taxon_concept_id: @taxon_concept.id)
    @rel_canonical_href = curators_taxon_communities_url(@taxon_page)
  end

end
