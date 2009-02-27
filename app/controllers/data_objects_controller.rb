class DataObjectsController < ApplicationController

  layout proc { |c| c.request.xhr? ? false : "main" }

  before_filter :set_data_object, :except => :new

  # example urls this handles ...
  #
  #   /v1/species/5/images
  #   /v1/species/5/videos
  #   /v1/species/5/text          # not yet implemented
  #   /v1/species/5/data_objects  # not yet implemented
  #
  def index
    @species = TaxonConcept.find params[:species_id] if params[:species_id]
    if @species
      case request.path
      when /images/
        respond_to do |format|
          format.xml  { render :xml  => @species.images.to_xml(serialization_options)  }
          format.json { render :json => @species.images.to_json(serialization_options) }
        end
      when /videos/
        respond_to do |format|
          format.xml  { render :xml  => @species.videos.to_xml(serialization_options)  }
          format.json { render :json => @species.videos.to_json(serialization_options) }
        end
      else
        render :text => "Don't know how to render #{ params.inspect }"
      end
    end
  end

  make_resourceful do
    actions :show

    before :show do
      @data_object ||= current_object # Because we use a partial that assumes this is defined 
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

  def new
    @data_object = DataObject.new

   #to link with taxa
    @data_objects_taxa = DataObjectsTaxon.new
    @data_objects_taxa.taxon_id = params[:taxon_id]

   #to get Taxon.name
    @current_taxa = Taxon.find(params[:taxon_id])
    @current_taxa_name = Name.find(@current_taxa.name_id)

   #to link with toc
    @data_objects_toc_category = DataObjectsTableOfContent.new
    @data_objects_toc_category.toc_id = params[:toc_id]

   #to get TOC.category
    @current_toc_category = TocItem.find(params[:toc_id])
  end

  # PUT /data_objects/1/curate
  def curate
    @data_object.curate!(params[:curator_activity_id]) if current_user.can_curate?(@data_object)
    
    respond_to do |format|
      format.html {redirect_to request.referer ? :back : '/'}
      format.js {render :action => 'curate.rjs'}
    end
  end

protected

  def set_data_object
    @data_object ||= ( DataObject.find( params[:id] ) if params[:id] )
  end

  def serialization_options
    {
      :methods => [ :thumb_or_object ]
    }
  end  

end
