class NavigationController < ApplicationController

  # caches_page :flash_tree_view

  def show_tree_view
    # set the users default hierarchy if they haven't done so already
    current_user.default_hierarchy_id = Hierarchy.default.id if current_user.default_hierarchy_id.nil? || !Hierarchy.exists?(current_user.default_hierarchy_id)
    @session_hierarchy = Hierarchy.find(current_user.default_hierarchy_id)
    @session_secondary_hierarchy = current_user.secondary_hierarchy_id.nil? ? nil : Hierarchy.find(current_user.secondary_hierarchy_id)
    
    
    load_taxon_for_tree_view
    render :layout => false, :partial => 'tree_view', :locals => { :current_user => current_user }
  end
  
  def show_tree_view_for_selection
    load_taxon_for_tree_view
    render :layout => false, :partial => 'tree_view_for_selection', :locals => { :current_user => current_user }
  end
  
  # Flash requires an additional product (flash remoting mx components) to do remote web service requests so we just
  # want to pass through the remote response as if it were local
  # Accessed via /flashxml/:taxon_concept_id.xml
  def flash_tree_view
    
    id = params[:id] rescue 0
    
    if id.to_i == 0
      raw_xml = "";
    else
      @entry = HierarchyEntry.find(id)
      #@entry.current_user = current_user
      #TODO - something with params like this: raw_xml = @taxon_concept.entry(params[:classifcation_id]).classification(:raw => true, :kingdoms=>true)
      raw_xml = @entry.classification(:raw => true, :kingdoms=>true)
      raw_xml.gsub!('&lt;i&gt;','') if raw_xml.nil? == false
      raw_xml.gsub!('&lt;/i&gt;','') if raw_xml.nil? == false
    end
    
    respond_to do |format|
      format.xml { render :xml => raw_xml }
    end

  end

  # AJAX call to set default taxonomic browser in session and save to profile
  def set_default_taxonomic_browser
    
        browser=params[:browser] || $DEFAULT_TAXONOMIC_BROWSER
        current_user.default_taxonomic_browser=browser
        current_user.save if logged_in?
        render :nothing=>true
        
  end
  
  protected
  
  def load_taxon_for_tree_view
    @taxon_concept = TaxonConcept.find(params[:id].to_i, :include => [:names])
    @taxon_concept.current_user = current_user
  end
  
end
