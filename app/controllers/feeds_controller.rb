class FeedsController < ApplicationController
  before_filter :set_session_hierarchy_variable

  caches_page :all, :images, :text, :comments, :expires_in => 2.minutes

    def get_attribution_for_feed(dato_ids)
      unless dato_ids.empty?
        attribution_for_feed = SpeciesSchemaModel.connection.execute("
          SELECT a.id AS agent_id, ar.label AS agent_role, 
                 a.full_name AS agent_name, a.homepage, ado.data_object_id
          FROM #{AgentsDataObject.full_table_name} ado 
            JOIN #{Agent.full_table_name} a ON (ado.agent_id=a.id) 
            LEFT JOIN #{AgentRole.full_table_name} ar ON (ado.agent_role_id = ar.id) 
          WHERE ado.data_object_id IN (#{dato_ids})
        ").all_hashes

        @dato_attribution = {}

        unless attribution_for_feed.empty?
          attribution_for_feed.each do |i|
            @dato_attribution[i['data_object_id'].to_i] ? @dato_attribution[i['data_object_id'].to_i] << i : @dato_attribution[i['data_object_id'].to_i] = [i]
          end
        end
      end
    end

    def get_supplier(dato_ids)
      unless dato_ids.empty?
        suppliers = SpeciesSchemaModel.connection.execute("
          SELECT a.id, dohe.data_object_id 
           FROM #{DataObjectsHarvestEvent.full_table_name} dohe 
           JOIN #{HarvestEvent.full_table_name} he ON (dohe.harvest_event_id=he.id) 
           JOIN #{AgentsResource.full_table_name} ar ON (he.resource_id=ar.resource_id) 
           JOIN #{ResourceAgentRole.full_table_name} rar ON (ar.resource_agent_role_id = rar.id)
           JOIN #{Agent.full_table_name} a ON (ar.agent_id=a.id) 
           WHERE dohe.data_object_id IN (#{dato_ids})
           AND rar.label = 'Data Supplier'
        ").all_hashes         

      # puts "URA 1 " * 50
      # puts "suppliers = "+suppliers.inspect.to_s
      
      agents_hash = []
      suppliers.each do |m|
        h = {}
        h["data_object_id"] = m['data_object_id']
        h["agent"] = Agent.find([m["id"]])
        agents_hash << h
      end

      # puts "URA 2 " * 50
      # puts "agents_hash = "+agents_hash.inspect.to_s

      dato_agent_hash = {}
      agents_hash.each do |i|

        dato_agent_hash[i['data_object_id'].to_i] ? dato_agent_hash[i['data_object_id'].to_i] << i : dato_agent_hash[i['data_object_id'].to_i] = i

      end
      # puts "URA^&*" * 50
      # puts "dato_agent_hash = " + dato_agent_hash.inspect.to_s
# h = {161=>{"id"=>"2", "data_object_id"=>"161"}, 142=>{"id"=>"2", "data_object_id"=>"142"}, 47=>{"id"=>"2", "data_object_id"=>"47"}, 66=>{"id"=>"2", "data_object_id"=>"66"}, 152=>{"id"=>"2", "data_object_id"=>"152"}, 114=>{"id"=>"2", "data_object_id"=>"114"}, 19=>{"id"=>"2", "data_object_id"=>"19"}, 57=>{"id"=>"2", "data_object_id"=>"57"}, 162=>{"id"=>"2", "data_object_id"=>"162"}, 143=>{"id"=>"2", "data_object_id"=>"143"}, 48=>{"id"=>"2", "data_object_id"=>"48"}, 67=>{"id"=>"2", "data_object_id"=>"67"}, 
      @dato_agent_hash = dato_agent_hash
      # puts "URA===" * 50
      # puts "@dato_agent_hash = " + @dato_agent_hash.inspect.to_s
      
      end
    end

  def all
    #render :nothing => true
    #return nil
    feed = Atom::Feed.new do |f|
      f.updated = Time.now
      if((taxon_concept_id = params[:id]).nil?)
        f.links << Atom::Link.new(:href => root_url)
        f.title = 'Latest Images, Text and Comments'
        all = DataObject.feed_images_and_text + Comment.feed
      else
        begin
          taxon_concept = TaxonConcept.find(taxon_concept_id)
        rescue
          render_404
          return false
        end
        f.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id))
        f.title = "Latest Images, Text and Comments for #{taxon_concept.quick_scientific_name(:normal, @session_hierarchy)}"
        all_dato    = DataObject.feed_images_and_text(taxon_concept.id)
        all_comment = Comment.feed(taxon_concept_id)
        all = all_dato + all_comment
      end

      all.sort! {|x,y| y.created_at <=> x.created_at}
      all = all[0..100]

      dato_ids = all_dato.map {|x| x.id}.join(',')
      get_attribution_for_feed(dato_ids)
      get_supplier(dato_ids)
      
      all.each do |entry|
        f.entries << create_entry(entry)
      end
    end
    render :text => feed.to_xml
  end
  
  def images
    # puts "&" * 40
    # puts "URA start images feeds"
    feed = Atom::Feed.new do |f|
      f.updated = Time.now
#      f.authors << Atom::Person.new(:name => 'John Doe')
#      f.id = "urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6"
      if((taxon_concept_id = params[:id]).nil?)
        f.links << Atom::Link.new(:href => root_url)
        f.title = 'Latest Images'
        images = DataObject.feed_images
      else
        begin
          taxon_concept = TaxonConcept.find(taxon_concept_id)
        rescue
          render_404
          return false
        end
        f.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id))
        f.title = "Latest Images for #{taxon_concept.quick_scientific_name(:normal, @session_hierarchy)}"
        images = DataObject.feed_images(taxon_concept.id)
        
      end
      dato_ids = images.map {|x| x.id}.join(',')
      get_attribution_for_feed(dato_ids)
      get_supplier(dato_ids)
      
      images.each do |image|
        f.entries << image_entry(image)
      end
    end
    render :text => feed.to_xml
  end

  def text
    feed = Atom::Feed.new do |f|
      f.updated = Time.now
