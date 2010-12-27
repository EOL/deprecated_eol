class DataObjectsController < ApplicationController

  # No layout for Ajax calls.  Everthing else uses main:
  layout proc { |c| c.request.xhr? ? false : "main" }

  before_filter :set_data_object, :except => [:index, :new, :create, :preview]
  before_filter :curator_only, :only => [:rate, :curate]

  def create
    params[:references] = params[:references].split("\n") unless params[:references].blank?
    data_object = DataObject.create_user_text(params, current_user)
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @curator = current_user.can_curate?(@taxon_concept)
    @taxon_concept.current_user = current_user
    @category_id = data_object.toc_items[0].id
    alter_current_user do |user|
      user.vetted=false
    end
    current_user.log_activity(:created_data_object_id, :value => data_object.id, :taxon_concept_id => @taxon_concept.id)
    render(:partial => '/taxa/text_data_object',
           :locals => {:content_item => data_object, :comments_style => '', :category => data_object.toc_items[0].label})
  end

  def preview
    begin
      params[:references] = params[:references].split("\n")
      data_object = DataObject.preview_user_text(params, current_user)
      @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
      @taxon_concept.current_user = current_user
      @curator = false
      @preview = true
      @data_object_id = params[:id]
      @hide = true
      current_user.log_activity(:previewed_data_object, :taxon_concept_id => @taxon_concept.id)
      render :partial => '/taxa/text_data_object', :locals => {:content_item => data_object, :comments_style => '', :category => data_object.toc_items[0].label}
    rescue => e
      @message = e.message
    end
  end

  def get
    @taxon_concept = TaxonConcept.find params[:taxon_concept_id] if params[:taxon_concept_id]
    @taxon_concept.current_user = current_user
    @curator = current_user.can_curate?(@taxon_concept)
    @hide = true
    @category_id = @data_object.toc_items[0].id
    @text = render_to_string(:partial => '/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
    render(:partial => '/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
  end

  def update
    params[:references] = params[:references].split("\n")
    @taxon_concept = TaxonConcept.find params[:taxon_concept_id] if params[:taxon_concept_id]
    @taxon_concept.current_user = current_user
    @old_data_object_id = params[:id]
    @data_object = DataObject.update_user_text(params, current_user)
    @curator = current_user.can_curate?(@taxon_concept)
    @hide = true
    @category_id = @data_object.toc_items[0].id
    alter_current_user do |user|
      user.vetted=false
    end
    current_user.log_activity(:updated_data_object_id, :value => @data_object.id, :taxon_concept_id => @taxon_concept.id)
    render(:partial => '/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
  end

  def edit
    set_text_data_object_options
    @taxon_concept = TaxonConcept.find params[:taxon_concept_id] if params[:taxon_concept_id]
    @selected_language = [@data_object.language.label,@data_object.language.id]
    @selected_license = [@data_object.license.title,@data_object.license.id]
    current_user.log_activity(:editing_data_object, :taxon_concept_id => @taxon_concept.id)
    render :partial => 'edit_text'
  end

  def new
    if(logged_in?)
      @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
      @selected_license = [License.by_nc.title,License.by_nc.id]        
      @selected_language = [current_user.language.label,current_user.language.id]
      @toc_id_empty = params[:toc_id] == 'none'
      if (@toc_id_empty)
        @taxon_concept.current_user = current_user
        toc_item = @taxon_concept.tocitem_for_new_text
        params[:toc_id] = toc_item.id
      end
      set_text_data_object_options
      @data_object = DataObject.new
      render :partial => 'new_text'
      current_user.log_activity(:creating_new_data_object, :taxon_concept_id => @taxon_concept.id)
    else
      if $ALLOW_USER_LOGINS
        render :partial => 'login_for_text'
      else
        render :text => 'New text cannot be added at this time. Please try again later.'
      end
    end
  end

  def curator_only
    if !current_user.can_curate?(@data_object)
      raise Exception.new('Not logged in as curator')
    end
  end

  def rate
    @data_object.rate(current_user,params[:stars].to_i)

    expire_data_object(@data_object.id)
    current_user.log_activity(:rated_data_object_id, :value => @data_object.id)

    respond_to do |format|
      format.html {redirect_to request.referer ? :back : '/'} #todo, complete later
      format.js {render :action => 'rate.rjs'}
    end
  end


  # example urls this handles ...
  #
  #   /pages/5/images/2.xml  # Second page of TaxonConcept 5's images.
  #   /pages/5/videos/2.xml
  #
  # DEPRECATED ... There will be a new API that should cover this.  ...Which is good, because it appears to be BROKEN for
  # images (videos work).
  def index
    begin
      @taxon_concept = TaxonConcept.find params[:taxon_concept_id] if params[:taxon_concept_id]
    rescue ActiveRecord::RecordNotFound
      render :text => "Don't know how to render #{ params.inspect }"
      return
    end
    per_page = params[:per_page].to_i
    per_page = 10 if per_page < 1
    per_page = 50 if per_page > 50
    page     = params[:page].to_i
    page     = 1 if page < 1
    case request.path
    when /images/
      respond_to do |format|
        format.xml do
          xml = $CACHE.fetch("taxa/#{@taxon_concept.id}/images/#{page}.#{per_page}/xml", :expires_in => 4.hours) do
            images = @taxon_concept.images
            {
              :images           => images.paginate(:per_page => per_page, :page => page),
              'num-images'      => images.length,
              'images-per-page' => per_page,
              'page'            => page
            }.to_xml(:root => 'results')
          end
          render :xml => xml
        end
      end
      current_user.log_activity(:viewing_page_of_images, :value => page, :taxon_concept_id => @taxon_concept.id)
    when /videos/
      respond_to do |format|
        format.xml do
          xml = $CACHE.fetch("taxa/#{@taxon_concept.id}/videos/#{page}.#{per_page}/xml", :expires_in => 4.hours) do
            videos = @taxon_concept.videos
            {
              :videos           => videos.paginate(:per_page => per_page, :page => page),
              'num-videos'      => videos.length,
              'videos-per-page' => per_page,
              'page'            => page
            }.to_xml(:root => 'results')
          end
          render :xml => xml
        end
      end
      current_user.log_activity(:viewing_page_of_videos, :value => page, :taxon_concept_id => @taxon_concept.id)
    end
  end

  def show
    get_attribution
    @type = @data_object.data_type.label
    @comments = @data_object.all_comments.paginate(:page => params[:page], :order => 'updated_at DESC', :per_page => Comment.per_page)
    @slim_container = true
    @revisions = @data_object.revisions.sort_by(&:created_at).reverse
    @hierarchy_paths = get_harvested_paths
    @taxon_concepts = @data_object.taxon_concepts(:published => :preferred)
    @scientific_names = @taxon_concepts.inject({}) { |res, tc| res[tc.scientific_name] = { :common_name => tc.common_name, :taxon_concept_id => tc.id }; res }
    @image_source = get_image_source if @type == 'Image'
  end

  # GET /data_objects/1/attribution
  def attribution
    get_attribution
    render :partial => 'attribution', :locals => { :data_object => @data_object }, :layout => @layout
  end

  # GET /data_objects/1/curation
  # GET /data_objects/1/curation.js
  #
  # UI for curating a data object
  #
  # This is a GET, so there's no real reason to check to see 
  # whether or not the current_user can_curate the object - 
  # we leave that to the #curate method
  #
  def curation
  end

  # PUT /data_objects/1/curate
  def curate
    opts = {
      :vetted_id => params[:vetted_id], 
      :visibility_id => params[:visibility_id], 
      :untrust_reason_ids => params[:untrust_reasons], 
      :comment => params[:comment], 
      :taxon_concept_id => params[:taxon_concept_id], 
      :untrust_reasons_comment => params[:untrust_reasons_comment]
    }
    @data_object.curate(current_user, opts)
    expire_data_object(@data_object.id)
    current_user.log_activity(:curated_data_object_id, :value => @data_object.id)
    
    respond_to do |format|
      format.html {redirect_to request.referer ? :back : '/'}
      format.js {
        type = 'image'
        type = 'text' if @data_object.text?
        render :text => {:type => type, :args => [@data_object.id, @data_object.visibility_id, @data_object.vetted_id]}.to_json
      }
    end
  end

protected

  def set_data_object
    @data_object ||= DataObject.find(params[:id])
  end

  def get_attribution
    @data_object['attributions'] = @data_object.attributions
    @data_object['media_type'] = @data_object.data_type.label
    current_user.log_activity(:showed_attributions_for_data_object_id, :value => @data_object.id)
  end

  # Every data object has hieararchy associated with it by data partner
  # This method collects these hierarchy paths
  def get_harvested_paths
    @data_object.harvested_ancestries.map do |a|
      { :path => a.map {|he| {:name => Name.find(he.name_id).string, :taxon_concept_id => he.taxon_concept_id } },
        :published => a.last.published? }
    end
  end

  def set_text_data_object_options
    @selectable_toc = TocItem.selectable_toc
    toc = TocItem.find(params[:toc_id])
    @selected_toc = [toc.label, toc.id]
    @languages = Language.find_by_sql("SELECT * FROM languages WHERE iso_639_1!='' ORDER BY label").collect {|c| [c.label.truncate(30), c.id] }
    @licenses = License.valid_for_user_content
  end

  def get_image_source
    case params[:image_size]
    when 'small'
      @data_object.smart_thumb
    when 'medium'
      @data_object.smart_medium_thumb
    when 'original'
      @data_object.original_image
    else 
      @data_object.smart_image
    end
  end
end
