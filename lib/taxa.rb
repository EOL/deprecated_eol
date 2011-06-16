module Taxa
  ########################################################################################################
  # Notice: those methods are taken from other controllers to be shared with the mobile app.             #
  # TO-DO by the maintainers: remove those methods from original controllers and include the module      #
  ########################################################################################################
  
  # from taxa_controller
  # If you want this to redirect to search, call (do_the_search && return if this_request_is_really_a_search) before this.
  def find_taxon_concept
    tc_id = params[:id].to_i
    tc_id = params[:taxon_id].to_i if tc_id == 0
    tc_id = params[:taxon_concept_id].to_i if tc_id == 0
    redirect_to_missing_page_on_error do
      TaxonConcept.find(tc_id)
    end
  end
  
  
  private
  
  # from taxa_controller
  def instantiate_taxon_concept
    @taxon_concept = find_taxon_concept
  end
  
  # from taxa_controlle
  def redirect_if_invalid
    redirect_to_missing_page_on_error do
      raise "TaxonConcept not found" if @taxon_concept.nil?
      raise "Page not accessible" unless accessible_page?(@taxon_concept)
    end
  end
  
  # from taxa_controller
  def update_user_content_level
    current_user.content_level = params[:content_level] if ['1','2','3','4'].include?(params[:content_level])
  end
  
  # from taxa_controller
  # to rewrite for mobile
  def redirect_to_missing_page_on_error(&block)
    begin
      yield
    rescue => e
      @message = e.message
      render(:layout => 'main', :template => "content/missing", :status => 404)
      return false
    end
  end
  
  # from taxa/overviews_controller
  def redirect_if_superceded
    redirect_to taxon_overview_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end
  
    
end