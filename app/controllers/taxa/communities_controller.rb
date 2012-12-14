class Taxa::CommunitiesController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @communities = @taxon_concept.communities
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_communities, :taxon_concept_id => @taxon_concept.id)
    @rel_canonical_href = @selected_hierarchy_entry ?
      taxon_entry_communities_url(@taxon_concept, @selected_hierarchy_entry) :
      taxon_communities_url(@taxon_concept)
    if params[:ajax]
      render :partial => 'taxa/communities/communities'
    end
  end

  def collections
    @collections = @taxon_concept.collections.select{ |c| c.published? && !c.watch_collection? }
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_collections, :taxon_concept_id => @taxon_concept.id)
    @rel_canonical_href = @selected_hierarchy_entry ?
      collections_taxon_entry_communities_url(@taxon_concept, @selected_hierarchy_entry) :
      collections_taxon_communities_url(@taxon_concept)
  end

  def curators
    @curators = @taxon_concept.data_object_curators
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_curators, :taxon_concept_id => @taxon_concept.id)
    @rel_canonical_href = @selected_hierarchy_entry ?
      curators_taxon_entry_communities_url(@taxon_concept, @selected_hierarchy_entry) :
      curators_taxon_communities_url(@taxon_concept)
  end

end
