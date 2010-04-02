require 'set'
require 'uuid'
require 'erb'

# Represents any kind of object imported from a ContentPartner, eg. an image, article, video, etc.  This is one
# of our primary models, and an awful lot of work occurs here.
class DataObject < SpeciesSchemaModel
  
  include UserActions
  include ModelQueryHelper

  belongs_to :data_type
  belongs_to :language
  belongs_to :license
  belongs_to :mime_type
  belongs_to :visibility
  belongs_to :vetted

  has_many :top_images
  has_many :feed_data_objects
  has_many :top_concept_images
  has_many :languages
  has_many :agents_data_objects, :include => [ :agent, :agent_role ]
  has_many :data_objects_taxa
  has_many :comments, :as => :parent, :attributes => true
  has_many :data_objects_harvest_events
  has_many :harvest_events, :through => :data_objects_harvest_events
  has_many :agents, :through => :agents_data_objects
  has_many :resources, :through => :taxa
  has_many :data_object_tags, :class_name => DataObjectTags.to_s
  has_many :tags, :class_name => DataObjectTag.to_s, :through => :data_object_tags, :source => :data_object_tag
  has_many :data_objects_table_of_contents
  has_many :data_objects_untrust_reasons
  has_many :untrust_reasons, :through => :data_objects_untrust_reasons
  has_many :data_objects_info_items
  has_many :info_items, :through => :data_objects_info_items
  

  has_and_belongs_to_many :taxa
  has_and_belongs_to_many :audiences
  has_and_belongs_to_many :refs
  has_and_belongs_to_many :agents
  has_and_belongs_to_many :toc_items, :join_table => 'data_objects_table_of_contents', :association_foreign_key => 'toc_id'

  attr_accessor :vetted_by # who changed the state of this object? (not persisted on DataObject but required by observer)

  named_scope :visible, lambda { { :conditions => { :visibility_id => Visibility.visible.id } }}
  named_scope :preview, lambda { { :conditions => { :visibility_id => Visibility.preview.id } }}
  
  # for RSS feeds
  def self.for_feeds(type = :all, taxon_concept_id = nil, max_results = 100)
    if type == :text
      data_type_ids = [DataType.text_type_ids[0]]
    elsif type == :images
      data_type_ids = [DataType.image_type_ids[0]]
    else
      data_type_ids = [DataType.image_type_ids[0], DataType.text_type_ids[0]]
    end
    
    if taxon_concept_id.nil?
      lookup_ids = HierarchyEntry.find_all_by_hierarchy_id_and_parent_id(Hierarchy.default.id, 0).collect{|he| he.taxon_concept_id}
    else
      lookup_ids = [taxon_concept_id]
    end

    data_object_ids = SpeciesSchemaModel.connection.execute("
      SELECT do.id, do.created_at
      FROM feed_data_objects fdo
      JOIN #{DataObject.full_table_name} do ON (fdo.data_object_id=do.id)
      WHERE fdo.taxon_concept_id IN (#{lookup_ids.join(',')})
      AND do.published=1
      AND do.data_type_id IN (#{data_type_ids.join(',')})
      AND do.created_at IS NOT NULL
      AND do.created_at != '0000-00-00 00:00:00'").all_hashes.uniq
    
    return [] if data_object_ids.blank?
    
    data_object_ids.sort! do |a, b|
      b['created_at'] <=> a['created_at']
    end
    
    details = self.details_for_objects(data_object_ids[0...max_results].collect{|obj| obj['id']}, :skip_refs => true)
    return [] if details.blank?
    return details
  end
  
  #----- user submitted text --------
  def self.update_user_text(all_params, user)
    dato = DataObject.find(all_params[:id])
    if dato.user.id != user.id
      raise 'Not original author'
    end
    taxon_concept = TaxonConcept.find(all_params[:taxon_concept_id])
    do_params = {
      :guid => dato.guid,
      :data_type => DataType.find_by_label('Text'),
      :rights_statement => '',
      :rights_holder => '',
      :mime_type_id => MimeType.find_by_label('text/plain').id,
      :location => '',
      :latitude => 0,
      :longitude => 0,
      :bibliographic_citation => '',
      :source_url => '',
      :altitude => 0,
      :object_url => '',
      :thumbnail_url => '',
      :object_title => ERB::Util.h(all_params[:data_object][:object_title]), # No HTML allowed
      :description => all_params[:data_object][:description].allow_some_html,
      :language_id => all_params[:data_object][:language_id],
      :license_id => all_params[:data_object][:license_id],
      :vetted_id => (user.can_curate?(taxon_concept) ? Vetted.trusted.id : Vetted.unknown.id),
      :published => 1, #not sure if this is right
      :visibility_id => Visibility.visible.id #not sure if this is right either
    }

    d = DataObject.new(do_params)
    d.toc_items << TocItem.find(all_params[:data_objects_toc_category][:toc_id])

    unless all_params[:references].blank?
      all_params[:references].each do |reference|
        d.refs << Ref.new({:full_reference => reference, :user_submitted => true, :published => 1, :visibility => Visibility.visible}) if reference.strip != ''
      end
    end

    d.save!
    dato.published = false
    dato.save!
    
    comments_from_old_dato = Comment.find(:all, :conditions => {:parent_id => dato.id})        
    comments_from_old_dato.map { |c| c.update_attribute :parent_id, d.id  }

    d.curator_activity_flag(user, all_params[:taxon_concept_id])
    
    udo = UsersDataObject.new({:user_id => user.id, :data_object_id => d.id, :taxon_concept_id => TaxonConcept.find(all_params[:taxon_concept_id]).id})
    udo.save!
    d.new_actions_histories(user, udo, 'users_submitted_text', 'update')
    
    # this will give it the hash elements it needs for attributions
    d['attributions'] = Attributions.from_agents_hash(d, nil)
    d['users'] = [user]
    d['refs'] = d.refs unless d.refs.empty?
    d
  end

  def self.preview_user_text(all_params, user)
    taxon_concept = TaxonConcept.find(all_params[:taxon_concept_id])

    do_params = {
      :guid => '',
      :data_type => DataType.text,
      :rights_statement => '',
      :rights_holder => '',
      :mime_type_id => MimeType.find_by_label('text/plain').id,
      :location => '',
      :latitude => 0,
      :longitude => 0,
      :object_title => '',
      :bibliographic_citation => '',
      :source_url => '',
      :altitude => 0,
      :object_url => '',
      :thumbnail_url => '',
      :object_title => ERB::Util.h(all_params[:data_object][:object_title]), # No HTML allowed
      :description => all_params[:data_object][:description].allow_some_html,
      :language_id => all_params[:data_object][:language_id],
      :license_id => all_params[:data_object][:license_id],
      :vetted_id => (user.can_curate?(taxon_concept) ? Vetted.trusted.id : Vetted.unknown.id),
      :published => 1, #not sure if this is right
      :visibility_id => Visibility.visible.id #not sure if this is right either
    }

    d = DataObject.new(do_params)
    d.toc_items << TocItem.find(all_params[:data_objects_toc_category][:toc_id])

    unless all_params[:references].blank?
      all_params[:references].each do |reference|
        d.refs << Ref.new({:full_reference => reference, :user_submitted => true, :published => 1, :visibility => Visibility.visible}) if reference.strip != ''
      end
    end
    
    # this will give it the hash elements it needs for attributions
    d['attributions'] = Attributions.from_agents_hash(d, nil)
    d['users'] = [user]
    d['refs'] = d.refs unless d.refs.empty?
    d
  end

  def self.create_user_text(all_params,user)
    taxon_concept = TaxonConcept.find(all_params[:taxon_concept_id])

    do_params = {
      :guid => UUID.generate.gsub('-',''),
      :data_type => DataType.text,
      :rights_statement => '',
      :rights_holder => '',
      :mime_type_id => MimeType.find_by_label('text/plain').id,
      :location => '',
      :latitude => 0,
      :longitude => 0,
      :object_title => '',
      :bibliographic_citation => '',
      :source_url => '',
      :altitude => 0,
      :object_url => '',
      :thumbnail_url => '',
      :object_title => ERB::Util.h(all_params[:data_object][:object_title]), # No HTML allowed
      :description => all_params[:data_object][:description].allow_some_html,
      :language_id => all_params[:data_object][:language_id],
      :license_id => all_params[:data_object][:license_id],
      :vetted_id => (user.can_curate?(taxon_concept) ? Vetted.trusted.id : Vetted.unknown.id),
      :published => 1, #not sure if this is right
      :visibility_id => Visibility.visible.id #not sure if this is right either
    }

    dato = DataObject.new(do_params)
    dato.toc_items << TocItem.find(all_params[:data_objects_toc_category][:toc_id])

    unless all_params[:references].blank?
      all_params[:references].each do |reference|
        dato.refs << Ref.new({:full_reference => reference, :user_submitted => true, :published => 1, :visibility => Visibility.visible}) if reference.strip != ''
      end
    end

    dato.save!
    dato.curator_activity_flag(user, all_params[:taxon_concept_id])
    raise "Unable to build a UsersDataObject if user is nil" if user.nil?
    raise "Unable to build a UsersDataObject if DataObject is nil" if dato.nil?
    raise "Unable to build a UsersDataObject if taxon_concept_id is missing" if all_params[:taxon_concept_id].blank?
    udo = UsersDataObject.new(:user_id => user.id, :data_object_id => dato.id,
                              :taxon_concept_id => taxon_concept.id)
    udo.save!
    dato.new_actions_histories(user, udo, 'users_submitted_text', 'create')
    
    # this will give it the hash elements it needs for attributions
    dato['attributions'] = Attributions.from_agents_hash(dato, nil)
    dato['users'] = [user]
    dato['refs'] = dato.refs unless dato.refs.empty?
    dato
  end

  def created_by_user?
    user != nil
  end

  def user
    @udo ||= UsersDataObject.find_by_data_object_id(self.id)
    @udo_user ||= @udo.nil? ? nil : User.find(@udo.user_id)
  end
  
  def taxon_concept_for_users_text
    unless self.user.nil?
      udo = UsersDataObject.find_by_data_object_id(self.id)
      TaxonConcept.find(udo.taxon_concept_id)
    end
  end

  #----- end of user submitted text --------
  
  def subtitle_to_show
    if object_title.blank? && !info_items.blank?
      subtitle = info_items.first.label
    else 
      subtitle = object_title
    end
    return subtitle
  end

  def rate(user,stars)
    rating = UsersDataObjectsRating.find_by_data_object_guid_and_user_id(self.guid, user.id)
    if rating.nil?
      rating = UsersDataObjectsRating.new({:data_object_guid => self.guid, :user_id => user.id, :rating => stars})
    else
      rating.rating = stars
    end
    rating.save!

    total = 0
    ratings = UsersDataObjectsRating.find_all_by_data_object_guid(self.guid)
    ratings.each do |rating|
      total += rating.rating
    end

    divisor = ratings.length
    if divisor == 0
      self.data_rating = total
    else
      self.data_rating = total / ratings.length
    end

    self.save!
  end

  def rating_for_user(user)
    UsersDataObjectsRating.find_by_data_object_guid_and_user_id(self.guid, user.id)
  end

  # Add a comment to this data object
  def comment(user, body)
    comment = comments.create :user_id => user.id, :body => body
    user.comments.reload # be friendly - update the user's comments automatically
    return comment
  end
  
  # Test whether a user has curator rights on this object
  def is_curatable_by? user
    taxon_concepts.collect {|tc| tc.is_curatable_by?(user) }.include?(true)
  end

  # Find the Agent (only one) that supplied this data object to EOL.
  def data_supplier_agent
    @data_supplier_agent ||= Agent.find_by_sql(["SELECT a.* 
                        FROM data_objects_harvest_events dohe 
                          JOIN harvest_events he ON (dohe.harvest_event_id=he.id)     
                          JOIN agents_resources ar ON (he.resource_id=ar.resource_id) 
                          JOIN agents a ON (ar.agent_id=a.id) 
                        WHERE dohe.data_object_id=? 
                        AND ar.resource_agent_role_id=?", self.id,
                        ResourceAgentRole.data_supplier.id]).first
  end

  # Gets agents_data_objects, sorted by AgentRole, based on this objects' DataTypes' AgentRole attribution
  # priorities
  #
  # we also fetch agents_data_objects, including (eager loading) Agents by default, assuming we will be using them
  def attributions

    @attributions = Attributions.new(agents_data_objects)

    @attributions.add_supplier   self.data_supplier_agent 
    @attributions.add_license    self.license, rights_statement
    @attributions.add_location   self.location
    @attributions.add_source_url self.source_url
    @attributions.add_citation   self.bibliographic_citation

    return @attributions

  end

  # Find all of the authors associated with this data object, including those that we dynamically add elsewhere
  def authors
    default_authors = agents_data_objects.find_all_by_agent_role_id(AgentRole.author_id).collect {|ado| ado.agent }.compact
    @fake_authors.nil? ? default_authors : default_authors + @fake_authors
  end

  # Find all of the photographers associated with this data object, including those that we dynamically add elsewhere
  def photographers
    agents_data_objects.find_all_by_agent_role_id(AgentRole.photographer_id).collect {|ado| ado.agent }.compact
  end

  # Add an author to this data object that isn't in the database.
  def fake_author(author_options)
    @fake_authors ||= []
    @fake_authors << Agent.new(author_options)
  end

  # Find Agents associated with this data object as sources.  If there are none, find authors.
  def sources
    list = agents_data_objects.find_all_by_agent_role_id(AgentRole.source_id).collect {|ado| ado.agent }.compact
    return list unless list.blank?
    # I ended up with empty lists in cases where I thought I shouldn't, so tried to defer to authors for those:
    return authors
  end

  def find_all_for_reharvested_dato
    DataObject.find_all_by_guid(self.guid)
  end
  
  def all_comments
    all_comments = []
    find_all_for_reharvested_dato.each do |parent|
      all_comments += Comment.find_all_by_parent_id(parent.id)
    end
    return all_comments
  end

  def visible_comments(user = nil)
    return comments if (not user.nil?) and user.is_moderator?
    comments.find_all {|comment| comment.visible? }
  end

  def image?
    return DataType.image_type_ids.include?(data_type_id)
  end

  def map?
    return DataType.map_type_ids.include?(data_type_id)
  end

  def text?
    return DataType.text_type_ids.include?(data_type_id)
  end

  def self.cache_path(cache_url, subdir = $CONTENT_SERVER_CONTENT_PATH)
    (ContentServer.next + subdir +
      cache_url.to_s.gsub(/(\d{4})(\d{2})(\d{2})(\d{2})(\d+)/, "/\\1/\\2/\\3/\\4/\\5"))
  end

  def self.image_cache_path(cache_url, size = :large, subdir = $CONTENT_SERVER_CONTENT_PATH)
    self.cache_path(cache_url, subdir) + "_#{size}.#{$SPECIES_IMAGE_FORMAT}"
  end

  def has_thumbnail_cache?
    return false if thumbnail_cache_url.blank? or thumbnail_cache_url == 0
    return true
  end

  def has_object_cache_url?
    return false if object_cache_url.blank? or object_cache_url == 0
    return true
  end

  def thumb_or_object(size = :large)
    return DataObject.image_cache_path(object_cache_url, size) 
  end

  # Returns the src when you want an image tag containing a thumbnail.
  def smart_thumb
    thumb_or_object(:small)
  end

  # Returns the src when you want an image tag containing a "larger" thumbnail (a'la main page).
  def smart_medium_thumb
    thumb_or_object(:medium)
  end

  # Returns the src when you want an image tag containing the *full* image.
  def smart_image
    thumb_or_object
  end  

  def video_url
    if data_type.label == 'Flash'
      return has_object_cache_url? ? DataObject.cache_path(object_cache_url) + '.flv' : ''
    else
      return object_url
    end
  end

  def map_image
    # Sometimes, we want to serve map images right from the source:
    if ($PREFER_REMOTE_IMAGES and not object_url.blank?) or (object_cache_url.blank?)
      return object_url
    else
      return DataObject.cache_path(object_cache_url) + "_orig.jpg"
    end
  end

  # add a DataObjectTag to a DataObject
  def tag(key, values, user = nil)
    values = [values.to_s] unless values.is_a?Array
    if key and values
      values.each do |value|
        tag    = DataObjectTag.find_or_create_by_key_and_value key.to_s, value.to_s
        if user.tags_are_public_for_data_object?(self)
          tag.is_public = true
          tag.save!
        end
        join   = DataObjectTags.new :data_object => self, :data_object_guid => self.guid, :data_object_tag => tag, :user => user
        begin
          join.save!
        rescue # TODO LOWPRIO - specific rescue types with nice, customer-facing explanations.
          raise FailedToCreateTag.new("Failed to add #{key}:#{value} tag")
        end
      end
      tags.reset
      user.tags.reset if user # TODO - can we tag anonymously?  If not, clean this up to reflect that.
    end
  end

  def public_tags
    DataObjectTags.public_tags_for_data_object self
  end

  # TODO: DELETE (NOT USED)
  def private_tags user
    DataObjectTags.private_tags.find_all_by_data_object_guid_and_user_id id, user.id
  end
  
  # TODO: DELETE (NOT USED)
  alias user_tags private_tags
  alias users_tags private_tags

  # Names of taxa associated with this image
  def taxa_names_taxon_concept_ids
    taxa=Taxon.find_by_sql("select t.scientific_name as taxon_name, he.taxon_concept_id from data_objects_taxa dot join taxa t on (dot.taxon_id=t.id) join hierarchy_entries he on (t.hierarchy_entry_id=he.id) where data_object_id=#{self.id}")
    taxa.map{|t| {:taxon_name => t.taxon_name, :taxon_concept_id => t.taxon_concept_id}}
  end

  # returns a hash in the format { 'tag_key' => ['value1','value2'] }
  def tags_hash
    tags.inject({}) do |all,this|
      all[this.key] = (all[this.key] || []) + [this.value]
      all
    end
  end

  # returns an array of all of the keys an object is tagged with
  def tag_keys
    tags.map {|t| t.key }.uniq
  end

  # Return all of the TCs associated with this Dato.  Not necessarily all the pages it shows up on,
  # however, as Zea mays image will show up on Plantae
  def taxon_concepts
    if created_by_user?
      @taxon_concepts ||= [taxon_concept_for_users_text]
    else
      @taxon_concepts ||= TaxonConcept.find_by_sql(["
        SELECT tc.*
        FROM data_objects_taxon_concepts dotc
        JOIN taxon_concepts tc ON (dotc.taxon_concept_id=tc.id)
        WHERE dotc.data_object_id=? -- DataObject#taxon_concepts
      ", self.id])
    end
  end

  # Return all of the HEs associated with this Dato.  Not necessarily all the pages it shows up on,
  # however, as Zea mays image will show up on Plantae
  def hierarchy_entries
    @hierarchy_entries ||= HierarchyEntry.find_by_sql(["
      SELECT he.* FROM data_objects do
      JOIN data_objects_taxa dot ON (do.id=dot.data_object_id)
      JOIN taxa t ON (dot.taxon_id=t.id)
      JOIN hierarchy_entries he ON (t.hierarchy_entry_id=he.id)
      WHERE do.id=? -- DataObject#hierarchy_entries
    ", self.id])
  end
  
  def curate!(vetted_id, visibility_id, user, untrust_reason_ids = [], comment = nil)
    if vetted_id
      vetted_id = vetted_id.to_i
      if vetted_id == Vetted.untrusted.id
        untrust(user, untrust_reason_ids, comment)
      elsif vetted_id == Vetted.trusted.id
        trust(user)
      else
        raise "Cannot set data object vetted id to #{vetted_id}"
      end
    end

    if visibility_id
      visibility_id = visibility_id.to_i
      if visibility_id == Visibility.visible.id
        show(user)
      elsif visibility_id == Visibility.invisible.id
        hide(user)
      elsif visibility_id == Visibility.inappropriate.id
        inappropriate(user)
      else
        raise "Cannot set data object visibility id to #{visibility_id}"
      end
    end

    curator_activity_flag(user)
  end

  def curated?
    self.curated
  end

  def visible?
    visibility_id == Visibility.visible.id
  end

  def invisible?
    visibility_id == Visibility.invisible.id
  end

  def inappropriate?
    visibility_id == Visibility.inappropriate.id
  end

  def untrusted?
    vetted_id == Vetted.untrusted.id
  end

  def unknown?
    vetted_id == Vetted.unknown.id
  end

  def vetted?
    vetted_id == Vetted.trusted.id
  end
  alias is_vetted? vetted?
  alias trusted? vetted?

  def preview?
    visibility_id == Visibility.preview.id
  end

  def curator_activity_flag(user, taxon_concept_id = nil)
    taxon_concept_id ||= taxon_concepts[0].id
    return if taxon_concept_id == 0
     if user and user.can_curate_taxon_concept_id? taxon_concept_id
         LastCuratedDate.create(:user_id => user.id, 
           :taxon_concept_id => taxon_concept_id, 
           :last_curated => Time.now)
     end    
  end
  
  def visible_references(options = {})
    @all_refs ||= refs.delete_if {|r| r.published!=1 || r.visibility_id!=Visibility.visible.id}
  end

  def to_s
    "[DataObject id:#{id}]"
  end

  # Find data objects tagged with a particular tag
  #
  # If no 'value' is provided for the tag, it will find all data objects
  # tagged with *any* value of the given key (category)
  #
  # Usage:
  #   DataObject.search_by_tag :color, 'blue'
  #   DataObject.search_by_tag :color, :blue
  #   DataObject.search_by_tag <DataObjecTag>
  #
  # TODO this is starting to get really messy ... extract some of this outta here into objects ...
  #      try a named_scope on TopImage and things like that ... move to other models or to other
  #      DataObject methods
  #
  def self.search_by_tag key_or_tag, value_or_nil = nil, options = {}
    tag = (key_or_tag.is_a?DataObjectTag) ? key_or_tag : DataObjectTag[key_or_tag, value_or_nil]
    data_object_tags = (tag) ? DataObjectTags.search_by_tag( tag ) : []
    return [] if data_object_tags.empty?
    if options[:clade]
      options[:clade] = [ options[:clade] ] unless options[:clade].is_a?Array
      data_object_ids = data_object_tags.map(&:data_object_id).uniq
      clades = HierarchyEntry.find :all, :conditions => options[:clade].map {|id| "id = #{id}" }.join(' OR ')
      return [] if clades.empty?
      sql = %[
        SELECT DISTINCT top_images.data_object_id
        FROM top_images 
        JOIN hierarchy_entries ON top_images.hierarchy_entry_id = hierarchy_entries.id
        WHERE ]
      sql += clades.map {|clade| "(hierarchy_entries.lft >= #{clade.lft} AND hierarchy_entries.lft <= #{clade.rgt})" }.join(' OR ')
      sql += %[ AND data_object_id IN (#{data_object_ids.join(',')})]
      tagged_images_in_clade = TopImage.find_by_sql sql
      tagged_images_in_clade.map {|img| DataObject.find(img.data_object_id) }.uniq
    else
      data_object_tags.map(&:object).uniq
    end
  end

  # Find data objects tagged with certain tags
  #
  # Usage:
  #   DataObject.search_by_tags [ [<DataObjecTag>], [<DataObjectTag>, <DataObjectTag] ]
  #   DataObject.search_by_tags [ [[:key1,'value1']], [[:key2,:value2],['key3',:value3]] ]
  #
  # TODO: Optimization is necessary, the way it is now is quite resource hungry
  def self.search_by_tags tags, options = {}
    t = tags.inject([]) do |res,tags_group|
      if tags_group.first.is_a?(DataObjectTag)
        res << tags_group
      else
        res << tags_group.map {|k,v| DataObjectTag[k,v]}
      end
    end
    result = t.inject(Set.new) do |res, tags_group|
      search = (DataObject.search_tags_group(tags_group, options).to_set)
      res = res ? search : res.intersection(search)
    end.to_a
    result
  end

  def self.search_tags_group tags, options
    tags.compact!
    return [] if tags.empty?
    data_object_tags = DataObjectTags.search_by_tags_or tags, options[:user_id]
    return [] if data_object_tags.empty?

    if options[:clade]

      # TODO - THIS HAS BEEN COPY/PASTED - ***JUST*** FOR TESTING - NEEDS REFACTORING & TO BE DRY'd UP
      options[:clade] = [ options[:clade] ] unless options[:clade].is_a?Array
      data_object_ids = data_object_tags.map(&:data_object_id).uniq
      clades = HierarchyEntry.find :all, :conditions => options[:clade].map {|id| "id = #{self.id}" }.join(' OR ')
      return [] if clades.empty?
      sql = %[
        SELECT DISTINCT top_images.data_object_id
        FROM top_images 
        JOIN hierarchy_entries ON top_images.hierarchy_entry_id = hierarchy_entries.id
        WHERE ]
      sql += clades.map {|clade| "(hierarchy_entries.lft >= #{clade.lft} AND hierarchy_entries.lft <= #{clade.rgt})" }.join(' OR ')
      sql += %[ AND data_object_id IN (#{data_object_ids.join(',')})]
      tagged_images_in_clade = TopImage.find_by_sql sql
      return tagged_images_in_clade.map {|img| DataObject.find(img.data_object_id) }.uniq

    else
      return data_object_tags.map(&:object).uniq
    end
  end
  
  def self.build_top_images_query(taxon, options = {})
    join_hierarchy = join_agents = ''
    options[:unpublished] ||= false
    options[:filter_hierarchy] ||= nil
    from_table = options[:unpublished] ? 'top_unpublished_concept_images' : 'top_concept_images'
    where_clause = "ti.taxon_concept_id=#{taxon.id}"
    
    # filtering by hierarchy means we need the top_* tables which use hierarchy_entry_ids
    if !options[:filter_hierarchy].nil?
      from_table = options[:unpublished] ? 'top_unpublished_images' : 'top_images'
      join_hierarchy = "JOIN hierarchy_entries he_filter ON (ti.hierarchy_entry_id=he_filter.id AND he_filter.hierarchy_id=#{options[:filter_hierarchy].id})"
      where_clause = "ti.hierarchy_entry_id IN (#{taxon.hierarchy_entries.collect {|he| he.id }.join(',')})"
    end
    
    # unpublished images require a few extra bits to the query:
    if options[:unpublished]
      from_cp = ', ar.agent_id agent_id'
      join_agents = self.join_agents_clause(options[:agent])
    else
      from_cp = ', NULL agent_id'
    end
    
    query_string = %Q{
      SELECT dato.id, dato.visibility_id, dato.data_rating, dato.vetted_id, dato.guid, v.view_order vetted_view_order #{from_cp}
        FROM #{from_table} ti
          JOIN data_objects dato      ON ti.data_object_id = dato.id
          JOIN vetted v               ON dato.vetted_id = v.id
          #{join_agents}
          #{join_hierarchy}
        WHERE #{where_clause}
          AND ti.view_order < 170
          #{DataObject.visibility_clause(options.merge(:taxon => taxon))} # DataObject.cached_images_for_taxon
      }
  end
  
  def self.cached_images_for_taxon(taxon, options = {})
    options[:user] = User.create_new if options[:user].nil?    
    if options[:filter_by_hierarchy] && !options[:hierarchy].nil?
      options[:filter_hierarchy] = options[:hierarchy]
    end
    
    top_images_query = DataObject.build_top_images_query(taxon, options)
    
    # the user/agent has the ability to see some unpublished images, so create a UNION
    show_unpublished = ((not options[:agent].nil?) or options[:user].is_curator? or options[:user].is_admin?)
    if show_unpublished
      options[:unpublished] = true
      top_unpublished_images_query = DataObject.build_top_images_query(taxon, options)
      top_images_query = "(#{top_images_query}) UNION (#{top_unpublished_images_query})"
    end
    
    # commenting this out as it could be effecting curator rating
    # # if there is no filter hierarchy and we're just returning published images - the default
    # if options[:filter_hierarchy].nil? && !show_unpublished && !options[:user].vetted
    #   result = Rails.cache.fetch("data_object/cached_images_for/#{taxon.id}") do
    #     data_objects_result = DataObject.find_by_sql(top_images_query)
    #   end
    # else
      data_objects_result = DataObject.find_by_sql(top_images_query).uniq
    # end
    
    # when we have all the images then get the uniquq list and sort them by
    # vetted order ASC (so trusted are first), rating DESC (so best are first), id DESC (so newest are first)
    data_objects_result.sort! do |a, b|
      if a.vetted_view_order == b.vetted_view_order
        # TODO - this should probably also sort on visibility.
        if a.data_rating == b.data_rating
          b.id <=> a.id # essentially, orders images by date.
        else
          b.data_rating <=> a.data_rating # Note this is reversed; higher ratings are better.
        end
      else
        a.vetted_view_order <=> b.vetted_view_order
      end
    end
    
    # an extra loop to ensure that we have no duplicate GUIDs
    result = []
    used_guids = {}
    data_objects_result.each do |r|
      result << r if used_guids[r.guid].blank?
      used_guids[r.guid] = true
    end
    
    return [] if result.empty?
    
    # get the rest of the metadata for the selected page
    image_page        = (options[:image_page] ||= 1).to_i
    start             = $MAX_IMAGES_PER_PAGE * (image_page - 1)
    last              = start + $MAX_IMAGES_PER_PAGE - 1
    results_to_lookup = result[start..last]
    
    results_to_lookup = DataObject.metadata_for_images(taxon.id, results_to_lookup, {:user => options[:user]})
    results_to_lookup = DataObject.add_attributions_to_result(results_to_lookup)
    results_to_lookup = DataObject.add_taxa_names_to_result(results_to_lookup)
    result[start..last] = results_to_lookup
    
    return result
  end
  
  def self.metadata_for_images(taxon_id, results, options = {})
    data_object_ids = results.collect {|r| r.id}
    return results if data_object_ids.empty?
    
    comments_clause = " AND c.visible_at IS NOT NULL"
    comments_clause = "" if !options[:user].nil? && options[:user].is_moderator?
    
    rating_select = " 0 as user_rating"
    rating_from = " "
    if !options[:user].nil? && options[:user].id
      rating_select = "udor.rating user_rating"
      rating_from = " LEFT OUTER JOIN #{UsersDataObjectsRating.full_table_name} udor ON (dato.guid=udor.data_object_guid AND udor.user_id=#{options[:user].id})"
    end
    
    data_objects_with_metadata = DataObject.find_by_sql(%Q{
        SELECT 'Image' media_type, dato.*, v.view_order vetted_view_order, l.description license_text, l.logo_url license_logo, l.source_url license_url,
               #{taxon_id} taxon_id, t.scientific_name, count(distinct c.id) as comments_count, #{rating_select}
         FROM #{DataObject.full_table_name} dato
           STRAIGHT_JOIN #{Vetted.full_table_name} v              ON (dato.vetted_id=v.id)
           STRAIGHT_JOIN #{DataObjectsTaxon.full_table_name} dot  ON (dato.id=dot.data_object_id)
           STRAIGHT_JOIN #{Taxon.full_table_name} t               ON (dot.taxon_id=t.id)
           LEFT OUTER JOIN #{License.full_table_name} l           ON (dato.license_id=l.id)
           LEFT OUTER JOIN #{Comment.full_table_name} c           ON (c.parent_id=dato.id AND c.parent_type='DataObject' #{comments_clause})
           #{rating_from}
         WHERE dato.id IN (#{data_object_ids.join(',')})
         GROUP BY dato.id })
    
    metadata = {}
    # add the DataObject metadata
    data_objects_with_metadata.each do |dom|
      dom.description = dom.description_linked if !dom.description_linked.nil?
      metadata[dom.id.to_i] = dom
    end
    
    results.each_with_index do |r, index|
      if m = metadata[r.id.to_i]
        results[index] = m
      end
    end
    return results
  end
  
  def self.add_attributions_to_result(results)
    data_object_ids = results.collect {|r| r.id}
    return results if data_object_ids.empty?
    
    data_supplier_id = ResourceAgentRole.content_partner_upload_role.nil? ? 0 : ResourceAgentRole.content_partner_upload_role.id
    data_object_agents = Agent.find_by_sql(%Q{
        (SELECT a.*, 0 as data_supplier, ado.agent_role_id, ar.label agent_role_label, ado.data_object_id, ado.view_order
          FROM agents_data_objects ado JOIN agents a ON (ado.agent_id=a.id)
          JOIN agent_roles ar ON (ado.agent_role_id=ar.id)
          WHERE ado.data_object_id IN (#{data_object_ids.join(',')}))
        UNION
        (SELECT a.* , 1 as data_supplier, NULL agent_role_id, NULL agent_role_label, dohe.data_object_id, 1 view_order
          FROM data_objects_harvest_events dohe 
          JOIN harvest_events he                ON (dohe.harvest_event_id=he.id) 
          JOIN agents_resources ar              ON (he.resource_id=ar.resource_id) 
          JOIN agents a                         ON (ar.agent_id=a.id) 
          WHERE dohe.data_object_id IN (#{data_object_ids.join(',')})
          AND ar.resource_agent_role_id=#{data_supplier_id})
        ORDER BY view_order
         })
    
    
    attributions = {}
    data_object_agents.each do |a|
      do_id = a['data_object_id'].to_i
      attributions[do_id] ||= {
            'supplied_user_id'  => nil,
            'data_supplier'     => nil,
            'agents'            => {} }
      if attributions[do_id]['agents'].empty?
        @all_agent_roles ||= AgentRole.all
        @all_agent_roles.each do |ar|
          attributions[do_id]['agents'][ar.label] ||= []
        end
      end
          
      if a['data_supplier'].to_i == 1
        attributions[do_id]['data_supplier'] = a
      else
        attributions[do_id]['agents'][a['agent_role_label']] ||= []
        attributions[do_id]['agents'][a['agent_role_label']] << a
      end
    end
    
    results.each do |r|
      r['attributions'] = {}
      if a = attributions[r.id.to_i]
        r['data_supplier'] = a['data_supplier'] if !a['data_supplier'].nil?
        a['attributions'] = Attributions.from_agents_hash(r, a)
        a.each do |key, value|
          r[key] = value
        end
      else
        r['attributions'] = Attributions.from_agents_hash(r, nil)
      end
    end
    
    return results
  end
  
  def self.add_taxa_names_to_result(results)
    data_object_ids = results.collect {|r| r.id}
    return results if data_object_ids.empty?
    
    data_object_taxa_names = Taxon.find_by_sql(%Q{
        SELECT t.scientific_name as taxon_name, he.taxon_concept_id, dot.data_object_id
          FROM data_objects_taxa dot
          JOIN taxa t ON (dot.taxon_id=t.id)
          JOIN hierarchy_entries he ON (t.hierarchy_entry_id=he.id)
          WHERE dot.data_object_id IN (#{data_object_ids.join(',')})})
    
    grouped_taxa_names = ModelQueryHelper.group_array_by_key(data_object_taxa_names, 'data_object_id')
    results = ModelQueryHelper.add_hash_to_object_array_as_key(results, grouped_taxa_names, 'taxa_names_ids')
    return results
  end
  
  def self.add_refs_to_result(results)
    data_object_ids = results.collect {|r| r.id}
    return results if data_object_ids.empty?
    
    refs = Ref.find_by_sql(%Q{
        SELECT r.*, dor.data_object_id
          FROM data_objects_refs dor
          JOIN refs r ON (dor.ref_id=r.id)
          WHERE dor.data_object_id IN (#{data_object_ids.join(',')})
          AND r.published=1
          AND r.visibility_id=#{Visibility.visible.id}})
    
    grouped_refs = ModelQueryHelper.group_array_by_key(refs, 'data_object_id')
    results = ModelQueryHelper.add_hash_to_object_array_as_key(results, grouped_refs, 'refs')
    return results
  end
  
  def self.add_users_to_result(results)
    data_object_ids = results.collect {|r| r.id}
    return results if data_object_ids.empty?
    
    users = User.find_by_sql(%Q{
        SELECT u.*, udo.data_object_id
          FROM #{UsersDataObject.full_table_name} udo
          JOIN #{User.full_table_name} u ON (udo.user_id=u.id)
          WHERE udo.data_object_id IN (#{data_object_ids.join(',')})})
    
    grouped_users = ModelQueryHelper.group_array_by_key(users, 'data_object_id')
    results = ModelQueryHelper.add_hash_to_object_array_as_key(results, grouped_users, 'users')
    return results
  end
  
  

  # Find all of the data objects of a particular type (text, image, etc) associated with a given taxon.
  # Options may include current agents and/or users, to affect permissions of who sees what.
  def self.for_taxon(taxon, type, options = {})

    options[:user] = User.create_new if options[:user].nil?

    results = nil # scope

    if type == :image
      # Just return the (much faster) cached images if that's the type we're dealing with:
      results = DataObject.cached_images_for_taxon(taxon, options)
    else
      # usually, we want to return data objects.  But if we want text objects, we call them toc items...
      if type == :text && options[:toc_id].nil?
        results = TocItem.find_by_sql(DataObject.build_query(taxon, type, options))
      else
        results = DataObject.other_type_for_taxon(taxon, type, options)
      end
    end

    # In order to display a warning about pages that include unvetted material, we check now, while the
    # information is most readily available (data objects are the only things that can be unvetted, and only
    # if we have to check permissions), and then flag the taxon_concept model if anything is non-trusted.
    trusted_id = Vetted.trusted.id
    taxon.includes_unvetted = true if results.detect {|d| d.vetted_id != trusted_id }

    # Content Partners' query included ALL invisible, untrusted and unknown items... not JUST THEIRS.  We
    # now need to exclude those items that they did not contribute:
    if options[:agent]
      results.delete_if do |dato|
        dato.visibility_id == Visibility.preview.id and not dato['data_supplier'].nil? and
          dato['data_supplier'].id != options[:agent].id
      end
    end

    return results

  end
  
  def self.other_type_for_taxon(taxon, type, options)
    # generate the query to search for data objects
    query = DataObject.build_query(taxon, type, options)
    # load the objects and the info we need to sort them
    result = DataObject.find_by_sql(query)
    result = result.uniq
    
    # sort objects by vetted order ASC (so trusted are first), rating DESC (so best are first), id DESC (so newest are first)
    result.sort! do |a, b|
      if a.vetted_view_order == b.vetted_view_order
        # TODO - this should probably also sort on visibility.
        if a.data_rating == b.data_rating
          b.id <=> a.id # essentially, orders images by date.
        else
          b.data_rating <=> a.data_rating # Note this is reversed; higher ratings are better.
        end
      else
        a.vetted_view_order <=> b.vetted_view_order
      end
    end
    
    # query result set for attribution info, taxa info (for permalinks), and references
    result = DataObject.add_attributions_to_result(result)
    result = DataObject.add_taxa_names_to_result(result)
    result = DataObject.add_refs_to_result(result)
    result = DataObject.add_users_to_result(result)
    return result
  end

  # TODO - MED PRIORITY - I'm assuming there's one taxa for this data object, and there could be several.
  # TODO = licenses should simply be included, and referenced directly where needed.
  def self.build_query(taxon, type, options)
    add_toc      = (type == :text and options[:toc_id].nil?) ? ', toc.*' : ''
    add_cp       = options[:agent].nil? ? '' : ', ar.agent_id agent_id'
    join_agents  = options[:agent].nil? ? '' : self.join_agents_clause(options[:agent])
    join_toc     = type == :text        ? 'JOIN data_objects_table_of_contents dotoc ON dotoc.data_object_id = dato.id ' +
                                                 'JOIN table_of_contents toc ON toc.id = dotoc.toc_id' : ''
    where_toc    = options[:toc_id].nil? ? '' : ActiveRecord::Base.sanitize_sql(['AND toc.id = ?', options[:toc_id]])
    #sort         = 'published, vetted_id DESC, data_rating DESC' # unpublished first, then by data_rating.
    sort         = 'published, vetted_sort_order, data_rating DESC' # unpublished first, then by data_rating.    
    data_type_ids = DataObject.get_type_ids(type)
    
    query_string = %Q{
(SELECT dt.label media_type, dato.*, dotc.taxon_concept_id taxon_id,
       l.description license_text, l.logo_url license_logo, l.source_url license_url #{add_toc} #{add_cp}, v.view_order as vetted_view_order
  FROM data_objects_taxon_concepts dotc
    JOIN data_objects dato     ON (dotc.data_object_id = dato.id)
    JOIN vetted v              ON (dato.vetted_id=v.id)
    JOIN data_types dt         ON (dato.data_type_id = dt.id)
    #{join_agents} #{join_toc}
    LEFT OUTER JOIN licenses l       ON (dato.license_id = l.id)
  WHERE dotc.taxon_concept_id = #{taxon.id}
    AND data_type_id IN (#{data_type_ids.join(',')})
    #{DataObject.visibility_clause(options.merge(:taxon => taxon))}
    #{where_toc})
UNION
(SELECT dt.label media_type, dato.*, taxon_concept_id taxon_id, l.description license_text, l.logo_url license_logo, l.source_url license_url #{add_toc} #{add_cp}, v.view_order vetted_view_order
FROM data_objects dato
JOIN vetted v              ON (dato.vetted_id=v.id)
JOIN #{ UsersDataObject.full_table_name } udo ON (dato.id=udo.data_object_id)
STRAIGHT_JOIN data_types dt ON (dato.data_type_id = dt.id)
#{join_agents} #{join_toc}
LEFT OUTER JOIN licenses l ON (dato.license_id = l.id)
WHERE
udo.taxon_concept_id=#{taxon.id}
AND data_type_id IN (#{data_type_ids.join(',')})
#{DataObject.visibility_clause(options.merge(:taxon => taxon))}
    #{where_toc}) # DataObject.for_taxon
    }
  end

  alias :ar_to_xml :to_xml
  # Be careful calling a block here.  We have our own builder, and you will be overriding that if you use a block.
  def to_xml(options = {})
    default_only   = [:id, :bibliographic_citation, :description, :guid, :rights_holder, :rights_statement]
    default_only  += [:altitude, :latitude, :location, :longitude] unless map? or text?
    options[:only] = (options[:only] ? options[:only] + default_only : default_only)
    options[:methods] ||= [:data_supplier_agent, :tags_hash]
    options[:methods] << :map_image if map?
    default_block = lambda do |xml|
      xml.attributions do
        attributions.each do |attr|
          xml.attribution do
            xml.role attr.agent_role.label
            attr.agent.to_xml(:builder => xml, :skip_instruct => true)
          end
        end
      end
      xml.language language.label unless map? or image?
      xml.license license.title
      xml.type data_type.label
      xml.url thumb_or_object unless map?
      xml.medium_thumb_url thumb_or_object(:medium) unless map?
      xml.small_thumb_url thumb_or_object(:small) unless map?
    end
    if block_given?
      ar_to_xml(options) { |xml| yield xml }
    else 
      ar_to_xml(options) { |xml| default_block.call(xml) }
    end
  end
  
  def self.latest_published_version_of(data_object_id)
    obj = DataObject.find_by_sql("SELECT MAX(do.id) id FROM data_objects do_old JOIN data_objects do ON (do_old.guid=do.guid) WHERE do_old.id=#{data_object_id} AND do.published=1")[0]
    return nil if obj.id.nil?
    return DataObject.find(obj.id)
  end


  def self.data_object_details(data_object_ids,page)
    if(data_object_ids.length > 0) then
    
    query="SELECT distinct  taxon_concepts.id taxon_concept_id , data_objects.id , 
    mime_types.label as mime, data_types.label as datatype, vetted.label vetted_label, visibilities.label visible,
    data_objects.object_title as title, data_objects.source_url, data_objects.description,
    taxon_concepts.published, data_objects.object_cache_url
    from
    data_objects
    Inner Join mime_types ON data_objects.mime_type_id = mime_types.id
    Inner Join vetted ON data_objects.vetted_id = vetted.id
    Inner Join visibilities ON data_objects.visibility_id = visibilities.id
    Inner Join data_types ON data_objects.data_type_id = data_types.id

    Inner Join data_objects_taxa ON data_objects.id = data_objects_taxa.data_object_id
    Inner Join taxa ON data_objects_taxa.taxon_id = taxa.id
    Left Join hierarchy_entries ON taxa.hierarchy_entry_id = hierarchy_entries.id
    Left Join taxon_concepts ON hierarchy_entries.taxon_concept_id = taxon_concepts.id
    Where data_objects.id in (#{data_object_ids.join(',')})
    AND taxon_concepts.published = 1     
    order by data_objects.id     
    "
    query="
    Select distinct taxon_concepts.id AS taxon_concept_id,
    data_objects.id, vetted.label AS vetted_label, visibilities.label AS visible,
    data_objects.object_title AS title, data_objects.source_url,
    data_objects.description, taxon_concepts.published,
    data_objects.object_cache_url, concat(toc2.label, ' - ', table_of_contents.label) as toc
    From
    data_objects
    Inner Join vetted ON data_objects.vetted_id = vetted.id
    Inner Join visibilities ON data_objects.visibility_id = visibilities.id
    Inner Join data_objects_taxa ON data_objects.id = data_objects_taxa.data_object_id
    Inner Join taxa ON data_objects_taxa.taxon_id = taxa.id
    Left Join hierarchy_entries ON taxa.hierarchy_entry_id = hierarchy_entries.id
    Left Join taxon_concepts ON hierarchy_entries.taxon_concept_id = taxon_concepts.id
    Left Join data_objects_table_of_contents ON data_objects.id = data_objects_table_of_contents.data_object_id
    left Join table_of_contents ON data_objects_table_of_contents.toc_id = table_of_contents.id
    left Join table_of_contents toc2 ON table_of_contents.parent_id = toc2.id
    Where data_objects.id in (#{data_object_ids.join(',')})
    AND taxon_concepts.published = 1
    order by data_objects.id "
    # AND taxon_concepts.published = 1
    # AND taxon_concepts.supercedure_id = 0    
    # (2983141, 2985085, 2996805)
    # #{data_object_ids.join(',')}
    
    self.paginate_by_sql [query, data_object_ids], :page => page, :per_page => 50 , :order => 'id'
    
    end
    
  end
  
  
  def self.get_toc_info(obj_ids)
    
    obj_toc_info = {} #same Hash.new
    if(obj_ids.length > 0) then
      sql = "
      Select data_objects.id, vetted.label AS vetted_label, visibilities.label AS visible,        
      concat(toc2.label, ' - ', table_of_contents.label) as toc
      From data_objects
      left Join vetted ON data_objects.vetted_id = vetted.id
      left Join visibilities ON data_objects.visibility_id = visibilities.id
      Left Join data_objects_table_of_contents ON data_objects.id = data_objects_table_of_contents.data_object_id
      left Join table_of_contents ON data_objects_table_of_contents.toc_id = table_of_contents.id
      left Join table_of_contents toc2 ON table_of_contents.parent_id = toc2.id
      Where data_objects.id in (#{obj_ids.join(',')})"
      rset = DataObject.find_by_sql([sql])            
      rset.each do |post|
        obj_toc_info["#{post.id}"] = "#{post.toc}"
        obj_toc_info["e#{post.id}"] = "#{post.vetted_label} <br>  #{post.visible}"
      end    
    end
    
    return obj_toc_info
  end
  
  def self.get_dataobjects(obj_ids,page) 
    query="Select data_objects.* From data_objects
    Inner Join vetted ON data_objects.vetted_id = vetted.id
    WHERE data_objects.id IN (#{ obj_ids.join(', ') })
    "
    self.paginate_by_sql [query, obj_ids], :page => page, :per_page => 20 , :order => 'id'  
  end
  
  
  
  def self.details_for_object(data_object_guid, options = {})
    data_object = DataObject.find_by_guid(data_object_guid, :conditions => "published=1 AND visibility_id=#{Visibility.visible.id}", :order => "id desc")
    return [] if data_object.nil?
    
    details = self.details_for_objects([data_object.id])
    return [] if details.blank?
    first_obj = details[0]
    
    # create the objects taxon and place the object inside
    if options[:include_taxon]
      obj = DataObject.find(first_obj['id'])
      tc = obj.taxon_concepts[0]
      return tc.details_hash(:data_object_hash => first_obj)
    end
    
    # return the object alone
    return first_obj 
  end
  
  def self.details_for_objects(data_object_ids, options = {})
    return [] unless data_object_ids.is_a? Array
    return [] if data_object_ids.empty?
    object_details_hashes = SpeciesSchemaModel.connection.execute("
      SELECT do.*, dt.schema_value data_type, dt.label data_type_label, mt.label mime_type, lang.iso_639_1 language,
              lic.source_url license, lic.title license_label, ii.schema_value subject, v.view_order vetted_view_order, toc.view_order toc_view_order,
              t.scientific_name, he.taxon_concept_id
        FROM data_objects do
        LEFT JOIN data_types dt ON (do.data_type_id=dt.id)
        LEFT JOIN mime_types mt ON (do.mime_type_id=mt.id)
        LEFT JOIN languages lang ON (do.language_id=lang.id)
        LEFT JOIN licenses lic ON (do.license_id=lic.id)
        LEFT JOIN vetted v ON (do.vetted_id=v.id)
        LEFT JOIN (
           info_items ii
           JOIN table_of_contents toc ON (ii.toc_id=toc.id)
           JOIN data_objects_table_of_contents dotoc ON (toc.id=dotoc.toc_id)
          ) ON (do.id=dotoc.data_object_id)
        LEFT JOIN (
           data_objects_taxa dot
           JOIN taxa t ON (dot.taxon_id=t.id)
           JOIN hierarchy_entries he ON (t.hierarchy_entry_id=he.id)
          ) ON (do.id=dot.data_object_id)
        WHERE do.id IN (#{data_object_ids.join(',')})
        AND do.published = 1
        AND do.visibility_id = #{Visibility.visible.id}
        GROUP BY do.id
    ").all_hashes
    
    flash_id = DataType.flash.id
    youtube_id = DataType.youtube.id
    object_details_hashes.each do |r|
      if r['data_type_id'].to_i == flash_id || r['data_type_id'].to_i == youtube_id
        r['data_type'] = DataType.video.schema_value
      end
    end
    
    object_details_hashes = ModelQueryHelper.sort_object_hash_by_display_order(object_details_hashes)
    
    object_details_hashes = DataObject.add_refs_to_details(object_details_hashes) if options[:skip_metadata].blank? && options[:skip_refs].blank?
    object_details_hashes = DataObject.add_agents_to_details(object_details_hashes) if options[:skip_metadata].blank?
    object_details_hashes
  end
  
  def self.add_refs_to_details(object_details_hash)
    data_object_ids = object_details_hash.collect {|r| r['id']}
    return object_details_hash if data_object_ids.blank?
    
    refs = SpeciesSchemaModel.connection.execute("
        SELECT r.*, dor.data_object_id
          FROM data_objects_refs dor
          JOIN refs r ON (dor.ref_id=r.id)
          WHERE dor.data_object_id IN (#{data_object_ids.join(',')})
          AND r.published=1
          AND r.visibility_id=#{Visibility.visible.id}").all_hashes
    
    grouped_refs = ModelQueryHelper.group_array_by_key(refs, 'data_object_id')
    object_details_hash = ModelQueryHelper.add_hash_to_hash_as_key(object_details_hash, grouped_refs, 'refs')
    return object_details_hash
  end
  
  def self.add_agents_to_details(object_details_hash)
    data_object_ids = object_details_hash.collect {|r| r['id']}
    return object_details_hash if data_object_ids.blank?
    
    data_supplier_id = ResourceAgentRole.content_partner_upload_role.nil? ? 0 : ResourceAgentRole.content_partner_upload_role.id
    agents = SpeciesSchemaModel.connection.execute("
        (SELECT a.* , 'Provider' role, dohe.data_object_id, -1 view_order
          FROM data_objects_harvest_events dohe 
          JOIN harvest_events he                ON (dohe.harvest_event_id=he.id) 
          JOIN agents_resources ar              ON (he.resource_id=ar.resource_id) 
          JOIN agents a                         ON (ar.agent_id=a.id) 
          WHERE dohe.data_object_id IN (#{data_object_ids.join(',')})
          AND ar.resource_agent_role_id=#{data_supplier_id})
        UNION
        (SELECT a.*, ar.label role, ado.data_object_id, ado.view_order
          FROM agents_data_objects ado
          JOIN agents a ON (ado.agent_id=a.id)
          JOIN agent_roles ar ON (ado.agent_role_id=ar.id)
          WHERE ado.data_object_id IN (#{data_object_ids.join(',')}))
        ORDER BY view_order").all_hashes
    
    agents.sort do |a, b|
      b['view_order'].to_i <=> a['view_order'].to_i
    end
    
    grouped = ModelQueryHelper.group_array_by_key(agents, 'data_object_id')
    object_details_hash = ModelQueryHelper.add_hash_to_hash_as_key(object_details_hash, grouped, 'agents')
    return object_details_hash
  end
  
  # using object.untrust_reasons.include? was firing off a query every time. This is faster
  def untrust_reasons_include?(untrust_reason)
    @untrust_reasons_cached ||= untrust_reasons
    return true if @untrust_reasons_cached.index(untrust_reason)
    return false
  end





private

  def show(user)
    self.vetted_by = user
    update_attributes({:visibility_id => Visibility.visible.id, :curated => true})
    new_actions_histories(user, self, 'data_object', 'show')
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.show!
  end

  def hide(user)
    self.vetted_by = user
    update_attributes({:visibility_id => Visibility.invisible.id, :curated => true})
    new_actions_histories(user, self, 'data_object', 'hide')
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.hide!
  end

  def trust(user)
    self.vetted_by = user
    update_attributes({:vetted_id => Vetted.trusted.id, :curated => true})
    DataObjectsUntrustReason.destroy_all(:data_object_id => self.id)
    new_actions_histories(user, self, 'data_object', 'trusted')
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.approve!
  end

  def untrust(user, untrust_reason_ids, comment)
    self.vetted_by = user
    update_attributes({:vetted_id => Vetted.untrusted.id, :curated => true})
    DataObjectsUntrustReason.destroy_all(:data_object_id => self.id)
    if untrust_reason_ids
      untrust_reason_ids.each do |untrust_reason_id|
        self.untrust_reasons << UntrustReason.find(untrust_reason_id)
      end
    end
    if comment && !comment.blank?
      self.comment(user, comment)
    end
    new_actions_histories(user, self, 'data_object', 'untrusted')
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.disapprove!
  end

  def inappropriate(user)
    self.vetted_by = user
    update_attributes({:visibility_id => Visibility.inappropriate.id, :curated => true})
    new_actions_histories(user, self, 'data_object', 'inappropriate')
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.inappropriate!
  end
  
  def self.join_agents_clause(agent)
    data_supplier_id = ResourceAgentRole.content_partner_upload_role.id
    return %Q{LEFT JOIN (agents_resources ar
              STRAIGHT_JOIN harvest_events hevt ON (ar.resource_id = hevt.resource_id
                AND ar.resource_agent_role_id = #{data_supplier_id})
              STRAIGHT_JOIN data_objects_harvest_events dohe ON hevt.id = dohe.harvest_event_id)
                ON (dato.id = dohe.data_object_id)}
                  #AND ar.agent_id = #{agent.id}  -- We removed this because now we're filtering manually.
  end

  # TODO - this smells like a good place to use a Strategy pattern.  The user can have certain behaviour based
  # on their access.
  def self.visibility_clause(options)
    preview_objects = ActiveRecord::Base.sanitize_sql(['OR (dato.visibility_id = ? AND dato.published IN (0,1))', Visibility.preview.id])
    published    = [1] # Boolean
    vetted       = [Vetted.trusted.id]
    visibility   = [Visibility.visible.id]
    other_visibilities = ''
    if options[:user]
      if options[:user].is_curator? and options[:user].can_curate?(options[:taxon])
        vetted += [Vetted.untrusted.id, Vetted.unknown.id] if options[:user].show_unvetted?
        visibility << Visibility.invisible.id
      end
      if options[:user].is_admin?
        vetted += [Vetted.untrusted.id, Vetted.unknown.id]
        visibility = Visibility.all_ids
        other_visibilities = preview_objects
      end
      if options[:user].vetted == false
        vetted += [Vetted.unknown.id,Vetted.untrusted.id]
      end
    end
    # TODO - The problem here is that we're Allowing CPs to see EVERYTHING, when they should only see THEIR
    # invisibles, untrusteded, and unknowns.
    if options[:agent] # Content partner ... note that some of this is handled via the join in join_agents_clause().
      visibility << Visibility.invisible.id
      vetted += [Vetted.untrusted.id, Vetted.unknown.id]
      other_visibilities = preview_objects
    end

    return ActiveRecord::Base.sanitize_sql([<<EOVISBILITYCLAUSE, vetted.uniq, published, visibility])
    AND dato.vetted_id IN (?)
    AND ((dato.published IN (?)
      AND dato.visibility_id IN (?)) #{other_visibilities})
EOVISBILITYCLAUSE
  end

  def self.get_type_ids(type)
    case type
    when :map 
      return DataType.map_type_ids
    when :text 
      return DataType.text_type_ids
    when :video 
      return DataType.video_type_ids
    when :image 
      return DataType.image_type_ids
    else
      raise "I'm not sure what data type #{type} is."
    end
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_objects
#
#  id                     :integer(4)      not null, primary key
#  data_type_id           :integer(2)      not null
#  language_id            :integer(2)      not null
#  license_id             :integer(1)      not null
#  mime_type_id           :integer(2)      not null
#  vetted_id              :integer(1)      not null
#  visibility_id          :integer(4)
#  altitude               :float           not null
#  bibliographic_citation :string(300)     not null
#  curated                :boolean(1)      not null
#  data_rating            :float           not null
#  description            :text            not null
#  guid                   :string(32)      not null
#  latitude               :float           not null
#  location               :string(255)     not null
#  longitude              :float           not null
#  object_cache_url       :string(255)     not null
#  object_title           :string(255)     not null
#  object_url             :string(255)     not null
#  published              :boolean(1)      not null
#  rights_holder          :string(255)     not null
#  rights_statement       :string(300)     not null
#  source_url             :string(255)     not null
#  thumbnail_cache_url    :string(255)     not null
#  thumbnail_url          :string(255)     not null
#  created_at             :timestamp       not null
#  object_created_at      :timestamp       not null
#  object_modified_at     :timestamp       not null
#  updated_at             :timestamp       not null