#      f.authors << Atom::Person.new(:name => 'John Doe')
#      f.id = "urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6"
      if((taxon_concept_id = params[:id]).nil?)
        f.links << Atom::Link.new(:href => root_url)
        f.title = 'Latest Text'
        text_entries = DataObject.feed_text
      else
        begin
          taxon_concept = TaxonConcept.find(taxon_concept_id)
        rescue
          render_404
          return false
        end
        f.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id))
        f.title = "Latest Text for #{taxon_concept.quick_scientific_name(:normal, @session_hierarchy)}"
        text_entries = DataObject.feed_text(taxon_concept.id)
      end

      dato_ids = text_entries.map {|x| x.id}.join(',')
      get_attribution_for_feed(dato_ids)
      get_supplier(dato_ids)
      
      text_entries.each do |text|
        f.entries << text_entry(text)
      end
    end
    render :text => feed.to_xml
  end

  def comments
    feed = Atom::Feed.new do |f|
      f.updated = Time.now
#      f.authors << Atom::Person.new(:name => 'John Doe')
#      f.id = "urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6"

      if((taxon_concept_id = params[:id]).nil?)
        f.links << Atom::Link.new(:href => root_url)
        f.title = 'Latest Comments'
        comments = Comment.feed
      else
        begin
          taxon_concept = TaxonConcept.find(taxon_concept_id)
        rescue
          render_404
          return false
        end
        f.title = "Latest Comments for #{taxon_concept.quick_scientific_name(:normal, @session_hierarchy)}"
        f.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id))

        comments = Comment.feed(taxon_concept.id)
      end

      comments.each do |comment|
        f.entries << comment_entry(comment)
      end
    end
    render :text => feed.to_xml
  end

  protected
  def create_entry(entry)
    
    if entry.class == DataObject && entry.data_type_id == DataType.image_type_ids[0]
      image_entry(entry)
    elsif entry.class == DataObject && entry.data_type_id == DataType.text_type_ids[0]
      text_entry(entry)
    elsif entry.class == Comment
      comment_entry(entry)
    end
  end
  
  def text_link(text, url, params = {:show_link_icon => true})
    view_helper_methods.external_link_to(text, url, params) 
  end

  def image_link(image, url, params = {:show_link_icon => false})
    view_helper_methods.external_link_to(view_helper_methods.image_tag(image), url, params) 
  end

  def feeds_attributions(dato)
    content = ""
    dato_id = dato.id.to_i
    
    source_url_text = "View original data object"
    
    # puts "!=" * 50
    # puts "@dato_agent_hash = "+@dato_agent_hash.inspect.to_s
    # puts "!=" * 50
    # puts "@dato_agent_hash[dato_id] = " 
    # pp @dato_agent_hash[dato_id].inspect.to_s

    
    unless @dato_agent_hash.empty?
      agent = @dato_agent_hash[dato_id]["agent"][0] 
      logo_size = (agent == Agent.catalogue_of_life ? "large" : "small")
      content += "<br/><b>Supplier</b>:
                  #{text_link(agent.full_name, 
                              agent.homepage)} 
                  #{view_helper_methods.agent_logo(agent, logo_size)}
                 "       
     end

     @dato_attribution[dato_id].each do |d_attr|
       content += "<br/><b>#{d_attr['agent_role']}</b>: #{text_link(d_attr['agent_name'], d_attr['homepage'])}"
     end     
     content += "<br/><b>Copyright</b>: 
                 #{text_link(dato.license[:description], 
                             dato.license[:source_url])}
                 #{image_link(dato.license[:logo_url], 
                              dato.license[:source_url])}
                "                 
    content += "<br/><b>Location</b>: #{dato.location}" unless 
    dato.location == ""
    content += "<br/><b>Source URL</b>: #{text_link(source_url_text, dato.source_url)}"
    content += "<br/><b>Citation</b>: #{dato.bibliographic_citation}" unless 
    dato.bibliographic_citation == ""  
    return content
  end

  def image_entry(image)
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

  def text_entry(text)
    Atom::Entry.new do |e|
      tc = text.taxon_concepts[0]
      if text.created_by_user?
        e.title = "New User Submitted Text for #{tc.quick_scientific_name(:normal,@session_hierarchy)} created by #{text.user.username}"
      else
        e.title = "New Text for #{tc.quick_scientific_name(:normal,@session_hierarchy)}"
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

  def comment_entry(comment)
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
          e.title = "New comment on text for #{tc.quick_scientific_name(:normal,@session_hierarchy)} by #{comment.user.username}"
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
end
