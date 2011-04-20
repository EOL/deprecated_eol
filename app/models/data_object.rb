require 'set'
require 'uuid'
require 'erb'

# Represents any kind of object imported from a ContentPartner, eg. an image, article, video, etc.  This is one
# of our primary models, and an awful lot of work occurs here.
class DataObject < SpeciesSchemaModel

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
  has_many :agents_data_objects
  has_many :data_objects_hierarchy_entries
  has_many :comments, :as => :parent
  has_many :data_objects_harvest_events
  has_many :harvest_events, :through => :data_objects_harvest_events
  has_many :data_object_tags, :class_name => DataObjectTags.to_s
  has_many :tags, :class_name => DataObjectTag.to_s, :through => :data_object_tags, :source => :data_object_tag
  has_many :data_objects_table_of_contents
  has_many :data_objects_untrust_reasons
  has_many :untrust_reasons, :through => :data_objects_untrust_reasons
  has_many :data_objects_info_items
  has_many :info_items, :through => :data_objects_info_items
  # has_many :user_ignored_data_objects
  has_many :users_data_objects
  has_many :users_data_objects_ratings, :foreign_key => 'data_object_guid', :primary_key => :guid
  has_many :all_comments, :class_name => Comment.to_s, :foreign_key => 'parent_id', :finder_sql => 'SELECT c.* FROM #{Comment.full_table_name} c JOIN #{DataObject.full_table_name} do ON (c.parent_id = do.id) WHERE do.guid=\'#{guid}\''
  # has_many :all_comments, :class_name => Comment.to_s, :through => :all_versions, :source => :comments, :primary_key => :guid
  # # the select_with_include library doesn't allow to grab do.* one time, then do.id later on - but this would be a neat method,
  # has_many :all_versions, :class_name => DataObject.to_s, :foreign_key => :guid, :primary_key => :guid, :select => 'id, guid'

  has_and_belongs_to_many :hierarchy_entries
  has_and_belongs_to_many :audiences
  has_and_belongs_to_many :refs
  has_and_belongs_to_many :published_refs, :class_name => Ref.to_s, :join_table => 'data_objects_refs',
    :association_foreign_key => 'ref_id', :conditions => 'published=1 AND visibility_id=#{Visibility.visible.id}'

  has_and_belongs_to_many :agents
  has_and_belongs_to_many :toc_items, :join_table => 'data_objects_table_of_contents', :association_foreign_key => 'toc_id'
  has_and_belongs_to_many :taxon_concepts

  attr_accessor :vetted_by # who changed the state of this object? (not persisted on DataObject but required by observer)

  named_scope :visible, lambda { { :conditions => { :visibility_id => Visibility.visible.id } }}
  named_scope :preview, lambda { { :conditions => { :visibility_id => Visibility.preview.id } }}

  define_core_relationships :select => {
      :data_objects => '*',
      :agents => [:full_name, :acronym, :display_name, :homepage, :username, :logo_cache_url],
      :agents_data_objects => :view_order,
      :names => :string,
      :hierarchy_entries => [ :published, :visibility_id, :taxon_concept_id ],
      :languages => :iso_639_1,
      :table_of_contents => :label,
      :info_items => [ :label, :schema_value ],
      :agent_roles => :label,
      :data_types => [ :label, :schema_value ],
      :mime_types => :label,
      :vetted => [ :label, :view_order ],
      :table_of_contents => '*',
      :licenses => '*' },
    :include => [:data_type, :mime_type, :language, :license, :vetted, :visibility, {:info_items => :toc_item},
      {:hierarchy_entries => [:name, { :hierarchy => :agent }] }, {:agents_data_objects => [ { :agent => :user }, :agent_role]}]

  def self.sort_by_rating(data_objects)
    data_objects.sort_by do |obj|
      toc_view_order = (!obj.is_text? || obj.info_items.blank? || obj.info_items[0].toc_item.blank?) ? 0 : obj.info_items[0].toc_item.view_order
      vetted_view_order = obj.vetted.blank? ? 0 : obj.vetted.view_order
      visibility_view_order = 1
      visibility_view_order = 2 if obj.visibility_id == Visibility.preview.id
      inverted_rating = obj.data_rating * -1
      inverted_id = obj.id * -1
      [obj.data_type_id,
       toc_view_order,
       visibility_view_order,
       vetted_view_order,
       inverted_rating,
       inverted_id]
    end
  end

  # TODO - this smells like a good place to use a Strategy pattern.  The user can have certain behaviour based
  # on their access.
  def self.filter_list_for_user(data_objects, options={})
    return [] if data_objects.blank?
    visibility_ids = [Visibility.visible.id]
    vetted_ids = [Vetted.trusted.id, Vetted.unknown.id, Vetted.untrusted.id]
    show_preview = false

    # Show all vetted states unless there is a user that DOES NOT want to see vetted content
    # AND is not a curator of this clade (curators always see all content in their clade)
    # AND is not an admin (admins always see all content)
    if options[:user]
      # admins see everything
      if options[:user].is_admin?
        vetted_ids += [Vetted.untrusted.id, Vetted.unknown.id]
        visibility_ids = Visibility.all_ids.dup
        show_preview = true
      # curators see invisible objects
      elsif options[:user].is_curator? && options[:user].can_curate?(options[:taxon])
        visibility_ids << Visibility.invisible.id
      end
      # the only scenario to see ONLY TRUSTED objects
      if options[:user].vetted == true && !options[:user].is_admin?
        vetted_ids = [Vetted.trusted.id]
      end
    end

    if options[:toc_id] == TocItem.wikipedia
      show_preview = true
    end

    # removing from the array the ones not mathching our criteria
    data_objects.compact.select do |d|
      # partners see all their PREVIEW or PUBLISHED objects
      if options[:agent] && d.data_supplier_agent.id == options[:agent].id
        if (d.visibility_id == Visibility.preview.id) || d.published == true
          true
        end
      # user can see preview objects
      elsif show_preview && d.visibility_id == Visibility.preview.id
        true
      # otherwise object must be PUBLISHED and in the vetted and visibility selection
      elsif d.published == true && vetted_ids.include?(d.vetted_id) &&
        visibility_ids.include?(d.visibility_id)
        true
      else
        false
      end
    end
  end

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

    data_objects = DataObject.find_by_sql("
      SELECT do.id, do.guid, do.created_at
      FROM feed_data_objects fdo
      JOIN #{DataObject.full_table_name} do ON (fdo.data_object_id=do.id)
      WHERE fdo.taxon_concept_id IN (#{lookup_ids.join(',')})
      AND do.published=1
      AND do.data_type_id IN (#{data_type_ids.join(',')})
      AND do.created_at IS NOT NULL
      AND do.created_at != '0000-00-00 00:00:00'").uniq
    data_objects.sort_by{ |d| d.created_at }
    DataObject.core_relationships.find_all_by_id(data_objects.collect{ |d| d.id })
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
      :identifier => '',
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
        if reference.strip != ''
          d.refs << Ref.new(:full_reference => reference, :user_submitted => true, :published => 1, :visibility => Visibility.visible)
        end
      end
    end

    d.save!
    dato.published = false
    dato.save!

    comments_from_old_dato = Comment.find(:all, :conditions => {:parent_id => dato.id, :parent_type => 'DataObject'})
    comments_from_old_dato.map { |c| c.update_attribute :parent_id, d.id  }

    d.curator_activity_flag(user, all_params[:taxon_concept_id])

    tc = TaxonConcept.find(all_params[:taxon_concept_id])
    udo = UsersDataObject.create(:user => user, :data_object => d, :taxon_concept => tc)
    d.users_data_objects << udo
    user.track_curator_activity(udo, 'users_submitted_text', 'update')
    d
  end

  def self.preview_user_text(all_params, user)
    taxon_concept = TaxonConcept.find(all_params[:taxon_concept_id])

    do_params = {
      :guid => '',
      :identifier => '',
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
        if reference.strip != ''
          d.published_refs << Ref.new(:full_reference => reference, :user_submitted => true, :published => 1, :visibility => Visibility.visible)
        end
      end
    end

    # TODO - references aren't shown in the preview, because we would have to "fake" them, and we can't effectively.
    d.users_data_objects = [UsersDataObject.new(:data_object => d, :taxon_concept => taxon_concept, :user => user)]
    d
  end

  def self.create_user_text(all_params,user)
    taxon_concept = TaxonConcept.find(all_params[:taxon_concept_id])

    if defined?(PhusionPassenger)
      UUID.state_file(0664) # Makes the file writable, which we seem to need to do with Passenger...
    end

    do_params = {
      :guid => UUID.generate.gsub('-',''),
      :identifier => '',
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
        if reference.strip != ''
          dato.refs << Ref.new(:full_reference => reference, :user_submitted => true, :published => 1, :visibility => Visibility.visible)
        end
      end
    end

    dato.save!
    dato.curator_activity_flag(user, all_params[:taxon_concept_id])
    raise "Unable to build a UsersDataObject if user is nil" if user.nil?
    raise "Unable to build a UsersDataObject if DataObject is nil" if dato.nil?
    raise "Unable to build a UsersDataObject if taxon_concept_id is missing" if all_params[:taxon_concept_id].blank?
    udo = UsersDataObject.create(:user => user, :data_object => dato,
                              :taxon_concept => taxon_concept)
    dato.users_data_objects << udo
    user.track_curator_activity(udo, 'users_submitted_text', 'create')

    # this will give it the hash elements it needs for attributions
    dato
  end

  def created_by_user?
    user != nil
  end

  def user
    @udo ||= UsersDataObject.find_by_data_object_id(id)
    @udo_user ||= @udo.nil? ? nil : User.find(@udo.user_id)
  end

  def taxon_concept_for_users_text
    unless user.nil?
      udo = UsersDataObject.find_by_data_object_id(id)
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

  def rate(user, new_rating)
    existing_ratings = UsersDataObjectsRating.find_all_by_data_object_guid(guid)
    users_current_ratings, other_ratings = existing_ratings.partition { |r| r.user_id == user.id }

    if users_current_ratings.blank?
      UsersDataObjectsRating.create(:data_object_guid => guid, :user_id => user.id, :rating => new_rating)
    elsif users_current_ratings[0].rating != new_rating
      users_current_ratings[0].rating = new_rating
      users_current_ratings[0].save!
    end

    self.data_rating = (other_ratings.inject(0) { |sum, r| sum + r.rating } + new_rating).to_f / (other_ratings.size + 1)
    self.save!
  end

  def recalculate_rating
    ratings = UsersDataObjectsRating.find_all_by_data_object_guid(guid)
    self.data_rating = ratings.blank? ? 2.5 : ratings.inject(0) { |sum, r| sum + r.rating }.to_f / ratings.size
    self.save!
  end

  def rating_for_user(user)
    users_data_objects_ratings.detect{ |udor| udor.user_id == user.id }
  end

  # Add a comment to this data object
  def comment(user, body)
    comment = comments.create :user_id => user.id, :body => body
    user.comments.reload # be friendly - update the user's comments automatically
    return comment
  end

  # Test whether a user has curator rights on this object
  def is_curatable_by? user
    # normally at this point, taxon_concepts shouldn't be blank
    # caused by some data problem, this hack is needed to curate object(s) like: e.g. http://www.eol.org/pages/913235?text_id=7655133
    if !taxon_concepts.blank?
      taxon_concepts.collect {|tc| tc.is_curatable_by?(user) }.include?(true)
    else
      return (user.nil? ? false : true)
    end
  end

  # Find the Agent (only one) that supplied this data object to EOL.
  def data_supplier_agent
    # this is a bit of a shortcut = the hierarchy's agent should be the same as the agent
    # that contributed the resource. DataObject should only live in a single hierarchy
    @data_supplier_agent ||= hierarchy_entries[0].hierarchy.agent rescue nil
  end

  def citable_data_supplier
    return nil if data_supplier_agent.blank?
    EOL::Citable.new( :agent_id => data_supplier_agent.id,
                                  :link_to_url => (data_supplier_agent.homepage?)? data_supplier_agent.homepage : "",
                                  :display_string => (data_supplier_agent.full_name?)? data_supplier_agent.full_name : "",
                                  :logo_cache_url => (data_supplier_agent.logo_cache_url?)? data_supplier_agent.logo_cache_url : "",
                                  :type => 'Supplier')
  end

  def citable_entities
    citables = []
    agents_data_objects.each do |ado|
      if ado.agent_role && ado.agent
        citables << ado.agent.citable(ado.agent_role.label)
      end
    end

    unless data_supplier_agent.blank?
      citables << citable_data_supplier
    end

    unless rights_statement.blank?
      citables << EOL::Citable.new( :display_string => rights_statement,
                                    :type => 'Rights')
    end

    unless rights_holder.blank?
      citables << EOL::Citable.new( :display_string => rights_holder,
                                    :type => 'Rights Holder')
    end

    unless license.blank?
      citables << EOL::Citable.new( :link_to_url => license.source_url,
                                    :display_string => license.description,
                                    :logo_path => license.logo_url,
                                    :type => 'License')
    end

    unless location.blank?
      citables << EOL::Citable.new( :display_string => location,
                                    :type => 'Location')
    end

    unless source_url.blank?
      citables << EOL::Citable.new( :link_to_url => source_url,
                                    :display_string => 'View original data object',
                                    :type => 'Source URL')
    end

    unless created_at.blank? || created_at == '0000-00-00 00:00:00'
      citables << EOL::Citable.new( :display_string => created_at.strftime("%B %d, %Y"),
                                    :type => 'Indexed')
    end

    unless bibliographic_citation.blank?
      citables << EOL::Citable.new( :display_string => bibliographic_citation,
                                    :type => 'Citation')
    end

    citables
  end

  # Find all of the authors associated with this data object, including those that we dynamically add elsewhere
  def authors
    default_authors = agents_data_objects.select{ |ado| ado.agent_role_id == AgentRole.author.id }.collect {|ado| ado.agent }.compact
    @fake_authors.nil? ? default_authors : default_authors + @fake_authors
  end

  # Find all of the photographers associated with this data object, including those that we dynamically add elsewhere
  def photographers
    agents_data_objects.agents_data_objects.select{ |ado| ado.agent_role_id == AgentRole.photographer.id }.collect {|ado| ado.agent }.compact
  end

  # Add an author to this data object that isn't in the database.
  def fake_author(author_options)
    @fake_authors ||= []
    @fake_authors << Agent.new(author_options)
  end

  # Find Agents associated with this data object as sources.  If there are none, find authors.
  def sources
    list = agents_data_objects.select{ |ado| ado.agent_role_id == AgentRole.source.id }.collect {|ado| ado.agent }.compact
    return list unless list.blank?
    # I ended up with empty lists in cases where I thought I shouldn't, so tried to defer to authors for those:
    return authors
  end

  def revisions
    DataObject.find_all_by_guid(guid)
  end

  def visible_comments(user = nil)
    return all_comments if (not user.nil?) and user.is_moderator?
    all_comments.find_all {|c| c.visible? }
  end

  def image?
    return DataType.image_type_ids.include?(data_type_id)
  end
  alias is_image? image?

  def map?
    return DataType.map_type_ids.include?(data_type_id)
  end

  def text?
    return DataType.text_type_ids.include?(data_type_id)
  end
  alias is_text? text?

  def video?
    return DataType.video_type_ids.include?(data_type_id)
  end
  alias is_video? video?

  def iucn?
    return data_type_id == DataType.iucn.id
  end
  alias is_iucn? iucn?


  # Convenience.  TODO - Stop calling this.  Use ContentServer directly.
  def self.cache_path(cache_url, subdir)
    ContentServer.cache_path(cache_url, subdir)
  end

  def self.image_cache_path(cache_url, size = :large, subdir = $CONTENT_SERVER_CONTENT_PATH)
    size = size ? "_" + size.to_s : ''
    cache_path(cache_url, subdir) + "#{size}.#{$SPECIES_IMAGE_FORMAT}"
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

  def original_image
    thumb_or_object(nil)
  end

  def video_url
    if !object_cache_url.blank? && !object_url.blank?
      filename_extension = File.extname(object_url)
      return ContentServer.cache_path(object_cache_url) + filename_extension
    elsif data_type.label == 'Flash'
      return has_object_cache_url? ? ContentServer.cache_path(object_cache_url) + '.flv' : ''
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

  # This allows multiple values, eg: 'red, blue' or 'red blue'
  def tag(key, values, user)
    raise "You must be logged in to add tags."[] unless user
    key = 'none' if key.blank?
    return unless values
    values = DataObjectTag.clean_values(values)
    values.each do |value|
      tag = DataObjectTag.find_or_create_by_key_and_value key.to_s, value.to_s
      if user.tags_are_public_for_data_object?(self)
        tag.update_attributes!(:is_public => true)
      end
      begin
        DataObjectTags.create :data_object => self, :data_object_guid => guid, :data_object_tag => tag, :user => user
      rescue
        raise FailedToCreateTag.new("Failed to add #{key}:#{value} tag")
      end
    end
    tags.reset
    user.tags.reset
  end

  def public_tags
    DataObjectTags.public_tags_for_data_object self
  end

  # Names of taxa associated with this image
  def taxa_names_taxon_concept_ids
    results = SpeciesSchemaModel.connection.execute("SELECT n.string, he.taxon_concept_id
        FROM data_objects_hierarchy_entries dohe
        JOIN hierarchy_entries he ON (dohe.hierarchy_entry_id=he.id)
        JOIN names n ON (he.name_id=n.id)
        WHERE dohe.data_object_id = #{id}").all_hashes

    results.map{|r| {:taxon_name => r['string'], :taxon_concept_id => r['taxon_concept_id']}}
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

  # TODO: Make documentation rdoc compatible
  # Return taxon concepts directly associated with this Dato.
  # default - returns all taxon concepts
  # options:
  # :published -> :strict - return only published taxon concepts
  # :published -> :preferred - same as above, but returns unpublished taxon concepts if no published ones are found
  def get_taxon_concepts(opts = {})
    return @taxon_concepts if @taxon_concepts
    if created_by_user?
      @taxon_concepts = [taxon_concept_for_users_text]
    else
      query = "
        SELECT distinct tc.*
        FROM hierarchy_entries he
        JOIN taxon_concepts tc on he.taxon_concept_id = tc.id
        JOIN data_objects_hierarchy_entries dh on dh.hierarchy_entry_id = he.id
        WHERE dh.data_object_id = ?
        ORDER BY tc.id -- DataObject#taxon_concepts(true)"
      @taxon_concepts = TaxonConcept.find_by_sql([query, id])
    end
    tc, tc_with_supercedure = @taxon_concepts.partition {|item| item.supercedure_id == 0}
    # find is aliased to recursive method to find taxon_concept without supercedure_id
    tc += tc_with_supercedure.map {|item| TaxonConcept.find(item.id)}.compact
    if opts[:published]
      published, unpublished = tc.partition {|item| item.published?}
      @taxon_concepts = (!published.empty? || opts[:published] == :strict) ? published : unpublished
    else
      @taxon_concepts = tc
    end
  end

  def linked_taxon_concept
    if created_by_user?
      @taxon_concept ||= taxon_concept_for_users_text
    else
      @taxon_concept ||= TaxonConcept.find_by_sql(["
        SELECT tc.*
        FROM data_objects_hierarchy_entries dohe
        JOIN hierarchy_entries he ON (dohe.hierarchy_entry_id=he.id)
        JOIN taxon_concepts tc ON (he.taxon_concept_id=tc.id)
        WHERE dohe.data_object_id=?
        ORDER BY tc.id -- DataObject#taxon_concepts
      ", id])[0]
    end
  end

  def curate(user, opts)
    vetted_id = opts[:vetted_id]
    visibility_id = opts[:visibility_id]

    raise "Curator should supply at least visibility or vetted information" unless (vetted_id || visibility_id)

    if vetted_id
      opts[:comment] = opts[:comment].blank? ? nil : comment(user, opts[:comment])
      case vetted_id.to_i
      when Vetted.untrusted.id
        untrust(user, opts)
      when Vetted.trusted.id
        trust(user, opts)
      when Vetted.unknown.id
        unreviewed(user)
      else
        raise "Cannot set data object vetted id to #{vetted_id}"
      end

    end

    if visibility_id
      case visibility_id.to_i
      when Visibility.visible.id
        show(user)
      when Visibility.invisible.id
        hide(user)
      when Visibility.inappropriate.id
        inappropriate(user)
      else
        raise "Cannot set data object visibility id to #{visibility_id}"
      end
    end
    curator_activity_flag(user)
    update_solr_index(opts)
  end

  def update_solr_index(options)
    return false if options[:vetted_id].blank? && options[:visibility_id].blank?
    solr_connection = SolrAPI.new($SOLR_SERVER_DATA_OBJECTS)
    begin
      # query Solr for the index record for this data object
      response = solr_connection.query_lucene("data_object_id:#{id}")
      data_object_hash = response['response']['docs'][0]
      return false unless data_object_hash
      modified_object_hash = data_object_hash.dup
      modified_object_hash['vetted_id'] = [options[:vetted_id]] unless options[:vetted_id].blank?
      modified_object_hash['visibility_id'] = [options[:visibility_id]] unless options[:visibility_id].blank?
      # if some of the values have changed, post the updated record to Solr
      if data_object_hash != modified_object_hash
        solr_connection.create(modified_object_hash)
      end
    rescue
    end
  end

  def curated?
    curated
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

  def in_wikipedia?
    toc_items.include?(TocItem.wikipedia)
  end

  def publish_wikipedia_article
    return false unless in_wikipedia?
    return false unless visibility_id == Visibility.preview.id

    SpeciesSchemaModel.connection.execute("UPDATE data_objects SET published=0 WHERE guid='#{guid}'");
    reload
    self.visibility_id = Visibility.visible.id
    self.vetted_id = Vetted.trusted.id
    self.published = 1
    self.save!
  end

  def curator_activity_flag(user, taxon_concept_id = nil)
    unless taxon_concept_id
      tc = taxon_concepts(:published => :preferred).first
      taxon_concept_id = tc.id if tc
    end
    return if (taxon_concept_id == nil || taxon_concept_id == 0)
    if user and user.can_curate_taxon_concept_id? taxon_concept_id
      LastCuratedDate.create(:user_id => user.id,
        :taxon_concept_id => taxon_concept_id,
        :last_curated => Time.now)
    end
  end

  def visible_references(options = {})
    @all_refs ||= refs.delete_if {|r| r.published != 1 || r.visibility_id != Visibility.visible.id}
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

    return_objects = []
    data_object_tags.each do |dot|
      if obj = DataObject.find_by_guid_and_published_and_visibility_id(dot.data_object_guid, 1, Visibility.visible.id, :order => 'id desc')
        return_objects << obj
      end
    end
    return return_objects
  end

  def self.images_for_taxon_concept(taxon_concept, options = {})
    options[:user] ||= User.create_new
    if options[:filter_by_hierarchy] && !options[:hierarchy].nil?
      options[:filter_hierarchy] = options[:hierarchy]
    end
    # the user/agent has the ability to see some unpublished images, so create a UNION
    show_unpublished = (options[:agent] || options[:user].is_curator? || options[:user].is_admin?)

    if options[:filter_hierarchy]
      # strict lookup
      if entry_in_hierarchy = taxon_concept.entry(options[:filter_hierarchy], true)
        HierarchyEntry.preload_associations(entry_in_hierarchy,
          [ :top_images => :data_object ],
          :select => { :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating ] } )
        image_data_objects = entry_in_hierarchy.top_images.collect{ |ti| ti.data_object }
        if show_unpublished
          HierarchyEntry.preload_associations(entry_in_hierarchy,
            [ :top_unpublished_images => :data_object ],
            :select => { :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating ] } )
          image_data_objects += entry_in_hierarchy.top_unpublished_images.collect{ |ti| ti.data_object }
        end
      end
    else
      image_data_objects = taxon_concept.top_concept_images.collect{ |tci| tci.data_object }
      # this is a content partner, so we'll want o preload image contributors to prevent
      # a bunch of queries later on in filter_list_for_user
      if options[:agent]
        DataObject.preload_associations(image_data_objects,
          [ :hierarchy_entries => { :hierarchy => :agent } ],
          :select => {
            :hierarchy_entries => :hierarchy_id,
            :agents => [:id, :full_name, :acronym, :display_name, :homepage, :username, :logo_cache_url] } )
      end
      if show_unpublished
        TaxonConcept.preload_associations(taxon_concept,
          [ :top_unpublished_concept_images => { :data_object => { :hierarchy_entries => { :hierarchy => :agent } } } ],
          :select => {
            :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating ],
            :hierarchy_entries => :hierarchy_id,
            :agents => [:id, :full_name, :acronym, :display_name, :homepage, :username, :logo_cache_url] } )
        image_data_objects += taxon_concept.top_unpublished_concept_images.collect{ |tci| tci.data_object }
      end
    end

    # remove anything this agent/user should not have access to
    image_data_objects = DataObject.filter_list_for_user(image_data_objects, options)
    # make the list unique by DataObject.guid
    unique_image_objects = []
    used_guids = {}
    image_data_objects.each do |r|
      unique_image_objects << r if used_guids[r.guid].blank?
      used_guids[r.guid] = true
    end

    return [] if unique_image_objects.empty?

    # sort the remainder by our rating criteria
    unique_image_objects = DataObject.sort_by_rating(unique_image_objects)

    # get the rest of the metadata for the selected page
    image_page  = (options[:image_page] ||= 1).to_i
    start       = $MAX_IMAGES_PER_PAGE * (image_page - 1)
    last        = start + $MAX_IMAGES_PER_PAGE - 1

    objects_with_metadata = eager_load_image_metadata(unique_image_objects[start..last].collect {|r| r.id})
    unique_image_objects[start..last] = objects_with_metadata unless objects_with_metadata.blank?
    if options[:user] && options[:user].is_curator? && options[:user].can_curate?(taxon_concept)
      DataObject.preload_associations(unique_image_objects[start..last], :users_data_objects_ratings, :conditions => "users_data_objects_ratings.user_id=#{options[:user].id}")
    end
    return unique_image_objects
  end

  def self.eager_load_image_metadata(data_object_ids)
    return nil if data_object_ids.blank?
    add_include = [ :all_comments ]
    add_select = { :comments => [ :parent_id, :visible_at ] }
    except = [ :info_items ]
    objects = DataObject.core_relationships(:except => except, :add_include => add_include, :add_select => add_select).find_all_by_id(data_object_ids)
    DataObject.sort_by_rating(objects)
  end

  def self.latest_published_version_of(data_object_id)
    obj = DataObject.find_by_sql("SELECT do.* FROM data_objects do_old JOIN data_objects do ON (do_old.guid=do.guid) WHERE do_old.id=#{data_object_id} AND do.published=1 ORDER BY id desc LIMIT 1")
    return nil if obj.blank?
    return obj[0]
  end
  
  def self.latest_published_version_ids_of_do_ids(data_object_ids)
    latest_published_version_ids = DataObject.find_by_sql("SELECT do.id FROM data_objects do_old JOIN data_objects do ON (do_old.guid=do.guid) WHERE do.id IN (#{data_object_ids.collect{|doi| doi}.join(', ')}) AND do.published=1")
    latest_published_version_ids.collect!{|data_object| (data_object.id)}.uniq!
    latest_published_version_ids
  end
  
  def self.latest_published_version_of_guid(guid, options={})
    options[:return_only_id] ||= false
    select = (options[:return_only_id]) ? 'id' : '*'
    obj = DataObject.find_by_sql("SELECT #{select} FROM data_objects WHERE guid='#{guid}' AND published=1 ORDER BY id desc LIMIT 1")
    return nil if obj.blank?
    return obj[0]
  end


  def self.tc_ids_from_do_ids(obj_ids)
    obj_tc_id = {} #same Hash.new
    if(obj_ids.length > 0) then
      sql = "SELECT dotc.taxon_concept_id tc_id , do.data_type_id, do.id do_id
      FROM data_objects_taxon_concepts dotc
      JOIN data_objects do ON dotc.data_object_id = do.id
      JOIN taxon_concepts tc ON dotc.taxon_concept_id = tc.id
      WHERE tc.published AND dotc.data_object_id IN (#{obj_ids.join(',')})"
      rset = DataObject.find_by_sql([sql])
      rset.each do |post|
        obj_tc_id["#{post.do_id}"] = post.tc_id
        if(post.data_type_id == 3)then obj_tc_id["datatype#{post.do_id}"] = "text"
                                  else obj_tc_id["datatype#{post.do_id}"] = "image"
        end
      end
    end
    return obj_tc_id
  end

  # using object.untrust_reasons.include? was firing off a query every time. This is faster
  def untrust_reasons_include?(untrust_reason)
    @untrust_reasons_cached ||= untrust_reasons
    return true if @untrust_reasons_cached.index(untrust_reason)
    return false
  end


  def self.generate_dataobject_stats(harvest_event_id)
    ids = connection.select_values("SELECT do.id
      FROM data_objects_harvest_events dohe
      JOIN data_objects do ON dohe.data_object_id = do.id
      WHERE dohe.harvest_event_id = #{harvest_event_id}")
    data_objects = DataObject.find_all_by_id(ids, :include => [ :vetted, :data_type ])

    # to get total_taxa count
    query = "Select count(distinct he.taxon_concept_id) taxa_count
    From harvest_events_hierarchy_entries hehe
    Join hierarchy_entries he ON hehe.hierarchy_entry_id = he.id
    Join taxon_concepts tc ON he.taxon_concept_id = tc.id
    where hehe.harvest_event_id = #{harvest_event_id}
    and tc.supercedure_id=0 and tc.vetted_id != #{Vetted.untrusted.id}
    and tc.published=1"

    total_taxa = connection.select_values(query)[0]
    [data_objects, total_taxa]
  end

  def show(user)
    vetted_by = user
    update_attributes({:visibility_id => Visibility.visible.id, :curated => true})
    user.track_curator_activity(self, 'data_object', 'show')
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.show
  end

  def hide(user)
    vetted_by = user
    update_attributes({:visibility_id => Visibility.invisible.id, :curated => true})
    user.track_curator_activity(self, 'data_object', 'hide')
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.hide
  end

  def inappropriate(user)
    vetted_by = user
    update_attributes({:visibility_id => Visibility.inappropriate.id, :curated => true})
    user.track_curator_activity(self, 'data_object', 'inappropriate')
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.inappropriate
  end

  def flickr_photo_id
    if matches = source_url.match(/flickr\.com\/photos\/.*?\/([0-9]+)\//)
      return matches[1]
    end
    nil
  end

  def published_entries
    hierarchy_entries.select{ |he| he.published == 1 && he.visibility_id == Visibility.visible.id }
  end

  def first_concept_name
    sorted_entries = HierarchyEntry.sort_by_vetted(hierarchy_entries)
    sorted_entries[0].name.string rescue nil
  end

  def first_taxon_concept
    sorted_entries = HierarchyEntry.sort_by_vetted(hierarchy_entries)
    sorted_entries[0].taxon_concept rescue nil
  end

  def first_hierarchy_entry
    sorted_entries = HierarchyEntry.sort_by_vetted(hierarchy_entries)
    sorted_entries[0] rescue nil
  end


  def rating_from_user(u)
    ratings_from_user = users_data_objects_ratings.select{ |udor| udor.user_id == u.id }
    return ratings_from_user[0] unless ratings_from_user.blank?
  end

  def short_title
    return object_title unless object_title.blank?
    # TODO - ideally, we should extract some of the logic from data_objects/show to make this "Image of Procyon Lotor".
    return data_type.label if description.blank?
    st = description.gsub(/\n.*$/, '')
    st.truncate(32)
  end

private

  def trust(user, opts = {})
    update_attributes({:vetted_id => Vetted.trusted.id, :curated => true})
    DataObjectsUntrustReason.destroy_all(:data_object_id => id)
    user.track_curator_activity(self, 'data_object', 'trusted', :comment => opts[:comment], :taxon_concept_id => opts[:taxon_concept_id])
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.approve
  end

  def untrust(user, opts = {})
    untrust_reason_ids = opts[:untrust_reason_ids].is_a?(Array) ? opts[:untrust_reason_ids] : []
    untrust_reasons_comment = opts[:untrust_reasons_comment]
    update_attributes({:vetted_id => Vetted.untrusted.id, :curated => true})
    DataObjectsUntrustReason.destroy_all(:data_object_id => id)

    these_untrust_reasons = []
    if untrust_reason_ids
      untrust_reason_ids.each do |untrust_reason_id|
        ur = UntrustReason.find(untrust_reason_id)
        these_untrust_reasons << ur
        untrust_reasons << ur
      end
    end
    unless untrust_reasons_comment.blank?
      comment(user, untrust_reasons_comment)
    end
    user.track_curator_activity(self, 'data_object', 'untrusted', :comment => opts[:comment], :untrust_reasons => these_untrust_reasons, :taxon_concept_id => opts[:taxon_concept_id])
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.disapprove
  end

  def unreviewed(user, opts = {})
    update_attributes({:vetted_id => Vetted.unknown.id, :curated => true})
    DataObjectsUntrustReason.destroy_all(:data_object_id => id)
    user.track_curator_activity(self, 'data_object', 'unreviewed', :comment => opts[:comment], :taxon_concept_id => opts[:taxon_concept_id])
    CuratorDataObjectLog.create :data_object => self, :user => user, :curator_activity => CuratorActivity.unreviewed
  end
end
