class FeedsController < ApplicationController

  #/feeds/images/25 or texts or comments or all

  before_filter :set_session_hierarchy_variable

  caches_page :all, :images, :texts, :comments, :expires_in => 2.minutes

  def all
    #render :nothing => true
    #return nil
    feed = Atom::Feed.new do |f|
      f.updated = Time.now
      if((taxon_concept_id = params[:id]).nil?)
        f.links << Atom::Link.new(:href => root_url)
        f.title = 'Latest Images, Text and Comments'
        all = DataObject.feed_images_and_texts + Comment.feed
      else
        begin
          taxon_concept = TaxonConcept.find(taxon_concept_id)
        rescue
          render_404
          return false
        end
        f.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id))
        f.title = "Latest Images, Text and Comments for #{taxon_concept.quick_scientific_name(:normal, @session_hierarchy)}"
        all_dato    = DataObject.feed_images_and_texts(taxon_concept.id)
        all_comment = Comment.feed_comments(taxon_concept_id)
        all = all_dato + all_comment
      end

      all.sort! {|x,y| y.created_at <=> x.created_at}
      all = all[0..100]

      set_all_attributions(all_dato)
      
      all.each do |entry|
        type = ""
        if entry.class == DataObject
          type = DataType.find(entry.data_type_id).label.downcase.pluralize
        elsif entry.class == Comment
          type = "comments"
        end
        f.entries << self.send("#{type}_entry", entry)
      end
    end
    render :text => feed.to_xml
  end
  
  def images
    make_feed('images', DataObject)
  end

  def texts
    make_feed('texts', DataObject)
  end
  
  def comments
    make_feed('comments', Comment)
  end

  private
  
  def make_feed(type, object_class)
    feed = Atom::Feed.new do |f|
      f.updated = Time.now
#      f.authors << Atom::Person.new(:name => 'John Doe')
#      f.id = "urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6"
      if((taxon_concept_id = params[:id]).nil?)
        f.links << Atom::Link.new(:href => root_url)
        f.title = "Latest #{type.capitalize}"
        data = object_class.send("feed_#{type}".to_sym)
      else
        begin
          taxon_concept = TaxonConcept.find(taxon_concept_id)
        rescue
          render_404
          return false
        end
        f.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id))
        f.title = "Latest #{type.capitalize} for #{taxon_concept.quick_scientific_name(:normal, @session_hierarchy)}"
        data = object_class.send("feed_#{type}".to_sym, taxon_concept.id)
      end
      
      set_all_attributions(data)
      
      data.each do |datum|
        f.entries << self.send("#{type}_entry", datum)
      end
    end
    render :text => feed.to_xml
  end

  def images_entry(image)
    Atom::Entry.new do |e|
      tc = image.taxon_concepts[0]
      e.title = "New image for #{tc.quick_scientific_name(:normal,@session_hierarchy)}"
      e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :image_id => image.id))
#      e.id = "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a"
      e.updated = image.created_at

      content   = "<a href='#{url_for(:controller => :taxa, :action => :show, :id => tc.id, :image_id => image.id)}'><img src='#{image.smart_image}'/></a><br/>"
      
      content  += feeds_attributions(image)
      
      e.content = Atom::Content::Html.new(content)
#      e.summary = ""
    end
  end

  def texts_entry(text)
    Atom::Entry.new do |e|
      tc = text.taxon_concepts[0]
      if text.created_by_user?
        e.title = "New User Submitted Text for #{tc.quick_scientific_name(:normal, @session_hierarchy)} created by #{text.user.username}"
      else
        e.title = "New Text for #{tc.quick_scientific_name(:normal, @session_hierarchy)}"
      end
      e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :text_id => text.id))
#      e.id = "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a"
      e.updated = text.created_at

      content   = "<b>#{text.object_title}</b><br/>#{text.description}<br/>"
      content  += feeds_attributions(text)

      e.content = Atom::Content::Html.new(content)
