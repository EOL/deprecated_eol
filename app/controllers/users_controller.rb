class UsersController < ApplicationController

  layout 'main'
  @@objects_per_page = 20

  def show
    @user = User.find(params[:id])
    @feed_item = FeedItem.new(:feed_id => @user.id, :feed_type => @user.class.name)

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  def objects_curated
    page = (params[:page] || 1).to_i
    @user = User.find(params[:id])
    current_user.log_activity(:show_objects_curated_by_user_id, :value => params[:id])
    @latest_curator_actions = @user.curator_activity_logs_on_data_objects.paginate_all_by_action_with_object_id(
                                ActionWithObject.raw_curator_action_ids,
                                :select => 'curator_activity_logs.*',
                                :order => 'curator_activity_logs.updated_at DESC',
                                :group => 'curator_activity_logs.object_id',
                                :include => [ :action_with_object ],
                                :page => page, :per_page => @@objects_per_page)
    @curated_datos = DataObject.find(@latest_curator_actions.collect{|lca| lca[:object_id]},
                       :select => 'data_objects.id, data_objects.description, data_objects.object_cache_url, ' +
                                  'hierarchy_entries.taxon_concept_id, hierarchy_entries.published, ' +
                                  'taxon_concepts.*, names.italicized' ,
                       :include => [ :vetted, :visibility, :toc_items,
                                     { :hierarchy_entries => [ :taxon_concept, :name ] } ])
    @latest_curator_actions.each do |ah|
      dato = @curated_datos.detect {|item| item[:id] == ah[:object_id]}
      # We use nested include of hierarchy entries, taxon concept and names as a first cheap
      # attempt to retrieve a scientific name.
      # TODO - dato.hierarchy_entries does not account for associations created by (or untrusted by) curators.  That
      # said, this whole method is too much code in a controller and should be re-written, so we are not (right now)
      # going to fix this.  Please create the data in a model and display it in the view.
      dato.hierarchy_entries.each do |he|
        # TODO: Check to see if this is using eager loading or not!
        if he.taxon_concept.published == 1 then
          dato[:_preferred_name_italicized] = he.name.italicized
          dato[:_preferred_taxon_concept_id] = he.taxon_concept_id
          break
        end
      end

      if dato[:_preferred_taxon_concept_id].nil? then
        # Hierarchy entries have not given us a published taxon concept so either the concept has been superceded
        # or its a user submitted data object, either way we go on a hunt for a published taxon concept with some
        # expensive queries.
        tcs = dato.get_taxon_concepts(:published => :preferred)
        tc = tcs.detect{|item| item[:published] == 1}
        # We only add a preferred taxon concept id if we've found a published taxon concept.
        dato[:_preferred_taxon_concept_id] = tc.nil? ? nil : tc[:id]
        # Finally we find a name, first we try cheaper hierarchy entries, if that fails we try through taxon concepts.
        dato[:_preferred_name_italicized] = dato.hierarchy_entries.first.name[:italicized] unless dato.hierarchy_entries.first.nil?
        if dato[:_preferred_name_italicized].nil? then
          tc = tcs.first if tc.nil? # Grab the first unpublished taxon concept if we didn't find a published one earlier.
          dato[:_preferred_name_italicized] = tc.nil? ? nil : tc.quick_scientific_name(:italicized)
        end
      end

      dato[:_description_teaser] = ""
      unless dato.description.blank? then
        dato[:_description_teaser] = Sanitize.clean(dato.description, :elements => %w[b i],
                                                    :remove_contents => %w[table script])
        dato[:_description_teaser] = dato[:_description_teaser].split[0..80].join(' ').balance_tags +
                                     '...' if dato[:_description_teaser].length > 500
      end

    end
  end

  def species_curated
    page = (params[:page] || 1).to_i
    @user = User.find(params[:id])
    current_user.log_activity(:show_species_curated_by_user_id, :value => params[:id])
    @taxon_concept_ids = @user.taxon_concept_ids_curated.paginate(:page => page, :per_page => @@objects_per_page)
  end

  def comments_moderated
    page = (params[:page] || 1).to_i
    @user = User.find(params[:id])
    current_user.log_activity(:show_species_comments_moderated_by_user_id, :value => params[:id])
    comment_curation_actions = @user.comment_curation_actions
    @comment_curation_actions = comment_curation_actions.paginate(:page => page, :per_page => @@objects_per_page)
  end

end
