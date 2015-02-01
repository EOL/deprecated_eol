require 'set'
require 'uuid'
require 'erb'
require 'eol/activity_loggable'

# Represents any kind of object imported from a ContentPartner, eg. an image, article, video, etc.  This is one
# of our primary models, and an awful lot of work occurs here.
class DataObject < ActiveRecord::Base

  MAXIMUM_RATING = 5.0
  MINIMUM_RATING = 0.5

  include EOL::ActivityLoggable
  include IdentityCache
  include Refable

  belongs_to :data_type
  belongs_to :data_subtype, class_name: DataType.to_s, foreign_key: :data_subtype_id
  belongs_to :language
  belongs_to :license
  belongs_to :mime_type

  # this is the DataObjectTranslation record which links this translated object
  # to the original data object
  has_one :data_object_translation
  # TODO - really, we should add a SQL finder to this to make it latest_published_users_data_object:
  has_one :users_data_object
  has_one :data_objects_link_type

  has_many :top_images
  has_many :top_concept_images
  has_many :agents_data_objects
  has_many :data_objects_hierarchy_entries
  has_many :data_objects_taxon_concepts
  has_many :curated_data_objects_hierarchy_entries
  has_many :all_curated_data_objects_hierarchy_entries, class_name: CuratedDataObjectsHierarchyEntry.to_s, source: :curated_data_objects_hierarchy_entries, foreign_key: :data_object_guid, primary_key: :guid
  has_many :comments, as: :parent
  has_many :data_objects_harvest_events
  has_many :harvest_events, through: :data_objects_harvest_events
  has_many :data_objects_table_of_contents
  has_many :data_objects_info_items
  has_many :info_items, through: :data_objects_info_items
  has_many :taxon_concept_exemplar_images
  has_many :worklist_ignored_data_objects
  has_many :collection_items, as: :collected_item
  has_many :containing_collections, through: :collection_items, source: :collection
  has_many :translations, class_name: DataObjectTranslation.to_s, foreign_key: :original_data_object_id
  has_many :curator_activity_logs, foreign_key: :target_id,
    conditions: Proc.new { "changeable_object_type_id IN (#{ [ ChangeableObjectType.data_object.id, ChangeableObjectType.data_objects_hierarchy_entry.id,
      ChangeableObjectType.curated_data_objects_hierarchy_entry.id, ChangeableObjectType.users_data_object.id ].join(',') } )" }
  has_many :users_data_objects_ratings, foreign_key: 'data_object_guid', primary_key: :guid
  has_many :all_comments, class_name: Comment.to_s, through: :all_versions, primary_key: :guid, source: :comments
  # the select_with_include library doesn't allow to grab do.* one time, then do.id later on. So in order
  # to use this with preloading I highly recommend doing DataObject.preload_associations(data_objects, :all_versions) on an array
  # of data_objects which already has everything else preloaded
  has_many :all_versions, class_name: DataObject.to_s, foreign_key: :guid, primary_key: :guid, select: 'id, guid, language_id, data_type_id, created_at, published'
  has_many :all_published_versions, class_name: DataObject.to_s, foreign_key: :guid, primary_key: :guid, conditions: 'published = 1'

  has_and_belongs_to_many :hierarchy_entries
  has_and_belongs_to_many :audiences # I don't think this is used anymore.
  has_and_belongs_to_many :refs
  has_and_belongs_to_many :published_refs, class_name: Ref.to_s, join_table: 'data_objects_refs',
    association_foreign_key: 'ref_id', conditions: Proc.new { "published=1 AND visibility_id=#{Visibility.visible.id}" }

  has_and_belongs_to_many :agents
  has_and_belongs_to_many :toc_items, join_table: 'data_objects_table_of_contents', association_foreign_key: 'toc_id'
  has_and_belongs_to_many :taxon_concepts

  attr_accessor :vetted_by, :is_the_latest_published_revision # who changed the state of this object? (not persisted on DataObject but required by observer)

  validates_presence_of :description, if: :is_text?
  validates_presence_of :source_url, if: :is_link?
  validates_presence_of :rights_holder, if: :rights_required?
  validates_inclusion_of :rights_holder, in: '', unless: :rights_required?
  validates_length_of :rights_statement, maximum: 300
  validate :source_url_is_valid, if: :is_link?

  before_validation :default_values
  after_create :clean_values

  scope :images, -> { where(data_type_id: DataType.image.id) }
  scope :texts,  -> { where(data_type_id: DataType.text.id) }

  index_with_solr keywords: [ :object_title, :rights_statement, :rights_holder,
    :location, :bibliographic_citation, :agents_for_solr ], fulltexts: [ :description ]

  def self.maximum_rating
    MAXIMUM_RATING
  end

  def self.minimum_rating
    MINIMUM_RATING
  end

  # this method is not just sorting by rating
  def self.sort_by_rating(data_objects, taxon_concept = nil, sort_order = [:type, :toc, :visibility, :vetted, :rating, :date])
    data_objects.sort_by do |obj|
      obj_vetted = obj.vetted_by_taxon_concept(taxon_concept)
      obj_visibility = obj.visibility_by_taxon_concept(taxon_concept)
      type_order = obj.data_type_id
      toc_view_order = (!obj.is_text? || obj.toc_items.blank?) ? 0 : obj.toc_items[0].view_order
      vetted_view_order = obj_vetted.blank? ? 0 : obj_vetted.view_order
      visibility_view_order = obj_visibility.blank? ? 0 : obj_visibility.view_order
      inverted_rating = obj.data_rating * -1 # Is this throwing an ArgumentError?  Restart your worker(s)!
      inverted_id = obj.id * -1
      sort = []
      sort_order.each do |item|
        sort << type_order if item == :type
        sort << toc_view_order if item == :toc
        sort << visibility_view_order if item == :visibility
        sort << vetted_view_order if item == :vetted
        sort << inverted_rating if item == :rating
        sort << inverted_id if item == :date
      end
      sort
    end
  end

  def self.sort_by_created_date(data_objects)
    data_objects.sort_by do |obj|
      created_at = obj.created_at || 0
      created_at
    end
  end

  def self.sort_by_language_view_order_and_label(data_objects)
    data_objects.sort_by do |obj|
      obj.language ? [ obj.language.sort_order, obj.language.source_form ] : [ 0, 0 ]
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
        vetted_ids += [Vetted.untrusted.id, Vetted.unknown.id, Vetted.inappropriate.id]
        visibility_ids = Visibility.all_ids.dup
      # curators see invisible objects
      elsif options[:user].is_curator? && options[:user].min_curator_level?(:full)
        visibility_ids << Visibility.invisible.id
      end
      # the only scenario to see ONLY TRUSTED objects
      if !options[:user].is_admin?
        vetted_ids = [Vetted.trusted.id]
      end
    end

    if options[:toc_id] == TocItem.wikipedia
      show_preview = true
    end

    # removing from the array the ones not mathching our criteria
    data_objects.compact.select do |d|
      tc = options[:taxon_concept]
      dato_vetted = d.vetted_by_taxon_concept(tc)
      dato_visibility = d.visibility_by_taxon_concept(tc)
      # partners see all their PREVIEW or PUBLISHED objects
      # user can see preview objects
      if show_preview && dato_visibility == Visibility.preview
        true
      # Users can see text that they have added:
      elsif d.added_by_user? && d.users_data_object.user_id == options[:user].id
        true
      # otherwise object must be PUBLISHED and in the vetted and visibility selection
      elsif d.published? && dato_vetted && dato_visibility &&
            vetted_ids.include?(dato_vetted.id) && visibility_ids.include?(dato_visibility.id)
        true
      else
        false
      end
    end
  end

  def self.latest_published_version_of_guid(guid, options={})
    options[:return_only_id] ||= false
    select = (options[:return_only_id]) ? 'id' : '*'
    obj = DataObject.find_by_sql("SELECT #{select} FROM data_objects WHERE guid='#{guid}' AND published=1 ORDER BY id desc LIMIT 1")
    return nil if obj.blank?
    return obj[0]
  end

  def previous_revision
    DataObject.find_by_guid_and_language_id(self.guid, self.language_id, conditions: "id < #{self.id}", order: 'id desc', limit: 1)
  end

  def self.image_cache_path(cache_url, size = '580_360', options={})
    return if cache_url.blank? || cache_url == 0
    size = size ? "_" + size.to_s : ''
    ContentServer.cache_path(cache_url, options) + "#{size}.#{$SPECIES_IMAGE_FORMAT}"
  end

  # NOTE - this used to have a select, but there are too many ancillary methods that get called which need other
  # fields (for example, language_id) and I got sick of adding them, so I just removed the select. Sorry.
  # TODO - this would probably be safer to do using ARel syntax, so we don't load anything until we need it.
  def self.load_for_title_only(find_these)
    DataObject.find(find_these, include: [:toc_items, :data_type])
  end

  def self.still_published?(data_object_id)
    DataObject.find(data_object_id, select: 'published').published?
  end

  # TODO - there is a lot of duplication here with #replicate below. Extract.
  def self.create_user_text(params, options)
    DataObject.set_subtype_if_link_object(params, options)
    DataObject.populate_rights_holder_or_data_subtype(params, options)
    object_is_a_link = (!options[:link_type_id].blank? && options[:link_type_id] != 0)
    params[:source_url] = DataObject.add_http_if_missing(params[:source_url]) if object_is_a_link
    dato = DataObject.new(params.reverse_merge!({published: true}))
    if dato.save
      begin
        dato.toc_items = Array(TocItem.find(options[:toc_id]))
        dato.build_relationship_to_taxon_concept_by_user(options[:taxon_concept], options[:user])
        if object_is_a_link
          dato.data_objects_link_type = DataObjectsLinkType.create(data_object: dato, link_type_id: options[:link_type_id])
        end
      rescue => e
        dato.update_column(:published, false)
        raise e
      ensure
        options[:taxon_concept].reload if options[:taxon_concept]
        dato.update_solr_index
      end
    end
    dato
  end

  # NOTE - you probably want to check that the user performing this has rights to do so, before calling this.
  def replicate(params, options)
    DataObject.set_subtype_if_link_object(params, options)
    DataObject.populate_rights_holder_or_data_subtype(params, options)
    object_is_a_link = (!options[:link_type_id].blank? && options[:link_type_id] != 0)
    params[:source_url] = DataObject.add_http_if_missing(params[:source_url]) if object_is_a_link
    new_dato = DataObject.new(params.reverse_merge!(guid: self.guid, published: 1))
    if new_dato.save
      begin
        new_dato.toc_items = Array(TocItem.find(options[:toc_id]))
        new_dato.unpublish_previous_revisions
        if object_is_a_link
          new_dato.data_objects_link_type = DataObjectsLinkType.create(data_object: new_dato, link_type_id: options[:link_type_id])
        end
        # NOTE - associations will be preserved in their current vetted state by virtue of the GUID.
        # There was once code here to trust all associations, if the user was a curator or admin. We have since
        # elucidated that we do NOT want to change the vetted state after an update.
        new_dato.users_data_object = users_data_object.replicate(new_dato)
        DataObjectsTaxonConcept.find_or_create_by_taxon_concept_id_and_data_object_id(users_data_object.taxon_concept_id, new_dato.id)
        new_dato.recalculate_rating
      rescue => e
        new_dato.update_column(:published, false)
        raise e
      ensure
        new_dato.update_solr_index
      end
    end
    new_dato
  end

  def self.add_http_if_missing(source_url)
    return "http://#{source_url}" unless source_url =~ /^[a-z]{3,5}:\/\//i
    source_url
  end

  def created_by_user?
    user != nil
  end

  def user
    @udo ||= users_data_object
    @udo_user ||= @udo.nil? ? nil : users_data_object.user
  end
  def user_id
    user.id
  end

  def taxon_concept_for_users_text
    # Need to make sure we're reading from master, since the udo won't exist if
    # there's slave lag, sigh:
    DataObject.with_master do
      unless user.nil?
        udo = UsersDataObject.find_by_data_object_id(id)
        TaxonConcept.find(udo.taxon_concept_id)
      end
    end
  end

  def rate(user, new_rating)
    if this_users_current_rating = rating_from_user(user)
      if this_users_current_rating.rating != new_rating
        this_users_current_rating.update_column(:rating, new_rating)
        this_users_current_rating.update_column(:weight, user.rating_weight)
      end
    else
      UsersDataObjectsRating.create(data_object_guid: guid, user_id: user.id,
                                    rating: new_rating, weight: user.rating_weight)
    end

    users_data_objects_ratings.reload
    self.update_column(:data_rating, average_rating)
  end

  def recalculate_rating
    self.update_column(:data_rating, average_rating)
    data_rating
  end

  def has_been_rated?
    users_data_objects_ratings.count > 0
  end

  def rating_from_user(u)
    return nil if u.is_a?(EOL::AnonymousUser)
    # more often than not ratings will have been preloaded, so a .detect
    # is faster than a .where here
    users_data_objects_ratings.detect{ |udor| udor.user_id == u.id }
  end

  def safe_rating
    return self.data_rating if self.data_rating >= MINIMUM_RATING && self.data_rating <= MAXIMUM_RATING
    Rails.logger.warn "!! WARNING: data object #{self.id} had a data_rating of #{self.data_rating}. Attempted fix:"
    rating = recalculate_rating
    if rating <= MINIMUM_RATING
      Rails.logger.error "** ERROR: data object #{self.id} had a *calculated* rating of #{rating}."
      return MINIMUM_RATING
    elsif rating > MAXIMUM_RATING
      Rails.logger.error "** ERROR: data object #{self.id} had a *calculated* rating of #{rating}."
      return MAXIMUM_RATING
    else
      return rating
    end
  end

  def comment(user, body)
    comment = comments.create user: user, body: body
    user.comments.reload # be friendly - update the user's comments automatically
    comment
  end

  # Find the Agent (only one) that supplied this data object to EOL.
  def data_supplier_agent
    # this is a bit of a shortcut = the hierarchy's agent should be the same as the agent
    # that contributed the resource. DataObject should only live in a single hierarchy
    @data_supplier_agent ||= hierarchy_entries[0].hierarchy.agent rescue nil
    if !@data_supplier_agent.blank?
      if (!@data_supplier_agent.homepage?)
        @data_supplier_agent = Agent.find_by_id(@data_supplier_agent.id)
      end
    end
    return @data_supplier_agent
  end

  def content_partner
    resource.content_partner if resource
  end

  def resource
    # TODO - change this, since it would be more efficient to go through hierarchy_entries... but the first attempt
    # (using hierarchy_entries.first) failed to find the correct data in observed cases. WEB-2850
    return @resource if @resource
    @resource = data_objects_hierarchy_entries.first.hierarchy_entry.hierarchy.resource rescue (harvest_events.last.resource rescue nil)
  end

  # 'owner' chooses someone responsible for this data object in order of preference
  # this method returns [OwnerName, OwnerUser || nil]
  def owner
    return translated_from.owner if data_object_translation # Use the original owner when translated. TODO - image only?
    if rights_holder_for_display.blank?
      unless agents_data_objects.empty?
        AgentsDataObject.sort_by_role_for_owner(agents_data_objects)
        if first_agent = agents_data_objects.first.agent
          return first_agent.full_name
        end
      end
      return ''
    else # rights holder is preferred
      owner = "#{rights_holder_for_display}"
      unless license && license.is_public_domain?
        return "&copy; #{owner}"
      end
      return owner
    end
  end

  # Find all of the authors associated with this data object, including those that we dynamically add elsewhere
  def authors
    @default_authors = agents_data_objects.select{ |ado| ado.agent_role_id == AgentRole.author.id }.collect {|ado| ado.agent }.compact
  end

  def revisions
    DataObject.find_all_by_guid_and_language_id(guid, language_id)
  end

  def image?
    return DataType.image_type_ids.include?(data_type_id)
  end
  alias is_image? image?

  def text?
    return DataType.text_type_ids.include?(data_type_id)
  end
  alias is_text? text?

  def sound?
    return DataType.sound_type_ids.include?(data_type_id)
  end
  alias is_sound? sound?

  def video?
    return DataType.video_type_ids.include?(data_type_id)
  end
  alias is_video? video?

  # NOTE: does not include image maps @see is_image_map? is used by en_type(object) in ApplicationHelper
  def map?
    return DataType.map_type_ids.include?(data_type_id)
  end
  alias is_map? map?

  # NOTE: Specifically for image maps
  def image_map?
    self.is_image? && is_subtype?(:map)
  end
  alias is_image_map? image_map?

  def link?
    self.is_text? && is_subtype?(:link)
  end
  alias is_link? link?

  def iucn?
    return data_type_id == DataType.iucn.id
  end
  alias is_iucn? iucn?

  def has_object_cache_url?
    return false if object_cache_url.blank? or object_cache_url == 0
    return true
  end

  def is_subtype_map?
    return true if self.data_subtype_id && self.data_subtype_id == DataType.map.id
    false
  end

  def map_from_DiscoverLife?
    (is_subtype_map? && resource && resource.from_DiscoverLife? && self.is_subtype_map?)
  end

  def access_image_from_remote_server?(size)
    return true if ['580_360', :orig].include?(size) && map_from_DiscoverLife?
    # we can add here other criterias for image to be hosted remotely
    false
  end

  def has_thumbnail?
    ((is_video? || is_sound?) && thumbnail_cache_url?) || (is_image? && object_cache_url?)
  end
  alias :has_thumb? :has_thumbnail?

  def thumb_or_object(size = '580_360', options={})
    if self.is_video? || self.is_sound?
      return DataObject.image_cache_path(thumbnail_cache_url, size, options)
    elsif has_object_cache_url?
      # this is just for Staging and can be removed for production. Staging uses a different
      # content server and needs to generate URLS with a different host for image crops
      is_crop = false
      return DataObject.image_cache_path(object_cache_url, size, options.merge({ is_crop: is_crop }))
    else
      return nil # No image to show. You might want to alter your code to avoid this by using #has_thumbnail?
    end
  end

  # Returns path to a thumbnail.
  def smart_thumb
    thumb_or_object('98_68')
  end

  # Returns path to a "larger" thumbnail (a'la main page).
  def smart_medium_thumb
    thumb_or_object('260_190')
  end

  # Returns path to the *full* image.
  def smart_image
    thumb_or_object
  end

  def original_image
    thumb_or_object(:orig)
  end

  def sound_url
    if !object_cache_url.blank? && !object_url.blank?
      filename_extension = File.extname(object_url).downcase
      # TODO get file extension during harvest so we don't have to guess here
      # we store audio as ogg, not oga
      filename_extension = '.ogg' if filename_extension == '.oga'
      return (ContentServer.cache_path(object_cache_url) + filename_extension) unless filename_extension.blank?
    end
    if mime_type.id == MimeType.mp3.id
      return has_object_cache_url? ? ContentServer.cache_path(object_cache_url) + '.mp3' : ''
    elsif mime_type.id == MimeType.wav.id
      return has_object_cache_url? ? ContentServer.cache_path(object_cache_url) + '.wav' : ''
    else
      return object_url
    end
  end

  def video_url
    if !object_cache_url.blank? && !object_url.blank?
      filename_extension = File.extname(Addressable::URI.parse(object_url).omit(:query).to_s).downcase
      # TODO get file extension during harvest so we don't have to guess here
      # the following addresses issues where object url is not directly a media path
      # we could reverse this and whitelist file extensions we know are ok
      if ['.php'].include? filename_extension
        # unreliably guess file extension from user provided mime type
        if (extensions = Rack::Mime::MIME_TYPES.select{|k, v| v == mime_type.label})
          unless extensions.empty?
            if extensions.keys.include?('.mp4')
              filename_extension = '.mp4'
            elsif extensions.keys.include?('.mov')
              filename_extension = '.mov'
            else
              filename_extension = extensions.first[0]
            end
          end
        end
      end
      # we store video as ogg, not ogv
      filename_extension = '.ogg' if filename_extension == '.ogv'
      return ContentServer.cache_path(object_cache_url) + filename_extension
    elsif data_type.label('en') == 'Flash'
      return has_object_cache_url? ? ContentServer.cache_path(object_cache_url) + '.flv' : ''
    else
      return object_url
    end
  end

  # TODO - wow, this is expensive (IFF you pass in :published) ... we should really consider optimizing this, since
  # it's actually used quite often. ...and in some cases, just to get the ID of the first one.  Ouch.
  # :published -> :strict - return only published taxon concepts
  # :published -> :preferred - same as above, but returns unpublished taxon concepts if no published ones are found
  # NOTE - honestly, I don't know if I trust this anymore anyway!  Compare to #data_object_taxa, for example.
  def get_taxon_concepts(opts = {})
    return @taxon_concepts if @taxon_concepts
    if created_by_user?
      @taxon_concepts = [taxon_concept_for_users_text]
    else
      @taxon_concepts = taxon_concepts
    end
    if opts[:published]
      published, unpublished = @taxon_concepts.partition { |item| item.published? }
      @taxon_concepts = (!published.empty? || opts[:published] == :strict) ? published : unpublished
    end
    @taxon_concepts
  end

  def linked_taxon_concept
    get_taxon_concepts.first
  end

  def update_solr_index
    if self.published
      DataObject.with_master do
        self.class.uncached do
          # creating another instance to remove any change of this instance not
          # matching the database and indexing stale or changed information
          object_to_index = DataObject.find(self.id)
          EOL::Solr::DataObjectsCoreRebuilder.reindex_single_object(object_to_index)
          if d = previous_revision
            EOL::Solr::DataObjectsCoreRebuilder.reindex_single_object(object_to_index)
          end
        end
      end
    else
      # hidden, so delete it from solr
      solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
      solr_connection.delete_by_id(self.id)
    end
  end

  def in_wikipedia?
    toc_items.include?(TocItem.wikipedia)
  end

  # TODO - really?  No logging?  Not going through Curation at all?  :S
  def publish_wikipedia_article(taxon_concept)
    return false unless in_wikipedia?
    return false unless visibility_by_taxon_concept(taxon_concept) == Visibility.preview

    connection.execute("UPDATE data_objects SET published=0 WHERE guid='#{guid}'");
    reload

    dato_vetted = vetted_by_taxon_concept(taxon_concept)
    dato_vetted_id = dato_vetted.id unless dato_vetted.nil?
    dato_visibility = visibility_by_taxon_concept(taxon_concept)
    dato_visibility_id = dato_visibility.id unless dato_visibility.nil?

    dato_association = association_with_taxon_or_best_vetted(taxon_concept)
    dato_association.visibility_id = Visibility.visible.id
    dato_association.vetted_id = Vetted.trusted.id
    dato_association.save!
    self.update_column(:published, 1)
  end

  def visible_references
    @all_refs ||= refs.delete_if {|r| r.published != 1 || r.visibility_id != Visibility.visible.id}
  end

  def to_s
    "[DataObject id:#{id}]"
  end

  def in_language?(comparison_language_id)
    comparison_language_id = Language.default.id if comparison_language_id.blank? || comparison_language_id == 0
    this_language_id = (language_id.blank? || language_id == 0) ? Language.default.id : language_id
    this_language_id == comparison_language_id
  end

  def published_in_language?(comparison_language_id)
    published? && in_language?(comparison_language_id)
  end

  def latest_version_in_same_language(params = {})
    latest_version_in_language(language_id, params)
  end

  def latest_version_in_language(chosen_language_id, params = {})
    return self if id.nil?
    chosen_language_id ||= language.id
    chosen_language_id = Language.english.id unless chosen_language_id && chosen_language_id != 0
    params[:check_only_published] = true unless params.has_key?(:check_only_published)
    # Important to ensure you're looking at ALL the data objects:
    versions_to_look_at_in_language = DataObject.with_master do
      if params[:check_only_published]
        return self if published_in_language?(chosen_language_id)
        # sometimes all_published_versions, but if not I anted to set a default set of select fields. Rails AREL
        # will attempt to load the versions again if the select fields are not the same as already
        # loaded in all_published_versions. This is verbose, but its potentially saving loading all descriptions from all
        # versions so I think it is worth it. But there may be an easier way
        unless all_published_versions.loaded?
          DataObject.preload_associations(self, :all_published_versions, select: 'id, guid, language_id, data_type_id, created_at, published')
        end
        all_published_versions
      else
        all_versions
      end
    end
    # only looking at revisions with the same data type (due to a bug it is possible for different revisions to have different types)
    versions_to_look_at_in_language.delete_if{ |d| data_type_id && d.data_type_id != data_type_id }
    versions_to_look_at_in_language.delete_if do |d|
      if d.language_id && d.language_id != 0
        true if d.language_id != chosen_language_id
      else
        true if chosen_language_id != Language.english.id
      end
    end
    if versions_to_look_at_in_language.empty?
      latest_version = self
    else
      latest_version = DataObject.sort_by_created_date(versions_to_look_at_in_language).reverse.first
    end
    return nil if params[:check_only_published] && !latest_version.published?
    return self if latest_version == self
    DataObject.find(latest_version.id)
  end

  def is_latest_published_version_in_same_language?
    return @is_latest_published_version unless @is_latest_published_version.nil?
    the_latest = latest_published_version_in_same_language
    @is_latest_published_version = (the_latest && the_latest.id == self.id) ? true : false
  end

  # this method will be run on an instance of an object unlike the above methods. It is best to have preloaded
  # all_published_versions in order for this method to be efficient
  # NOTE: English is basically the default language in the DB and we have cases where some revisions have
  # a language == English, but other revisions have a language_id of 0. That explains some
  # of the complicated logic in this method
  def latest_published_version_in_same_language
    @latest_published_version_in_same_language ||= latest_version_in_same_language(check_only_published: true)
  end

  # NOTE - You probably shouldn't be using these. It isn't really true that a data object has *one* visibility... it
  # has several. This is currently here only because the old API made that (false) assumption.
  def visibility
    @visibility ||= raw_association.visibility
  end
  def vetted
    @vetted ||= raw_association.vetted
  end

  # ATM, this is really only used by the User model to get the pages where the user commented...
  def taxon_concept_id
    return users_data_object.taxon_concept_id if users_data_object
    assoc = raw_association
    assoc.hierarchy_entry.taxon_concept_id if assoc
  end

  def visibility_by_taxon_concept(taxon_concept)
    a = association_with_taxon_or_best_vetted(taxon_concept)
    return a ? a.visibility : a
  end

  def vetted_by_taxon_concept(taxon_concept)
    a = association_with_taxon_or_best_vetted(taxon_concept)
    return a ? a.vetted : a
  end

  # Really only used in specs.  :\
  def vet_by_taxon_concept(tc, vet)
    assoc = raw_association(taxon_concept: tc)
    assoc.vetted_id = vet.id
    assoc.save!
  end

  # Used in the add-association view to recognize whether an association already exists:
  def associated_with_entry?(he)
    raw_association(hierarchy_entry: he)
  end

  def flickr_photo_id
    if matches = source_url.match(/flickr\.com\/photos\/.*?\/([0-9]+)\//)
      return matches[1]
    end
    nil
  end

  # Preview visibility CAN apply here, so be careful. By default, preview is included; otherwise, pages would show up
  # without any association at all, and that would be confusing. But note that preview associations should NOT be
  # curatable!
  def data_object_taxa_by_visibility(which = {})
    good_ids = [Visibility.visible.id]
    good_ids << Visibility.preview.id unless which[:preview] == false
    good_ids << Visibility.invisible.id if which[:invisible]
    uncached_data_object_taxa.select { |assoc| good_ids.include?(assoc.visibility_id) }
  end

  # The only filter allowed right now is :published.
  # This is obnoxiously expensive, so we cache it by default. See #uncached_data_object_taxa if you need it, but
  # consider clearing the cache instead...
  def data_object_taxa(options = {})
    DataObjectCaching.associations(self, options)
  end
  alias :associations :data_object_taxa

  # The only filter allowed right now is :published.
  def uncached_data_object_taxa(options = {})
    @data_object_taxa ||= {}
    cache_key = Marshal.dump(options)
    return @data_object_taxa[cache_key] if @data_object_taxa.has_key?(cache_key)
    assocs = (options[:published] == true) ?
      published_entries.clone :
      curated_hierarchy_entries.clone
    assocs << DataObjectTaxon.new(latest_published_users_data_object) if latest_published_users_data_object
    [ :vetted_id, :visibility_id ].each do |param|
      if options[param]
        values = options[param]
        values = [ values ] if values.class == Fixnum
        assocs.delete_if{ |a| ! values.include?(a.send(param)) }
      end
    end
    @data_object_taxa[cache_key] = assocs || []
  end

  def first_hierarchy_entry(options={})
    sorted_entries = HierarchyEntry.sort_by_vetted(published_entries)
    best_first_entry = sorted_entries[0] rescue nil
    if best_first_entry.nil? && options[:include_preview_entries]
      sorted_entries = HierarchyEntry.sort_by_vetted(curated_hierarchy_entries)
      best_first_entry = sorted_entries[0] rescue nil
    end
    return nil unless best_first_entry
    best_first_entry.hierarchy_entry # Because #published_entries returns DataObjectTaxon instances...
  end

  # NOTE - if you plan on calling this, you are behooved by adding object_title and data_type_id to your selects.
  def best_title
    return safe_object_title.html_safe unless safe_object_title.blank?
    return toc_items.first.label.html_safe unless ! text? || toc_items.blank? || toc_items.first.label.nil?
    return image_title_with_taxa.html_safe if image?
    return safe_data_type.simple_type.html_safe if safe_data_type
    return I18n.t(:unknown_data_object_title).html_safe
  end
  alias :summary_name :best_title
  alias :collected_name :best_title

  # NOTE - if you plan on calling this, you are behooved by adding object_title to your selects. You MUST select
  # description and data_type_id.
  # TODO - this really doesn't belong here. Truncation belongs in the view (or a helper). Also, it duplicates SOME of
  # the logic of best_title, but not all of it (why?). Very poor design.
  def short_title
    return safe_object_title unless safe_object_title.blank?
    # TODO - ideally, we should extract some of the logic from data_objects/show to make this "Image of Procyon Lotor".
    return data_type.label if description.blank?
    st = description.gsub(/\n.*$/, '')
    st = st[0..29] + '...' if st.length > 32
    st
  end

  def description_teaser
    full_teaser = Sanitize.clean(description.truncate_html(length: 300), elements: %w[b i], remove_contents: %w[table script]).strip
    return nil if full_teaser.blank?
    truncated_teaser = full_teaser.split[0..10].join(' ').balance_tags
    truncated_teaser << '...' if full_teaser.length > truncated_teaser.length
    truncated_teaser.strip
  end

  def added_by_user?
    users_data_object && !users_data_object.user.blank?
  end

  def add_curated_association(user, hierarchy_entry)
    taxon_concept_id = hierarchy_entry.taxon_concept.id
    vetted_id = user.min_curator_level?(:full) ? Vetted.trusted.id : Vetted.unknown.id
    # SILENTLY returns... this is not an error, but nothing needs to be done:
    if assoc = existing_association(hierarchy_entry)
      return assoc
    end
    cdohe = CuratedDataObjectsHierarchyEntry.create(hierarchy_entry_id: hierarchy_entry.id,
                                                    data_object_id: self.id, user_id: user.id,
                                                    data_object_guid: self.guid,
                                                    vetted_id: vetted_id,
                                                    visibility_id: Visibility.visible.id)
    if self.data_type == DataType.image
      TopImage.find_or_create_by_hierarchy_entry_id_and_data_object_id(hierarchy_entry.id, self.id, view_order: 1)
      TopConceptImage.find_or_create_by_taxon_concept_id_and_data_object_id(taxon_concept_id, self.id, view_order: 1)
    end
    DataObjectsTaxonConcept.find_or_create_by_taxon_concept_id_and_data_object_id(taxon_concept_id, self.id)
    revisions_by_date.each do |revision|
      if revision.id != self.id
        dotc_exists = DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(taxon_concept_id, revision.id)
        dotc_exists.destroy unless dotc_exists.nil?
      end
    end
    cdohe
  end

  def existing_association(hierarchy_entry)
    CuratedDataObjectsHierarchyEntry.find_by_data_object_guid_and_hierarchy_entry_id(guid, hierarchy_entry.id)
  end

  def remove_curated_association(user, hierarchy_entry)
    cdohe = existing_association(hierarchy_entry)
    raise EOL::Exceptions::ObjectNotFound if cdohe.nil?
    raise EOL::Exceptions::WrongCurator.new("user did not create this association") unless
      cdohe.user_id == user.id || user.min_curator_level?(:master)
    taxon_concept_id = hierarchy_entry.taxon_concept.id
    cdohe.destroy
    if self.data_type == DataType.image
      tci_exists = TopConceptImage.find_by_taxon_concept_id_and_data_object_id(taxon_concept_id, self.id)
      tci_exists.destroy unless tci_exists.nil?
      ti_exists = TopImage.find_by_hierarchy_entry_id_and_data_object_id(hierarchy_entry.id, self.id)
      ti_exists.destroy unless ti_exists.nil?
    end
    unless still_associated_with_taxon_concept?(taxon_concept_id)
      revisions_by_date.each do |revision|
        dotc_exists = DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(taxon_concept_id, revision.id)
        dotc_exists.destroy unless dotc_exists.nil?
      end
    end
    cdohe
  end

  def still_associated_with_taxon_concept?(taxon_concept_id)
    data_object_taxa.each do |assoc|
      if assoc.class == UsersDataObject
        return true if assoc.taxon_concept_id == taxon_concept_id
      else
        return true if assoc.taxon_concept.id == taxon_concept_id
      end
    end
    return false
  end

  def translated_from
    data_object_translation ? data_object_translation.original_data_object : nil
  end
  alias :translation_source :translated_from

  def available_translations_data_objects(current_user, taxon)
    latest_translations = []
    # first checking if this is original, which will have translations
    unless translations.blank?
      latest_translations << self
      translations.each do |tr|
        latest_translations << tr.data_object
      end
    else
      # now checking if this is the translated form of some other original
      if data_object_translation
        original_data_object = data_object_translation.original_data_object
        latest_translations << original_data_object
        # including the other translations of the primary object
        original_data_object.translations.each do |tr|
          latest_translations << tr.data_object
        end
      end
    end
    latest_translations.map!{ |d| d.latest_published_version_in_same_language }
    latest_translations.compact!
    latest_translations.uniq!
    latest_translations.delete_if{ |d| d.language && !Language.approved_languages.include?(d.language) }
    latest_translations.delete_if{ |d| !d.published? }
    if latest_translations.length > 1
      DataObject.sort_by_language_view_order_and_label(latest_translations)
      if !taxon.nil?
        dobjs = DataObject.filter_list_for_user(latest_translations, {user: current_user, taxon_concept: taxon})
      end
      return latest_translations
    end
  end


  def available_translation_languages(current_user, taxon)
    dobjs = available_translations_data_objects(current_user, taxon)
    if dobjs and !dobjs.empty?
      lang_ids = []
      dobjs.each do |dobj|
        lang_ids << dobj.language_id
      end

      lang_ids = lang_ids.uniq
      if !lang_ids.empty? && lang_ids.length>1
        languages = Language.find_by_sql("SELECT * FROM languages WHERE id in (#{lang_ids.join(',')}) AND activated_on <= NOW() ORDER BY sort_order")
        if !languages.blank? && languages.length>1
          return languages
        end
      end
    end
    return nil

  end

  def log_activity_in_solr(options)
    DataObject.with_master do
      base_index_hash = {
        'activity_log_unique_key' => "UsersDataObject_#{id}",
        'activity_log_type' => 'UsersDataObject',
        'activity_log_id' => self.users_data_object.id,
        'action_keyword' => options[:keyword],
        'date_created' => self.updated_at.solr_timestamp || self.created_at.solr_timestamp }
      base_index_hash[:user_id] = options[:user].id if options[:user]
      EOL::Solr::ActivityLog.index_notifications(base_index_hash, notification_recipient_objects(options))
      queue_notifications
    end
  end

  def queue_notifications
    Notification.queue_notifications(notification_recipient_objects, self)
  end

  def notification_recipient_objects(options = {})
    return @notification_recipients if @notification_recipients
    @notification_recipients = []
    add_recipient_user_making_object_modification(@notification_recipients, options)
    add_recipient_pages_affected(@notification_recipients, options)
    add_recipient_users_watching(@notification_recipients, options)
    @notification_recipients
  end

  def contributing_user
    if users_data_object && users_data_object.user
      users_data_object.user
    elsif content_partner && content_partner.user
      content_partner.user
    end
  end

  # TODO - this seems odd to me. We essentially have two tables storing the same relationship, but one with extra info?
  def build_relationship_to_taxon_concept_by_user(taxon_concept, user)
    DataObjectsTaxonConcept.find_or_create_by_taxon_concept_id_and_data_object_id(taxon_concept.id, self.id)
    UsersDataObject.create(user: user, data_object: self,
                           taxon_concept: taxon_concept, visibility: Visibility.visible)
  end

  def revisions_by_date
    @revisions_by_date ||= DataObject.sort_by_created_date(self.revisions).reverse
  end

  def self.replace_with_latest_versions!(data_objects, options={})
    options[:select] = [] if options[:select].blank? || options[:select].class != Array
    default_selects = [ :id, :published, :language_id, :guid, :data_type_id, :data_subtype_id, :object_cache_url,
      :data_rating, :object_title, :rights_holder, :source_url, :license_id, :mime_type_id, :object_url,
      :thumbnail_cache_url, :created_at ]
    DataObject.preload_associations(data_objects, :language)
    if options[:check_only_published]
      # if we only want latest versions of published objects, then we should check to see if we
      # have them already, and only preload the objects which are not already the latest versions in the language
      objects_for_preloading = data_objects.compact.select{ |d| ! d.published_in_language?(options[:language_id]) }
    else
      objects_for_preloading = data_objects
    end
    DataObject.preload_associations(objects_for_preloading, :all_published_versions,
      select: {
        data_objects: default_selects | options[:select] } )
    # sending data_objects and not objects_for_preloading as data_objects is the array which contains the instances
    # that need the latest versions
    DataObject.replace_with_latest_versions_no_preload(data_objects, options)
  end

  def self.replace_with_latest_versions_no_preload(data_objects, options = {})
    data_objects.collect! do |dato|
      if dato.blank? || !dato.is_a?(DataObject)
        dato
      else
        latest = dato.latest_version_in_language(options[:language_id] || dato.language_id, options.reverse_merge(check_only_published: false))
        latest = dato if latest.nil?
        latest.is_the_latest_published_revision = true
        latest
      end
    end
  end

  def unpublish_previous_revisions
    DataObject.find(:all, conditions: "id != #{self.id} AND guid = '#{self.guid}'").each do |dato|
      if dato.published?
        dato.update_column(:published, 0)
        dato.update_solr_index
        dato.remove_from_index
      end
    end
  end

  # TODO - generalize the instance variable reset. It could just be a module that's included at the top of the class.
  # (I'm actually kinda surprised rails doesn't actually do this by default. Hmmmn.)
  def reload
    DataObjectCaching.clear(self)
    @@ar_instance_vars ||= DataObject.new.instance_variables << :mock_proxy # For tests
    (instance_variables - @@ar_instance_vars).each do |ivar|
      remove_instance_variable(ivar)
    end
    super
  end

  # NOTE this is expensive, so don't call this on large collections of data objects:
  def reindex
    reload
    update_solr_index
    data_object_taxa(published: true).map(&:taxon_concept).each { |tc| tc.reindex if tc }
  end

  def can_be_deleted_by?(requestor)
    return false
  end

  def link_type
    if data_objects_link_type && data_objects_link_type.link_type
      data_objects_link_type.link_type
    end
  end

  def rating_summary
    rating_summary_hash = { 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0 }
    users_data_objects_ratings.each do |udo|
      rating_summary_hash[udo.rating] += udo.weight
    end
    rating_summary_hash
  end

  def total_ratings
    rating_summary.collect{ |score, votes| votes }.inject(:+)
  end

  def average_rating
    return 2.5 if users_data_objects_ratings.blank?
    rating_summary.collect{ |score, votes| score * votes }.inject(:+) / total_ratings.to_f
  end

  def show_rights_holder?
    license && license.show_rights_holder?
  end

  def can_be_made_overview_text_for_user?(user, taxon_concept)
    return false unless published?
    if visibility_by_taxon_concept(taxon_concept) == Visibility.visible
      overview = taxon_concept.overview_text_for_user(user)
      return true if overview.blank?
      return true if guid != overview.guid
    end
    false
  end

  def rights_holder_for_display
    return rights_holder unless rights_holder.blank?
    return resource.rights_holder unless resource.blank? || resource.rights_holder.blank?
  end

  def rights_statement_for_display
    return rights_statement unless rights_statement.blank?
    return resource.rights_statement unless resource.blank? || resource.rights_statement.blank?
  end

  def bibliographic_citation_for_display
    return bibliographic_citation unless bibliographic_citation.blank?
    return resource.bibliographic_citation unless resource.blank? || resource.bibliographic_citation.blank?
  end

  # NOTE - this is not very intention-revealing, because we #set_to_representative_language... but that doesn't
  # bother me enough to give it a loooooong method name.
  def approved_language?
    set_to_representative_language
    Language.approved_languages.include?(language)
  end

  def set_to_representative_language
    self.language = language ? language.representative_language : nil
  end

  def collected_type
    if is_link?
      item_collected_item_type = 'Link'
    else
      item_collected_item_type = data_type.simple_type('en')
    end
  end

  # Used for notifications only. Expensive.
  def watch_collections_for_associated_taxa
    data_object_taxa(published: true).map(&:taxon_concept).flat_map { |tc| tc.containing_collections.watch }
  end

  def title_same_as_toc_label(toc_item, options = {})
    return false unless toc_item
    options[:language] ||= Language.default
    return true if toc_item.label(options[:language].iso_code).downcase == object_title.downcase
    if options[:language] != Language.default
      return true if toc_item.label(Language.default_code).downcase == object_title.downcase
    end
  end

  def agents_for_solr
    agent_names = agents_data_objects.collect{ |ado| ado.agent.full_name }.uniq.compact
    return if agent_names.empty?
    { keyword_type: 'agent', keywords: agent_names }
  end

  # Because dependent destroy was too scary for us.  :|
  def destroy_everything
    # Too slow, probably not needed anyway: dato.top_images.destroy_all
    # Same with top_concept_images
    agents_data_objects.destroy_all # denorm table
    data_objects_hierarchy_entries.destroy_all # denorm
    data_objects_taxon_concepts.destroy_all # denorm
    curated_data_objects_hierarchy_entries.destroy_all # denorm
    comments.destroy_all
    data_objects_table_of_contents.destroy_all
    data_objects_info_items.destroy_all
    taxon_concept_exemplar_images.destroy_all
    worklist_ignored_data_objects.destroy_all
    collection_items.destroy_all
    # TODO: handle translations
    curator_activity_logs.destroy_all
    users_data_objects_ratings.destroy_all
    # refs.destroy_all # through the join table, here:
    # DataObjectsRef.where(data_object_id: id).destroy_all
    #ref_ids = refs.map(:id)
    refs_ids = []
    DataObjectsRef.where(data_object_id: id).each do |data_object_ref|
      refs_ids << data_object_ref.ref_id
      data_object_ref.destroy
    end
    Ref.where(id: refs_ids).each { |ref| ref.destroy if ref.data_objects.count == 0 }
    DataObjectsHierarchyEntry.where(data_object_id: id).destroy_all
    AgentsDataObject.where(data_object_id: id).destroy_all
    DataObjectsTaxonConcept.where(data_object_id: id).destroy_all
    DataObjectsTableOfContent.where(data_object_id: id).destroy_all
  end
  def self.same_as_last?(params, options)
    last_dato = DataObject.texts.last
    return false unless last_dato
    user_dato= UsersDataObject.find_by_data_object_id( last_dato.id )
    if user_dato
      return  UsersDataObject.find_by_data_object_id( last_dato.id ).user_id == options[:user][:id] &&
              options[:taxon_concept][:id] == UsersDataObject.find_by_data_object_id( last_dato.id ).taxon_concept_id &&
              params[:data_object][:data_type_id].to_i  == last_dato.data_type_id &&
              (params[:data_object][:object_title] == last_dato.object_title ||
              params[:data_object][:description] == last_dato.description) 
    end
  end

private

  def source_url_is_valid
    if is_link? && (source_url.blank? || ! EOLWebService.url_accepted?(source_url))
      errors[:source_url] << I18n.t(:url_not_accessible)
    end
  end

  # This is relatively expensive... but accurate.
  def image_title_with_taxa
    return @image_title_with_taxa if @image_title_with_taxa
    all_data_object_taxa = uncached_data_object_taxa(published: true)
    visible_data_object_taxa = all_data_object_taxa.select{ |dot| dot.vetted != Vetted.untrusted }
    if visible_data_object_taxa.empty?
      @image_title_with_taxa ||= I18n.t(:image_title_without_taxa)
    else
      @image_title_with_taxa ||= I18n.t(:image_title_with_taxa,
                                        taxa: visible_data_object_taxa.
                                            map(&:title_canonical_italicized).to_sentence)
    end
  end

  # TODO - this is quite lame. Best to re-think this. Perhaps a class that handles and cleans the DatoParams?
  # NOTE that this can modify params.
  # Remember, you don't put a bang on overwrite methods unless there's a safe version that *doesn't* do it.
  def self.populate_rights_holder_or_data_subtype(params, options)
    return if options[:link_object]
    license = License.find(params[:license_id]) rescue nil
    needs_rights = license && license.show_rights_holder?
    params[:rights_holder] = options[:user].full_name if needs_rights && params[:rights_holder].blank?
  end

  def self.set_subtype_if_link_object(params, options)
    params[:data_subtype_id] = DataType.link.id if options[:link_object]
  end

  # NOTE - do NOT rename this "association", that appears to be a reserved Rails name.
  def raw_association(options = {})
    raw_associations(options).first
  end

  # Options allowed are the :hierarchy_entry or :taxon_concept to filter on. Don't use both.
  # With no options, this sorts by best vetted status.
  def raw_associations(options = {})
    assocs = filter_associations(data_objects_hierarchy_entries, options)
    assocs += filter_associations(all_curated_data_objects_hierarchy_entries, options)
    if assocs.empty? || options.empty?
      return [] if options[:hierarchy_entry] # Can't match this on UDO, so there were none.
      if users_data_object
        assocs << users_data_object unless
          options[:taxon_concept] && users_data_object.taxon_concept_id != options[:taxon_concept].id
      end
    end
    assocs.compact!
    return [] if assocs.empty?
    assocs.sort_by { |a| [ a.visibility && a.visibility.view_order, a.vetted && a.vetted.view_order ] }
  end

  # To retrieve an exact association(if exists) for the given taxon concept,
  # otherwise retrieve an association with best vetted status.
  # TODO - let's put this in Rails.cache to avoid the lookup more often. Clearing it will, of course, be a little tricky.
  # Expiry should be one day.
  def association_with_taxon_or_best_vetted(taxon_concept)
    @association_with_taxon_or_best_vetted ||= {}
    return @association_with_taxon_or_best_vetted[taxon_concept.id] if
      @association_with_taxon_or_best_vetted.has_key?(taxon_concept.id)
    assoc = raw_association(taxon_concept: taxon_concept)
    if assoc.blank?
      return @association_with_taxon_or_best_vetted[taxon_concept.id] = raw_association
    else
      return @association_with_taxon_or_best_vetted[taxon_concept.id] = assoc
    end
  end

  def filter_associations(assocs, options = {})
    assocs.select do |dohe|
      if options[:taxon_concept]
        dohe.hierarchy_entry.taxon_concept_id == options[:taxon_concept].id
      elsif options[:hierarchy_entry]
        dohe.hierarchy_entry_id == options[:hierarchy_entry].id
      else
        true
      end
    end
  end

  def published_entries
    @published_entries ||= curated_hierarchy_entries.select { |he| he.published == 1 }
  end

  def curated_hierarchy_entries
    return @curated_hierarchy_entries if @curated_hierarchy_entries
    @curated_hierarchy_entries = []
    if latest_revision
      @curated_hierarchy_entries += latest_revision.data_objects_hierarchy_entries.compact.map do |dohe|
        # this saves having to query for the data object later. I thought Rails would take
        # care of this, but they it doesn't look like it does
        dohe.data_object = self
        DataObjectTaxon.new(dohe)
      end
    end
    @curated_hierarchy_entries += all_curated_data_objects_hierarchy_entries.compact.map do |cdohe|
      # this saves having to query for the data object later. I thought Rails would take
      # care of this, but they it doesn't look like it does
      cdohe.data_object = self
      DataObjectTaxon.new(cdohe)
    end
    @curated_hierarchy_entries.compact!
    @curated_hierarchy_entries ||= []
  end

  def latest_revision
    @latest_revision ||=
      if is_the_latest_published_revision # we already know this is the latest...
        self
      else
        latest_published_version_in_same_language || revisions_by_date.first
      end
  end

  def is_subtype?(type)
    reload unless self.has_attribute?(:data_subtype_id)
    DataType.send("#{type}_type_ids".to_sym).include?(data_subtype_id)
  end

  def safe_object_title
    safe_attribute(:object_title)
  end

  def safe_data_type
    safe_attribute(:data_type_id) # We don't actually want this value, but it makes this possible (and safe):
    data_type
  end

  # TODO - find the culrpits and fix them!
  # Gives you the attribute regardless of whether it's been loaded in this instance. It's minimally but notably
  # expensive, so if you find this is being called often, you should probably widen your #select from wherever you
  # loaded your instance. In fact, when this method is called, it's a bit of a bad smell!
  def safe_attribute(attribute)
    @safe_attributes ||= {}
    @safe_attributes[attribute] ||= if has_attribute?(attribute)
        send(attribute)
      else
        DataObject.select(attribute.to_s).find(self).send(attribute)
      end
  end

  def add_recipient_user_making_object_modification(recipients, options = {})
    if options[:user]
      recipients << { user: options[:user], notification_type: :i_created_something,
                      frequency: NotificationFrequency.never }
      recipients << options[:user].watch_collection if options[:user].watch_collection
    end
  end

  def add_recipient_pages_affected(recipients, options = {})
    if options[:taxon_concept]
      recipients << options[:taxon_concept]
      recipients << { ancestor_ids: options[:taxon_concept].flattened_ancestor_ids }
    else
      self.curated_hierarchy_entries.each do |he|
        recipients << he.taxon_concept
        recipients << { ancestor_ids: he.taxon_concept.flattened_ancestor_ids }
      end
    end
  end

  def add_recipient_users_watching(recipients, options = {})
    if options[:taxon_concept]
      options[:taxon_concept].containing_collections.watch.each do |collection|
        collection.users.each do |user|
          user.add_as_recipient_if_listening_to(:new_data_on_my_watched_item, recipients)
        end
      end
    end
  end

  # NOTE - description required, and published will default to false from the DB, so you PROBABLLY want to specify it.
  def default_values # Ideally, these would be in the DB, but I didn't want to take that step.  ...yet.
    if defined?(PhusionPassenger)
      UUID.state_file(0664) # Makes the file writable, which we seem to need to do with Passenger...
    end
    self.guid ||= UUID.generate.gsub('-','')
    self.identifier ||= ''
    self.data_type_id ||= DataType.text.id
    self.mime_type_id ||= MimeType.find_by_translated(:label, 'text/plain').id
    self.location ||= ''
    self.latitude ||= 0
    self.longitude ||= 0
    self.altitude ||= 0
    self.object_url ||= ''
    self.thumbnail_url ||= ''
    self.object_title ||= ''
    self.language_id ||= Language.default.id
    self.license_id ||= License.default.id
    self.rights_statement ||= ''
    self.bibliographic_citation ||= ''
    self.source_url ||= ''
    self.data_rating ||= 2.5
  end

  def clean_values
    # Some HTML Allowed:
    self.description = Sanitize.clean(self.description.balance_tags, Sanitize::Config::RELAXED)
    # No HTML Allowed:
    self.rights_holder          = ERB::Util.h(self.rights_holder)
    self.rights_statement       = ERB::Util.h(self.rights_statement)
    self.bibliographic_citation = ERB::Util.h(self.bibliographic_citation)
    self.source_url             = ERB::Util.h(self.source_url)
  end

  def rights_required?
    license.show_rights_holder?
  end

  def latest_published_users_data_object
    latest_published_version_in_same_language.users_data_object if
      users_data_object && latest_published_version_in_same_language
  end
end
