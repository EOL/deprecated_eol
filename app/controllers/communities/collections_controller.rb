class Communities::CollectionsController < CommunitiesController

  before_filter :load_community_and_dependent_vars, :only => [:index]

  def index
    # TODO: Sort endorsed collections param[:sort_by] :oldest or :newest
  end

end
