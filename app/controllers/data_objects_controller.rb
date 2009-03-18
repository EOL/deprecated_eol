class DataObjectsController < ApplicationController

  layout proc { |c| c.request.xhr? ? false : "main" }

  before_filter :set_data_object, :except => :index

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
    if current_user.can_curate?(@data_object)
      @data_object.curate! params[:curator_activity_id], current_user

      @data_object.taxa.each do |taxon|
        expire_taxon(taxon.id)
      end

      #expire_taxon(@data_object)
    end
    
    respond_to do |format|
      format.html {redirect_to request.referer ? :back : '/'}
      format.js {render :action => 'curate.rjs'}
    end
  end

protected

  def set_data_object
    @data_object ||= current_object
  end

end
