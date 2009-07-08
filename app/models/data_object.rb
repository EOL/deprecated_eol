require 'set'
require 'uuid'
require 'erb'

# Represents any kind of object imported from a ContentPartner, eg. an image, article, video, etc.  This is one
# of our primary models, and an awful lot of work occurs here.
class DataObject < SpeciesSchemaModel
  
  include UserActions

  belongs_to :data_type
  belongs_to :language
  belongs_to :license
  belongs_to :mime_type
  belongs_to :visibility
  belongs_to :vetted

	has_many :top_images
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

  has_and_belongs_to_many :taxa
  has_and_belongs_to_many :info_items
  has_and_belongs_to_many :audiences
  has_and_belongs_to_many :refs
  has_and_belongs_to_many :agents
  has_and_belongs_to_many :toc_items, :join_table => 'data_objects_table_of_contents', :association_foreign_key => 'toc_id'

  attr_accessor :vetted_by # who changed the state of this object? (not persisted on DataObject but required by observer)

  named_scope :visible, lambda { { :conditions => { :visibility_id => Visibility.visible.id } }}
  named_scope :preview, lambda { { :conditions => { :visibility_id => Visibility.preview.id } }}

  #----- user submitted text --------
  def self.update_user_text(all_params, user)
    dato = DataObject.find(all_params[:id])
    if dato.user.id != user.id
      raise 'Not original author'
    end
    do_params = {
      :guid => dato.guid,
      :data_type => DataType.find_by_label('Text'),
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
      :vetted_id => Vetted.unknown.id,
      :published => 1, #not sure if this is right
      :visibility_id => Visibility.visible.id #not sure if this is right either
    }

    dato.published = false
    dato.save!

    d = DataObject.new(do_params)
    d.toc_items << TocItem.find(all_params[:data_objects_toc_category][:toc_id])
    d.save!
    d.curator_activity_flag(user, all_params[:taxon_concept_id])
    udo = UsersDataObject.new({:user_id => user.id, :data_object_id => d.id, :taxon_concept_id => TaxonConcept.find(all_params[:taxon_concept_id]).id})
    udo.save!
    d.new_actions_histories(user, udo, 'users_submitted_text', 'update')
    d
  end

  def self.preview_user_text(all_params)
    do_params = {
      :guid => '',
      :data_type => DataType.find_by_label('Text'),
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
      :vetted_id => Vetted.unknown.id,
      :published => 1, #not sure if this is right
      :visibility_id => Visibility.visible.id #not sure if this is right either
    }

    d = DataObject.new(do_params)
    d.toc_items << TocItem.find(all_params[:data_objects_toc_category][:toc_id])
    d
  end

  def self.create_user_text(all_params,user)
    do_params = {
      :guid => UUID.generate.gsub('-',''),
      :data_type => DataType.find_by_label('Text'),
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
      :vetted_id => Vetted.unknown.id,
      :published => 1, #not sure if this is right
      :visibility_id => Visibility.visible.id #not sure if this is right either
    }

    dato = DataObject.new(do_params)
    dato.toc_items << TocItem.find(all_params[:data_objects_toc_category][:toc_id])
    dato.save!
    dato.curator_activity_flag(user, all_params[:taxon_concept_id])
    raise "Unable to build a UsersDataObject if user is nil" if user.nil?
    raise "Unable to build a UsersDataObject if DataObject is nil" if dato.nil?
    raise "Unable to build a UsersDataObject if taxon_concept_id is missing" if all_params[:taxon_concept_id].blank?
    udo = UsersDataObject.new(:user_id => user.id, :data_object_id => dato.id,
                              :taxon_concept_id => all_params[:taxon_concept_id])
    udo.save!
    dato.new_actions_histories(user, udo, 'users_submitted_text', 'create')
    dato
  end

  def created_by_user?
    user != nil
  end

  def user
    udo = UsersDataObject.find_by_data_object_id(self.id)
    udo.nil? ? nil : User.find(udo.user_id)
  end
  
  def taxon_concept_for_users_text
    unless self.user.nil?
      udo = UsersDataObject.find_by_data_object_id(self.id)
      TaxonConcept.find(udo.taxon_concept_id)
    end
  end

  #----- end of user submitted text --------

  def rate(user,stars)
    rating = UsersDataObjectsRating.find_by_data_object_id_and_user_id(self.id, user.id)
    if rating.nil?
      rating = UsersDataObjectsRating.new({:data_object_id => self.id, :user_id => user.id, :rating => stars})
    else
      rating.rating = stars
    end
    rating.save!

    total = 0
    ratings = UsersDataObjectsRating.find_all_by_data_object_id(self.id)
    ratings.each do |rating|
      total += rating.rating
    end

    self.data_rating = total / ratings.length

    self.save!
  end

  def rating_for_user(user)
    UsersDataObjectsRating.find_by_data_object_id_and_user_id(self.id, user.id)
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
    Agent.find_by_sql(["select a.* from data_objects_harvest_events dohe join harvest_events he on (dohe.harvest_event_id=he.id) join agents_resources ar on (he.resource_id=ar.resource_id) join agents a on (ar.agent_id=a.id) where dohe.data_object_id=? and ar.resource_agent_role_id=3", self.id]).first
  end

  # Gets agents_data_objects, sorted by AgentRole, based on this objects' DataTypes' AgentRole attribution
  # priorities
  #
  # we also fetch agents_data_objects, including (eager loading) Agents by default, assuming we will be using them
  def attributions

    @attributions = Attributions.new(agents_data_objects, data_type)

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
        join   = DataObjectTags.new :data_object => self, :data_object_tag => tag, :user => user
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

  def private_tags user
    DataObjectTags.private_tags.find_all_by_data_object_id_and_user_id id, user.id
  end

  alias user_tags private_tags
  alias users_tags private_tags

  # Names of taxa associated with this image
  def taxa_names_taxon_concept_ids
    taxa=Taxon.find_by_sql("select t.scientific_name as taxon_name, tcn.taxon_concept_id as taxon_concept_id from data_objects_taxa dot join taxa t on (dot.taxon_id=t.id) join taxon_concept_names tcn on (t.name_id=tcn.name_id) where data_object_id=#{self.id} group by t.id")
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
        SELECT tc.* FROM data_objects do
        JOIN data_objects_taxa dot ON (do.id=dot.data_object_id)
        JOIN taxa t ON (dot.taxon_id=t.id)
        JOIN taxon_concept_names tcn ON (t.name_id=tcn.name_id)
        JOIN taxon_concepts tc ON (tcn.taxon_concept_id=tc.id)
        WHERE do.id=? -- DataObject#taxon_concepts
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
      JOIN taxon_concept_names tcn ON (t.name_id=tcn.name_id)
      JOIN hierarchy_entries he ON (tcn.taxon_concept_id=he.taxon_concept_id)
      WHERE do.id=? -- DataObject#hierarchy_entries
    ", self.id])
  end
  
  def curate! action, user = nil
    activity = CuratorActivity.find(action)

    if activity.code[/^approve$/i]
      vet
      new_actions_histories(user, self, 'data_object', 'trusted')
    elsif activity.code[/^disapprove$/i]
      unvet
      new_actions_histories(user, self, 'data_object', 'untrusted')
    elsif activity.code[/^show$/i]
      make_visible
      new_actions_histories(user, self, 'data_object', 'show')
    elsif activity.code[/^hide$/i]
      hide
      new_actions_histories(user, self, 'data_object', 'hide')
    elsif activity.code[/^inappropriate$/i]
      inappropriate
      new_actions_histories(user, self, 'data_object', 'inappropriate')
    else
      raise "Not sure how to #{activity.code} a DataObject"
    end

    # log the fact that the user provided (if any user was passed) curacted this object with the given activity
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => activity if user
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
     if user and user.can_curate_taxon_id? taxon_concept_id
         LastCuratedDate.create(:user_id => user.id, 
           :taxon_concept_id => taxon_concept_id, 
           :last_curated => Time.now)
     end    
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

  def self.cached_images_for_taxon(taxon, options = {})
    options[:user] = User.create_new if options[:user].nil?
    add_cp = join_agents = ''
    if options[:from].nil?
      options[:from] ||= 'top_images'
    else
      nested = true
    end
    # Unpublished images require a few extra bits to the query:
    if nested and not options[:agent].nil?
      add_cp      = ', ar.agent_id agent_id'
      join_agents = self.join_agents_clause(options[:agent])
    end

    # NOTE - left join on the licenses, so they could be NULL.
    # (We don't want to miss images with no license!)
    result=DataObject.find_by_sql([%Q{
      SELECT dato.*, l.description license_text, l.logo_url license_logo, l.source_url license_url,
             (?) taxon_id, t.scientific_name #{add_cp}
        FROM #{options[:from]} ti
          STRAIGHT_JOIN data_objects dato      ON ti.data_object_id = dato.id
          STRAIGHT_JOIN data_objects_taxa dot  ON dato.id = dot.data_object_id
          STRAIGHT_JOIN taxa t                 ON dot.taxon_id = t.id
          #{join_agents}
          LEFT OUTER JOIN licenses l           ON dato.license_id = l.id 
        WHERE ti.hierarchy_entry_id IN (?)
          AND data_type_id IN (?)
          #{DataObject.visibility_clause(options.merge(:taxon => taxon))}
          GROUP BY dato.id
        ORDER BY dato.vetted_id DESC,dato.data_rating DESC               # DataObject.cached_images_for_taxon
      }, taxon.id, taxon.hierarchy_entries.collect {|he| he.id }, DataType.image_type_ids])                            
    # Run a second query if we need unpublished or invisible images (but not if we're already doing it!!!):
    if not nested and ((not options[:agent].nil?) or options[:user].is_curator? or options[:user].is_admin?)
      result += DataObject.cached_images_for_taxon(taxon, options.merge(:from => 'top_unpublished_images'))
    end
    return result                            
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
      klass = (type == :text && options[:toc_id].nil?) ? TocItem : DataObject
      results = klass.find_by_sql(DataObject.build_query(taxon, type, options))
    end

    # In order to display a warning about pages that include unvetted material, we check now, while the
    # information is most readily available (data objects are the only things that can be unvetted, and only
    # if we have to check permissions), and then flag the taxon_concept model if anything is non-trusted.
    taxon.includes_unvetted = true if results.detect {|d| d.vetted_id != Vetted.trusted.id }

    # Content Partners' query included ALL invisible, untrusted and unknown items... not JUST THEIRS.  We
    # now need to exclude those items that they did not contribute:
    if options[:agent]
      results.delete_if do |dato|
        dato.visibility_id == Visibility.preview.id and not dato['agent_id'].nil? and
          dato['agent_id'].to_i != options[:agent].id
      end
    end

    return results

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
    sort         = 'published, vetted_id DESC, data_rating DESC' # unpublished first, then by data_rating.

    query_string = %Q{
(SELECT DISTINCT dt.label media_type, dato.*, t.scientific_name, tcn.taxon_concept_id taxon_id,
       l.description license_text, l.logo_url license_logo, l.source_url license_url #{add_toc} #{add_cp}
  FROM taxon_concept_names tcn
    STRAIGHT_JOIN taxa t                ON (tcn.name_id = t.name_id)
    STRAIGHT_JOIN data_objects_taxa dot ON (t.id = dot.taxon_id)
    STRAIGHT_JOIN data_objects dato     ON (dot.data_object_id = dato.id)
    STRAIGHT_JOIN data_types dt         ON (dato.data_type_id = dt.id)
    #{join_agents} #{join_toc}
    LEFT OUTER JOIN licenses l       ON (dato.license_id = l.id)
  WHERE tcn.taxon_concept_id = :taxon_concept_id
    AND data_type_id IN (:data_type_ids)
    #{DataObject.visibility_clause(options.merge(:taxon => taxon))}
    #{where_toc})
UNION
(SELECT dt.label media_type, dato.*, '' scientific_name, taxon_concept_id taxon_id,l.description license_text, l.logo_url license_logo, l.source_url license_url #{add_toc} #{add_cp}
FROM data_objects dato
JOIN #{ UsersDataObject.full_table_name } udo ON (dato.id=udo.data_object_id)
STRAIGHT_JOIN data_types dt ON (dato.data_type_id = dt.id)
#{join_agents} #{join_toc}
LEFT OUTER JOIN licenses l ON (dato.license_id = l.id)
WHERE
udo.taxon_concept_id=:taxon_concept_id
AND data_type_id IN (:data_type_ids)
#{DataObject.visibility_clause(options.merge(:taxon => taxon))}
    #{where_toc})
  ORDER BY #{sort} # DataObject.for_taxon
    }

    ActiveRecord::Base.sanitize_sql([query_string, {:taxon_concept_id => taxon.id, :data_type_ids => DataObject.get_type_ids(type)}])
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

private

  def make_visible user = nil
    self.vetted_by = user if user
    update_attributes({:visibility_id => Visibility.visible.id, :curated => true})
  end
  def hide user = nil
    self.vetted_by = user if user
    update_attributes({:visibility_id => Visibility.invisible.id, :curated => true})
  end
  def vet user = nil
    self.vetted_by = user if user
    update_attributes({:vetted_id => Vetted.trusted.id, :curated => true})
  end
  def unvet user = nil
    self.vetted_by = user if user
    update_attributes({:vetted_id => Vetted.untrusted.id, :curated => true})
  end
  def inappropriate user = nil
    self.vetted_by = user if user
    update_attributes({:visibility_id => Visibility.inappropriate.id, :curated => true})
  end
  
  def self.join_agents_clause(agent)
    data_supplier_id = ResourceAgentRole.content_partner_upload_role.id
    return %Q{LEFT JOIN (agents_resources ar
              STRAIGHT_JOIN harvest_events he ON ar.resource_id = he.resource_id
                  AND ar.resource_agent_role_id = #{data_supplier_id}
              STRAIGHT_JOIN data_objects_harvest_events dohe ON he.id = dohe.harvest_event_id)
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

