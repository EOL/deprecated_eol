class Taxa::MediaController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show

    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => { :toc_items => :info_items } },
      { :top_concept_images => :data_object },
      { :last_curated_dates => :user },
      { :users_data_objects => { :data_object => :toc_items } }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating ],
      :table_of_contents => '*',
      :last_curated_dates => '*',
      :users => [ :given_name, :family_name ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @media = sort_filter_media(@taxon_concept.media)
    @assistive_section_header = I18n.t(:assistive_media_header)
    current_user.log_activity(:viewed_taxon_concept_media, :taxon_concept_id => @taxon_concept.id)
  end
  
private
  def sort_filter_media(media)
    @sort_by = params[:sort_by] || "default"
    @filter_by_type_all = params[:filter_by_type_all] || false
    @filter_by_type_image = params[:filter_by_type_image] || false
    @filter_by_type_video = params[:filter_by_type_video] || false
    @filter_by_type_audio = params[:filter_by_type_audio] || false
    @filter_by_type_photosynth = params[:filter_by_type_photosynth] || false
    
    # this is for default
    if !params[:sort_by] then @filter_by_type_all = true end
      
    filter_by_type = {}
    filter_by_type["all"] = @filter_by_type_all
    filter_by_type["image"] = @filter_by_type_image
    filter_by_type["video"] = @filter_by_type_video
    filter_by_type["audio"] = @filter_by_type_audio
    filter_by_type["photosynth"] = @filter_by_type_photosynth
    @filter_by_status_all = params[:filter_by_status_all] || false
    @filter_by_status_trusted = params[:filter_by_status_trusted] || false
    @filter_by_status_untrusted = params[:filter_by_status_untrusted] || false
    @filter_by_status_unreviewed = params[:filter_by_status_unreviewed] || false
    @filter_by_status_inappropriate = params[:filter_by_status_inappropriate] || false
    filter_by_status = {}
    filter_by_status["all"] = @filter_by_status_all
    filter_by_status["trusted"] = @filter_by_status_trusted
    filter_by_status["untrusted"] = @filter_by_status_untrusted
    filter_by_status["unreviewed"] = @filter_by_status_unreviewed
    filter_by_status["inappropriate"] = @filter_by_status_inappropriate
    media = DataObject.custom_filter(media, filter_by_type, filter_by_status)
    @media = DataObject.custom_sort(media, @sort_by).paginate(:page => params[:page], :per_page => $MAX_IMAGES_PER_PAGE)
  end

  def redirect_if_superceded
    redirect_to taxon_media_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end
end
