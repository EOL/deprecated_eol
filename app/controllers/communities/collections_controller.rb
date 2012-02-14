class Communities::CollectionsController < CommunitiesController

  # These are required because the declaration in CommunitiesController excludes index (for a good reason):
  before_filter :load_community_and_dependent_vars, :only => [:index]
  # TODO - when the commands are added, the login should be required and the restrictions should be placed.  See
  # CommunitiesController.

  def index
    # TODO: Sort endorsed collections param[:sort_by] :oldest or :newest
    @rel_canonical_href = community_collections_url(@community)
  end

end
