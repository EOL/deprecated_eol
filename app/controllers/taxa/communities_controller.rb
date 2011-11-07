class Taxa::CommunitiesController < TaxaController

  before_filter :instantiate_taxon_concept

  def index
    @communities = @taxon_concept.communities
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_communities, :taxon_concept_id => @taxon_concept.id)
  end

  def collections
    @collections = @taxon_concept.collections.select{ |c| c.published? && !c.watch_collection? }
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_collections, :taxon_concept_id => @taxon_concept.id)
  end

  def curators
    @curators = @taxon_concept.data_object_curators
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_curators, :taxon_concept_id => @taxon_concept.id)
  end

end
