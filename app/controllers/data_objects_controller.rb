class DataObjectsController < ApplicationController

  layout proc { |c| c.request.xhr? ? false : "main" }

  before_filter :set_data_object, :except => [:index, :new, :create, :preview]
  before_filter :curator_only, :only => [:rate, :curate]

  def create
    data_object = DataObject.create_user_text(params, current_user)
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @curator = current_user.can_curate?(@taxon_concept)
    @taxon_concept.current_user = current_user
    @category_id = data_object.toc_items[0].id
    alter_current_user do |user|
      user.vetted=false
    end
    @new_text = render_to_string(:partial=>'/taxa/text_data_object', :locals => {:content_item => data_object, :comments_style => '', :category => data_object.toc_items[0].label})
  end

  def preview
    data_object = DataObject.preview_user_text(params, current_user)
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @taxon_concept.current_user = current_user
    @curator = false
    @preview = true
    @data_object_id = params[:id]
    @hide = true
    @preview_text = render_to_string(:partial=>'/taxa/text_data_object', :locals => {:content_item => data_object, :comments_style => '', :category => data_object.toc_items[0].label})
  end

  def get
    @curator = current_user.can_curate?(TaxonConcept.find(params[:taxon_concept_id]))
    @hide = true
    @category_id = @data_object.toc_items[0].id
    @text = render_to_string(:partial=>'/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
  end

  def update
    @old_data_object_id = params[:id]
    @data_object = DataObject.update_user_text(params, current_user)
    @curator = current_user.can_curate?(TaxonConcept.find(params[:taxon_concept_id]))
    @hide = true
    @category_id = @data_object.toc_items[0].id
    alter_current_user do |user|
      user.vetted=false
    end
    @text = render_to_string(:partial=>'/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
  end

  def edit
    set_text_data_object_options
    @selected_language = [@data_object.language.label,@data_object.language.id]
    render :partial => 'edit_text'
  end

  def new
    if(logged_in?)
      @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
      if(params[:toc_id]!='none')
        set_text_data_object_options
        @data_object = DataObject.new
        @selected_language = [current_user.language.label,current_user.language.id]
        render :partial => 'new_text'
      else
        @taxon_concept.current_user = current_user
        toc_item = @taxon_concept.tocitem_for_new_text
        params[:toc_id] = toc_item.id
        set_text_data_object_options
        @data_object = DataObject.new
        @selected_language = [current_user.language.label,current_user.language.id]
        render :partial => 'new_text'
      end
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
  def index
    @taxon_concept = TaxonConcept.find params[:taxon_concept_id] if params[:taxon_concept_id]
    per_page = params[:per_page].to_i
    per_page = 10 if per_page < 1
    per_page = 50 if per_page > 50
    page     = params[:page].to_i
    page     = 1 if page < 1
    if @taxon_concept
      case request.path
      when /images/
        respond_to do |format|
          format.xml do
            xml = Rails.cache.fetch("taxon.#{params[:taxon_concept_id].to_i}/images/#{page}.#{per_page}/xml", :expires_in => 4.hours) do
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
      when /videos/
        respond_to do |format|
          format.xml do
            xml = Rails.cache.fetch("taxon.#{@taxon_concept.id}/videos/#{page}.#{per_page}/xml", :expires_in => 4.hours) do
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
      else
        render :text => "Don't know how to render #{ params.inspect }"
      end
    end
  end

  make_resourceful do
    actions :show

    before :show do
      set_data_object
    end
  end

  # GET /data_objects/1/attribution
  def attribution
    render :partial => 'attribution', :locals => { :data_object => current_object }, :layout => @layout
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
    @data_object.curate! params[:vetted_id], params[:visibility_id], current_user, params[:untrust_reasons], params[:comment]

    expire_data_object(@data_object.id)
    
    respond_to do |format|
      format.html {redirect_to request.referer ? :back : '/'}
      format.js {render :action => 'curate.rjs'}
    end
  end

protected

  def set_data_object
    @data_object ||= current_object
  end

  def set_text_data_object_options
    @selectable_toc = TocItem.find(:all, :order => 'id').select{|c| c.allow_user_text?}.collect {|c| [c.label, c.id] }
    toc = TocItem.find(params[:toc_id])
    @selected_toc = [toc.label, toc.id]
    @languages = Language.find_active.collect {|c| [c.label, c.id] }
    @licenses = License.valid_for_user_content
  end
end
