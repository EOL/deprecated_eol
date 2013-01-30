# This is a generalization used for presenters for Taxon Concepts... things like TaxonPage and TaxonOverview. All of
# them load a taxon concept and filter it by user and (optionally by) hierarchy_entry/classification.
module TaxonPresenter

  attr_reader :taxon_concept, :user

  def initialize(taxon_concept, user, hierarchy_entry = nil) 
    @taxon_concept = taxon_concept
    @user = user
    @taxon_concept.current_user = user # TODO - do we need this anymore?
    @_hierarchy_entry = hierarchy_entry
  end

  # NOTE - *THIS IS IMPORTANT* ... when you see "_hierarchy_entry", it means "the one specified by initialize." When
  # you see "hierarchy_entry" (no leading underscore) it means "do the right thing".
  def hierarchy_entry
    _hierarchy_entry || @taxon_concept.entry
  end

  # This tells you whether the presenter is being viewed with a classification filter. ...Of course. Please don't
  # trust the return value to be the actual HE; you should only be using this for t/f tests.
  def classifcation_filter?
    _hierarchy_entry
  end

  # helper.link_to "foo", app.overview_taxon_path(taxon_page) # Results depend on hierarchy_entry:
  # => "<a href=\"/pages/910093/hierarchy_entries/16/overview\">foo</a>"
  # OR
  # => "<a href=\"/pages/910093/overview\">foo</a>"
  def to_param
    classifcation_filter? ? "#{taxon_concept.to_param}/hierarchy_entries/#{_hierarchy_entry.to_param}" :
                            taxon_concept.to_param
  end

  # NOTE - these map methods are perhaps not best-suited to living here, but at the moment, it's the best place for
  # them since they are used by both classes that implement this module:
  def map_taxon_concept
    @map_taxon_concept ||= classifcation_filter? ? _hierarchy_entry.taxon_concept : taxon_concept
  end

  def gbif_map_id
    map_taxon_concept.gbif_map_id
  end

  # This is perhaps a bit too confusing: this checks if the *filtered* page really has a map (as opposed to whether
  # there is any map at all without filters):
  def map?
    map_taxon_concept.has_map? && map
  end

end
