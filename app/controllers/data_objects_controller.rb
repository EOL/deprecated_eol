class DataObjectsController < ApplicationController

  layout proc { |c| c.request.xhr? ? false : "main" }

  before_filter :set_data_object, :except => [:index, :new, :create, :preview]
  before_filter :curator_only, :only => [:rate, :curate]

  def create
    data_object = DataObject.create_user_text(params, current_user)
    @curator = current_user.can_curate?(TaxonConcept.find(params[:taxon_concept_id]))
    @new_text = render_to_string(:partial=>'/taxa/text_data_object', :locals => {:content_item => data_object, :comments_style => '', :category => data_object.toc_items[0].label})
  end

  def preview
    data_object = DataObject.preview_user_text(params)
    @curator = false
    @preview = true
    @data_object_id = params[:id]
    @hide = true
    @preview_text = render_to_string(:partial=>'/taxa/text_data_object', :locals => {:content_item => data_object, :comments_style => '', :category => data_object.toc_items[0].label})
  end

  def get
    @taxon_concept_id = @taxon_id = params[:taxon_concept_id]
    @curator = current_user.can_curate?(TaxonConcept.find(@taxon_concept_id))
    @hide = true
    @text = render_to_string(:partial=>'/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
  end

  def update
    @old_data_object_id = params[:id]
    @data_object = DataObject.update_user_text(params, current_user)
    @taxon_concept_id = @taxon_id = params[:taxon_concept_id]
    @curator = current_user.can_curate?(TaxonConcept.find(@taxon_concept_id))
    @hide = true
    @text = render_to_string(:partial=>'/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
  end

  def edit
    set_text_data_object_options
    render :partial => 'edit_text'
  end

  def new
    set_text_data_object_options
    @data_object = DataObject.new
    render :partial => 'new_text'
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
            xml = Rails.cache.fetch("taxon.#{@taxon_id}/videos/#{page}.#{per_page}/xml", :expires_in => 4.hours) do
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
    @data_object.curate! params[:curator_activity_id], current_user

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
    @taxon_concept_id = params[:taxon_concept_id]
    @languages = Language.find(:all).collect {|c| [c.name, c.id] }
    @licenses = License.valid_for_user_content
  end
end