#      e.summary = "<img src='#{image.smart_image}'/><br/>Image for #{tc.names[0].string}"
    end
  end

  def comments_entry(comment)
    Atom::Entry.new do |e|
      if comment.parent_type == 'TaxonConcept'
        tc = TaxonConcept.find(comment.parent.id)
        e.title = "New comment for #{tc.quick_scientific_name(:normal, @session_hierarchy)} by #{comment.user.username}"
        e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :comment_id => comment.id))
      elsif comment.parent_type == 'DataObject'
        tc = TaxonConcept.find(comment.parent.taxon_concepts[0].id)
        if comment.parent.data_type_id == DataType.image_type_ids[0]
          e.title = "New comment on image for #{tc.quick_scientific_name(:normal, @session_hierarchy)} by #{comment.user.username}"
          e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :image_comment_id => comment.id))
        elsif comment.parent.data_type_id == DataType.text_type_ids[0]
          e.title = "New comment on text for #{tc.quick_scientific_name(:normal, @session_hierarchy)} by #{comment.user.username}"
          e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :text_comment_id => comment.id))
        else
          raise "Unknown comment data object type #{comment.parent.data_type}"
        end
      else
        raise "Unknown comment parent type #{comment.parent_type}"
      end
      e.content = Atom::Content::Html.new(comment.body)
      e.updated = comment.created_at
    end
  end

  
  def set_all_attributions(dato)
    dato_ids = dato.map {|x| x.id}.join(',')
    @dato_attribution = set_attribution_for_feed(dato_ids)
    @dato_copyright   = set_license_attr(dato_ids)
    @dato_agent       = set_supplier(dato_ids)
  end
  
  def set_attribution_for_feed(dato_ids)
    unless dato_ids.empty?
      attribution_for_feed = SpeciesSchemaModel.connection.execute("
        SELECT a.id AS agent_id, ar.label AS agent_role, 
               a.full_name AS agent_name, a.homepage, ado.data_object_id
        FROM #{AgentsDataObject.full_table_name} ado 
          JOIN #{Agent.full_table_name} a ON (ado.agent_id=a.id) 
          LEFT JOIN #{AgentRole.full_table_name} ar ON (ado.agent_role_id = ar.id) 
        WHERE ado.data_object_id IN (#{dato_ids})
      ").all_hashes
    end
    return dato_id_hash(attribution_for_feed) || ""
  end

  def set_license_attr(dato_ids)
    unless dato_ids.empty?
      license_attrs = SpeciesSchemaModel.connection.execute("
      SELECT l.description, l.source_url, l.logo_url, dato.rights_statement, dato.id AS data_object_id 
      FROM #{License.full_table_name} l
      JOIN #{DataObject.full_table_name} dato ON (dato.license_id = l.id)
      WHERE dato.id IN (#{dato_ids});").all_hashes
    end
    return dato_id_hash(license_attrs) || ""
  end

  def set_supplier(dato_ids)
  unless dato_ids.empty?
      suppliers = SpeciesSchemaModel.connection.execute("
        SELECT a.id, a.logo_cache_url, a.homepage, a.full_name, dohe.data_object_id 
         FROM #{DataObjectsHarvestEvent.full_table_name} dohe 
         JOIN #{HarvestEvent.full_table_name} he ON (dohe.harvest_event_id=he.id) 
         JOIN #{AgentsResource.full_table_name} ar ON (he.resource_id=ar.resource_id) 
         JOIN #{ResourceAgentRole.full_table_name} rar ON (ar.resource_agent_role_id = rar.id)
         JOIN #{Agent.full_table_name} a ON (ar.agent_id=a.id) 
         WHERE dohe.data_object_id IN (#{dato_ids})
         AND rar.label = 'Data Supplier'
      ").all_hashes         
    
#      agents_hash = []
#      suppliers.each do |m|
#        h = {}
#        h["data_object_id"] = m['data_object_id']
#        h["agent"] = Agent.find([m["id"]])
#        agents_hash << h
#      end
    end
    return dato_id_hash(suppliers) || ""
    
  end
  
  def dato_id_hash(data)
    info_hash = {}

    if data
      data.each do |i|
        info_hash[i['data_object_id'].to_i] ? info_hash[i['data_object_id'].to_i] << i : info_hash[i['data_object_id'].to_i] = [i]
      end
    end   
    return info_hash   
  end

  
  def text_link(text, url, params = {:show_link_icon => true})
    view_helper_methods.external_link_to(text, url, params) 
  end

  def image_link(image, url, params = {:show_link_icon => false})
    view_helper_methods.external_link_to(view_helper_methods.image_tag(image), url, params) 
  end
  
  def dato_roles(dato_id)
    @roles = @author = ""
    if @dato_attribution[dato_id]
      @dato_attribution[dato_id].each do |d_attr|
        if d_attr['agent_role'] == "Author"
          @author += "<br/><b>#{d_attr['agent_role']}</b>: #{text_link(d_attr['agent_name'], d_attr['homepage'])}"
        else
          @roles += "<br/><b>#{d_attr['agent_role']}</b>: #{text_link(d_attr['agent_name'], d_attr['homepage'])}"
        end
      end     
    end
  end

  def feeds_attributions(dato)
    content = ""
    dato_id = dato.id.to_i
    dato_roles(dato_id) # cache strings for author and other roles separately
    dato_copyright      = @dato_copyright[dato_id][0]                             
    rights_statement    = dato_copyright["rights_statement"]
    license_description = dato_copyright["description"]
    copyright_string    = (rights_statement.blank? ? license_description : "#{rights_statement.strip}. #{license_description}")
    source_url_text = "View original data object"
    
    content += @author if @author
    content += "<br/><b>Copyright</b>: 
               #{text_link(copyright_string, 
                           dato_copyright['source_url'])}
               #{image_link(dato_copyright['logo_url'], 
                            dato_copyright['source_url'])}
              " if dato_copyright                
    if @dato_agent[dato_id]
      agent_data = @dato_agent[dato_id][0]
      img_logo = ""
      if agent_data["logo_cache_url"]
        logo_size = (agent_data["full_name"] == Agent.catalogue_of_life.full_name ? "large" : "small")
        img_url = ContentServer.next[0...-1] + $CONTENT_SERVER_AGENT_LOGOS_PATH
        img_url += "#{agent_data["logo_cache_url"]}_#{logo_size}.png"
        img_logo = image_link(img_url, agent_data['homepage'])
      end
      content += "<br/><b>Supplier</b>:
                  #{text_link(agent_data['full_name'], 
                              agent_data['homepage'])} 
                  #{img_logo}
                 "       
    end
    content += @roles if @roles
    content += "<br/><b>Location</b>: #{dato.location}" unless dato.location.blank?
    content += "<br/><b>Source URL</b>: #{text_link(source_url_text, dato.source_url)}"
    content += "<br/><b>Citation</b>: #{dato.bibliographic_citation}" unless dato.bibliographic_citation.blank?
    return content
  end  
end
