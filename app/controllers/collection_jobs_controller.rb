class CollectionJobsController < ApplicationController

  before_filter :force_login
  before_filter :create_collection_if_asked
  before_filter :read_collection_job_from_params

  layout 'choose_collect_target'

  def create
    return redirect_to(@collection_job.collection, notice: I18n.t(:error_no_items_selected)) unless
      @collection_job.has_items?
    create_collection_if_asked
    @sorts = {
      I18n.t(:sort_by_alphabetical_option) => :alpha,
      I18n.t(:sort_by_recently_updated_option) => :recent,
    }
    unless @collection_job.missing_targets?
      if @collection_job.save
        # TODO - we really want to decide if this is a "big" job and delay it, if so.
        Collection.with_master do
          Collection.uncached { @collection_job.run }
        end
        redirect_to job_should_redirect_to, notice: complete_notice
      else
        redirect_to @collection_job.collection # TODO - errors are lost because we redirect rather than render...  fix.
      end
    end
    @collections = current_user.all_non_resource_collections # A little weird, but use the 'create' view to get the targets...
    @collections_recently_updated = @collections.sort_by(&:updated_at).reverse
  end

  private

  def force_login
    raise EOL::Exceptions::MustBeLoggedIn unless logged_in?
  end

  def read_collection_job_from_params
    # Convert the sumbit button to a command by looking for each valid command in the 'raw' params:
    CollectionJob::VALID_COMMANDS.each do |command|
      params[:collection_job][:command] = command if params.delete(command)
    end
    # Convert all_items:
    params[:collection_job][:all_items] = true if params[:scope] == 'all_items'
    # TODO - Either remove the "other scopes" (and reduce the complexity of the controller/view) from collections,
    # or handle them here. ie: "All Images", "All Taxa" ... doesn't seem to work ATM, so I say remove it.
    # And add the user as we create the new Job:
    @collection_job = CollectionJob.new(params[:collection_job].reverse_merge(user: current_user))
  end

  def complete_notice
    # NOTE - values for command can be found in CollectionJob::VALID_COMMANDS
    I18n.t("collection_#{@collection_job.command}_complete_with_count",
           count: @collection_job.item_count,
           from: link_to_name(@collection_job.collection),
           to: @collection_job.collections.map { |col| link_to_name(col) }.to_sentence )
  end

  def link_to_name(collection)
    return "ERROR: UNKNOWN COLLECTION" unless collection
    self.class.helpers.link_to(collection.name, collection_path(collection))
  end

  def job_should_redirect_to
    collection = @collection_job.collection
    # If they only copy/moved to ONE collection, take them there:
    collection = @collection_job.collections.first if @collection_job.target_needed? && @collection_job.collections.count == 1
    collection
  end

  def create_collection_if_asked
    if params[:collection_job] && params[:collection_job][:collection_ids] &&
       params[:collection_job][:collection_ids].delete("0") && params[:collection_name]
      collection = Collection.new(name: params[:collection_name])
      if collection.save
        collection.users = [current_user]
        params[:collection_job][:collection_ids] << collection.id
      else
        raise "Critical error creating new collection." # this shouldn't happen unless, say, DB is down.
      end
    end
  end

end
