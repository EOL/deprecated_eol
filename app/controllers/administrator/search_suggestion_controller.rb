class Administrator::SearchSuggestionController < AdminController

  access_control :DEFAULT => 'Administrator - Site CMS'
  
  def index
    @page_title = 'Search Suggestions'
    @term_search_string=params[:term_search_string] || ''
    search_string_parameter='%' + @term_search_string + '%' 
    # let us go back to a page where we were
    page = params[:page] || "1"
    @search_suggestions=SearchSuggestion.paginate(:conditions=>['term like ? OR scientific_name like ?',search_string_parameter,search_string_parameter],:order=>'term asc',:page => page)
    @search_suggestions_count=SearchSuggestion.count(:conditions=>['term like ? OR scientific_name like ?',search_string_parameter,search_string_parameter])
  end

  def new
    @page_title = 'New Search Suggestion'
    @search_suggestion = SearchSuggestion.new
    store_location(referred_url) if request.get?    
  end

  def edit
    @page_title = 'Edit Search Suggestion'
    @search_suggestion = SearchSuggestion.find(params[:id])
    store_location(referred_url) if request.get?    
  end

  def create
    @search_suggestion = SearchSuggestion.new(params[:search_suggestion])
    @search_suggestion.scientific_name, @search_suggestion.common_name, @search_suggestion.image_url=get_names_and_image(params[:search_suggestion][:taxon_id])
    if @search_suggestion.save
      flash[:notice] = 'The search suggestion was successfully created.'
      redirect_back_or_default(url_for(:action=>'index'))
    else
      render :action => "new" 
    end
  end

  def update
    @search_suggestion = SearchSuggestion.find(params[:id])
    if @search_suggestion.update_attributes(params[:search_suggestion])
      flash[:notice] = 'The search suggestion was successfully updated.'
      redirect_back_or_default(url_for(:action=>'index'))
    else
      render :action => "edit" 
    end
  end

  def destroy
    (redirect_to referred_url;return) unless request.method == :delete
    @search_suggestion = SearchSuggestion.find(params[:id])
    @search_suggestion.destroy
    redirect_to referred_url 
  end

  # ajax call to update name and image for a given taxon_id
  def update_names_and_image
    scientific_name, common_name, image_url=get_names_and_image(params[:taxon_id])
    render :update do |page|
      page << "$('search_suggestion_scientific_name').value = '#{scientific_name}';"
      page << "$('search_suggestion_common_name').value = '#{common_name}';"
      page << "$('search_suggestion_image_url').value = '#{image_url}';"
    end
  end
  
  private 
  
  def get_names_and_image(taxon_concept_id)
    scientific_name=''
    common_name=''
    image_url=''
    unless taxon_concept_id.blank?
      taxon_concept=TaxonConcept.find_by_id(taxon_concept_id)
      unless taxon_concept.nil?
        scientific_name=taxon_concept.name(:expert)
        common_name=taxon_concept.name
        images=taxon_concept.images
        image_url=DataObject.image_cache_path(images[0].object_cache_url,:medium) unless (images.nil? || images[0].nil?)
      end
    end
    return scientific_name,common_name,image_url
  end

end
