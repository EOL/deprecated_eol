class FeedsController < ApplicationController
  def all
    feed = Atom::Feed.new do |f|
      f.title = "Example Feed"
    end
    render :text => feed.to_xml
  end

  def images
    feed = Atom::Feed.new do |f|
      f.updated = Time.now #TODO: not sure if this is right
#      f.authors << Atom::Person.new(:name => 'John Doe')
#      f.id = "urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6"
      if((taxon_concept_id = params[:page]).nil?)
        f.links << Atom::Link.new(:href => root_url)
        f.title = 'Latest Images'
        images = DataObject.find_by_sql("select * from #{DataObject.full_table_name} where data_type_id=#{DataType.image_type_ids[0]} AND published=1 order by created_at DESC limit 100") #TODO: add additional conditions for species selected
      else
        begin
          taxon_concept = TaxonConcept.find(taxon_concept_id)
        rescue
          render_404
          return false
        end
        f.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id))
        f.title = "Latest Images for #{taxon_concept.names[0].string}" #TODO: select more appropriate name?
        images = DataObject.find_by_sql("SELECT do.* FROM #{HierarchyEntry.full_table_name} he_parent JOIN #{HierarchyEntry.full_table_name} he_children ON (he_children.lft BETWEEN he_parent.lft AND he_parent.rgt) JOIN #{Taxon.full_table_name} t ON (he_children.id=t.hierarchy_entry_id) JOIN #{DataObjectsTaxon.full_table_name} dot ON (t.id=dot.taxon_id) JOIN #{DataObject.full_table_name} do ON (dot.data_object_id=do.id) WHERE he_parent.taxon_concept_id=#{taxon_concept_id} AND do.published=1 AND do.data_type_id=#{DataType.image_type_ids[0]} order by do.created_at DESC limit 100;")
      end
      
      images.each do |image|
        f.entries << Atom::Entry.new do |e|
          tc = image.taxon_concepts[0] #TODO: select lowest species in the hierarchy
          e.title = "New image for #{tc.names[0].string}" #TODO: select most "fitting" name?
          e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :image_id => image.id))
#          e.id = "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a"
          e.updated = image.created_at
          e.content = Atom::Content::Html.new("<a href='#{url_for(:controller => :taxa, :action => :show, :id => tc.id, :image_id => image.id)}'><img src='#{image.smart_image}'/></a>")
#          e.summary = ""
        end
      end
    end
    render :text => feed.to_xml
  end

  def text
    feed = Atom::Feed.new do |f|
      f.updated = Time.now #TODO: not sure if this is right
#      f.authors << Atom::Person.new(:name => 'John Doe')
#      f.id = "urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6"
      if((taxon_concept_id = params[:page]).nil?)
        f.links << Atom::Link.new(:href => root_url)
        f.title = 'Latest Text'
        text_entries = DataObject.find_by_sql("select * from #{DataObject.full_table_name} where data_type_id=#{DataType.text_type_ids[0]} AND published=1 order by created_at DESC limit 100") #TODO: add additional conditions for species selected
      else
        begin
          taxon_concept = TaxonConcept.find(taxon_concept_id)
        rescue
          render_404
          return false
        end
        f.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => taxon_concept.id))
        f.title = "Latest Text for #{taxon_concept.names[0].string}" #TODO: select more appropriate name?
        text_entries = DataObject.find_by_sql("SELECT do.* FROM #{HierarchyEntry.full_table_name} he_parent JOIN #{HierarchyEntry.full_table_name} he_children ON (he_children.lft BETWEEN he_parent.lft AND he_parent.rgt) JOIN #{Taxon.full_table_name} t ON (he_children.id=t.hierarchy_entry_id) JOIN #{DataObjectsTaxon.full_table_name} dot ON (t.id=dot.taxon_id) JOIN #{DataObject.full_table_name} do ON (dot.data_object_id=do.id) WHERE he_parent.taxon_concept_id=#{taxon_concept_id} AND do.published=1 AND do.data_type_id=#{DataType.text_type_ids[0]} order by do.created_at DESC limit 100;")
      end

      text_entries.each do |text|
        f.entries << Atom::Entry.new do |e|
          tc = text.taxon_concepts[0] #TODO: select the lowest species in the hierarchy
          e.title = "New Text for #{tc.names[0].string}" #TODO: select most "fitting" name?
          e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :text_id => text.id))
#          e.id = "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a"
          e.updated = text.created_at
          e.content = Atom::Content::Html.new("<b>#{text.object_title}</b><br/>#{text.description}")
#          e.summary = "<img src='#{image.smart_image}'/><br/>Image for #{tc.names[0].string}"
        end
      end
    end
    render :text => feed.to_xml
  end

  def comments
    feed = Atom::Feed.new do |f|
      f.title = 'Latest comments' #TODO: add which species in the tree this feed is for
      f.links << Atom::Link.new(:href => "http://eol.org/") #TODO: link to the species for the page
      f.updated = Time.now #TODO: not sure if this is right
#      f.authors << Atom::Person.new(:name => 'John Doe')
#      f.id = "urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6"
      comments = Comment.find_by_sql("select * from #{Comment.full_table_name} order by created_at DESC limit 100") #TODO: add additional conditions for species selected
      comments.each do |comment|
        f.entries << Atom::Entry.new do |e|
          if comment.parent_type == 'TaxonConcept'
            tc = TaxonConcept.find(comment.parent.id)
            e.title = "New comment for #{tc.names[0].string}" #TODO: select the lowest species in the hierarchy, select most "fitting" name?
            e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :comment_id => comment.id))
          elsif comment.parent_type == 'DataObject'
            tc = TaxonConcept.find(comment.parent.taxon_concepts[0].id)
            if comment.parent.data_type_id == DataType.image_type_ids[0]
              e.title = "New comment on image for #{tc.names[0].string}" #TODO: select the lowest species in the hierarchy, select most "fitting" name?
              e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :image_comment_id => comment.id))
            elsif comment.parent.data_type_id == DataType.text_type_ids[0]
              e.title = "New comment on text for #{tc.names[0].string}" #TODO: select the lowest species in the hierarchy, select most "fitting" name?
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
    render :text => feed.to_xml
  end
end