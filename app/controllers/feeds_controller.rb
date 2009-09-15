class FeedsController < ApplicationController
  before_filter :set_session_hierarchy_variable

  caches_page :all, :images, :text, :comments, :expires_in => 2.minutes

  def all
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
        f.title = "Latest Images, Text and Comments for #{taxon_concept.quick_scientific_name(:normal,@session_hierarchy)}"

        all = DataObject.feed_images_and_text(taxon_concept.id) + Comment.feed(taxon_concept_id)
      end

      all.sort! {|x,y| y.created_at <=> x.created_at}
      all = all[0..100]

      all.each do |entry|
        f.entries << create_entry(entry)
      end
    end
    render :text => feed.to_xml
  end

  def images
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
        f.title = "Latest Images for #{taxon_concept.quick_scientific_name(:normal,@session_hierarchy)}"
        images = DataObject.feed_images(taxon_concept.id)
      end
      
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
        f.title = "Latest Text for #{taxon_concept.quick_scientific_name(:normal,@session_hierarchy)}"
        text_entries = DataObject.feed_text(taxon_concept.id)
      end

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
        f.title = "Latest Comments for #{taxon_concept.quick_scientific_name(:normal,@session_hierarchy)}"
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

  def image_entry(image)
    Atom::Entry.new do |e|
      tc = image.taxon_concepts[0]
      e.title = "New image for #{tc.quick_scientific_name(:normal,@session_hierarchy)}"
      e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :image_id => image.id))
#      e.id = "urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a"
      e.updated = image.created_at

      content = "<a href='#{url_for(:controller => :taxa, :action => :show, :id => tc.id, :image_id => image.id)}'><img src='#{image.smart_image}'/></a><br/>"
      for attribution in image.attributions
        content += "<br/><b>#{attribution.agent_role}: </b> #{view_helper_methods.agent_partial(attribution.agent)} #{view_helper_methods.agent_icons_partial(attribution.agent)}"  
      end

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

      content = "<b>#{text.object_title}</b><br/>#{text.description}<br/>"
      for attribution in text.attributions
        content += "<br/><b>#{attribution.agent_role}: </b> #{view_helper_methods.agent_partial(attribution.agent)} #{view_helper_methods.agent_icons_partial(attribution.agent)}"
      end

      e.content = Atom::Content::Html.new(content)
#      e.summary = "<img src='#{image.smart_image}'/><br/>Image for #{tc.names[0].string}"
    end
  end

  def comment_entry(comment)
    Atom::Entry.new do |e|
      if comment.parent_type == 'TaxonConcept'
        tc = TaxonConcept.find(comment.parent.id)
        e.title = "New comment for #{tc.quick_scientific_name(:normal,@session_hierarchy)} by #{comment.user.username}"
        e.links << Atom::Link.new(:href => url_for(:controller => :taxa, :action => :show, :id => tc.id, :comment_id => comment.id))
      elsif comment.parent_type == 'DataObject'
        tc = TaxonConcept.find(comment.parent.taxon_concepts[0].id)
        if comment.parent.data_type_id == DataType.image_type_ids[0]
          e.title = "New comment on image for #{tc.quick_scientific_name(:normal,@session_hierarchy)} by #{comment.user.username}"
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