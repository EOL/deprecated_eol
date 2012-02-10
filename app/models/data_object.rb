require 'set'
require 'uuid'
require 'erb'

# Represents any kind of object imported from a ContentPartner, eg. an image, article, video, etc.  This is one
# of our primary models, and an awful lot of work occurs here.
class DataObject < SpeciesSchemaModel

  @@maximum_rating = 5.0
  @@minimum_rating = 0.5

  include ModelQueryHelper
  include EOL::ActivityLoggable

  belongs_to :data_type
  belongs_to :data_subtype, :class_name => DataType.to_s, :foreign_key => :data_subtype_id
  belongs_to :language
  belongs_to :license
  belongs_to :mime_type

  # this is the DataObjectTranslation record which links this translated object
  # to the original data object
  has_one :data_object_translation
  has_one :users_data_object

  has_many :top_images
  has_many :feed_data_objects
  has_many :top_concept_images
  has_many :agents_data_objects
  has_many :data_objects_hierarchy_entries
  has_many :curated_data_objects_hierarchy_entries
  has_many :comments, :as => :parent
  has_many :data_objects_harvest_events
  has_many :harvest_events, :through => :data_objects_harvest_events
  has_many :data_objects_table_of_contents
  has_many :data_objects_info_items
  has_many :info_items, :through => :data_objects_info_items
  has_many :taxon_concept_exemplar_images
  has_many :worklist_ignored_data_objects
  has_many :collection_items, :as => :object
  has_many :containing_collections, :through => :collection_items, :source => :collection
  has_many :translations, :class_name => DataObjectTranslation.to_s, :foreign_key => :original_data_object_id
  has_many :curator_activity_logs, :as => :object
  has_many :users_data_objects_ratings, :foreign_key => 'data_object_guid', :primary_key => :guid
  # has_many :all_comments, :class_name => Comment.to_s, :foreign_key => 'parent_id', :finder_sql => 'SELECT c.* FROM #{Comment.full_table_name} c JOIN #{DataObject.full_table_name} do ON (c.parent_id = do.id) WHERE do.guid=\'#{guid}\' AND c.parent_type = \'DataObject\''
  # TODO - I don't have time to make sure this fix isn't going to break or slow down other parts of the site, so
  # I'm calling this the 'better' method. DO NOT call this when using core relationships - it will not take just id and guid
  # from data_objects and you'll have way more data returned than you want
  has_many :all_comments, :class_name => Comment.to_s, :through => :all_versions, :source => :comments, :primary_key => :guid
  # the select_with_include library doesn't allow to grab do.* one time, then do.id later on. So in order
  # to use this with preloading I highly recommend doing DataObject.preload_associations(data_objects, :all_versions) on an array
  # of data_objects which already has everything else preloaded
  has_many :all_versions, :class_name => DataObject.to_s, :foreign_key => :guid, :primary_key => :guid, :select => 'id, guid'
  has_many :all_published_versions, :class_name => DataObject.to_s, :foreign_key => :guid, :primary_key => :guid, :order => "id desc"

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

  validates_presence_of :description, :if => :is_text?
  validates_length_of :rights_statement, :maximum => 300

  index_with_solr :keywords => [ :object_title ], :fulltexts => [ :description ]

  define_core_relationships :select => {
      :data_objects => '*',
      :agents => [:full_name, :homepage, :logo_cache_url],
      :agents_data_objects => :view_order,
      :names => :string,
      :hierarchy_entries => [ :published, :visibility_id, :taxon_concept_id ],
      :languages => :iso_639_1,
      :info_items => :schema_value,
      :data_types => :schema_value,
      :vetted => :view_order,
      :table_of_contents => '*',
      :licenses => '*' },
    :include => [:data_type, :mime_type, :language, :license, {:info_items => :toc_item},
      {:hierarchy_entries => [:name, { :hierarchy => :agent }] }, {:agents_data_objects => [ { :agent => :user }, :agent_role]}]

  def self.maximum_rating
    @@maximum_rating
  end

  def self.minimum_rating
    @@minimum_rating
  end

  # this method is not just sorting by rating
  def self.sort_by_rating(data_objects, taxon_concept = nil, sort_order = [:type, :toc, :visibility, :vetted, :rating, :date])
    data_objects.sort_by do |obj|
      obj_association = obj.association_with_exact_or_best_vetted_status(taxon_concept)
      obj_vetted = obj_association.vetted unless obj_association.nil?
      obj_visibility = obj_association.visibility unless obj_association.nil?
      type_order = obj.data_type_id
      toc_view_order = (!obj.is_text? || obj.info_items.blank? || obj.info_items[0].toc_item.blank?) ? 0 : obj.info_items[0].toc_item.view_order
      vetted_view_order = obj_vetted.blank? ? 0 : obj_vetted.view_order
      visibility_view_order = 2
      visibility_view_order = 1 if obj_visibility && obj_visibility.id == Visibility.preview.id
      visibility_view_order = 0 if obj_visibility.blank?
      inverted_rating = obj.data_rating * -1
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

  def self.custom_filter(data_objects, taxon_concept, type, status)

    return data_objects if data_objects.blank?

    # set types on which to filter or blank if no filter should be applied
    allowed_data_types = []
    type.each do |typ|
      if typ == 'all'
        allowed_data_types = []
        break
      end
      allowed_data_types.concat(DataType.video_type_ids) if typ == 'all' || typ == 'video'
      allowed_data_types.concat(DataType.image_type_ids) if typ == 'all' || typ == 'image' || typ == 'photosynth'
      allowed_data_types.concat(DataType.sound_type_ids) if typ == 'all' || typ == 'sound'
    end unless type.blank?

    # set visibilities and vetted statuses on which to filter or blank if no filter should be applied
    allowed_visibilities = []
    allowed_vetted_status = []
    status.each do |sta|
      if sta == 'all'
        allowed_vetted_status = []
        allowed_visibilities = []
        break
      elsif sta == 'inappropriate'
        allowed_visibilities << Vetted.inappropriate.id
      else
        allowed_vetted_status << Vetted.send(sta.to_sym).id
      end
    end unless status.blank?

    # we only delete objects by type, visibility or vetted respectively if allowed parameters exist
    data_objects.delete_if { |object|
      dato_association = object.association_with_exact_or_best_vetted_status(taxon_concept)
      dato_vetted_id = dato_association.vetted_id unless dato_association.nil?
      dato_visibility_id = dato_association.visibility_id unless dato_association.nil?
      # filter by type: delete object if type is not allowed
      (! allowed_data_types.blank? && ! allowed_data_types.include?(object.data_type_id)) ||
      # photosynth: delete non-photosynth images if type does not also include images or all
      (! type.blank? && ! object.source_url.match(/http:\/\/photosynth.net/i) &&
        object.is_image? && type.include?('photosynth') && ! type.include?('image') && ! type.include?('all')) ||
      # filter by visibility: only delete by visibility if vetted status is blank or also not allowed
      (! allowed_visibilities.blank? && ! allowed_visibilities.include?(dato_visibility_id) &&
        (allowed_vetted_status.blank? || ! allowed_vetted_status.include?(dato_vetted_id))) ||
      # filter by vetted status: only delete by vetted if visibility is blank or also not allowed
      (! allowed_vetted_status.blank? && ! allowed_vetted_status.include?(dato_vetted_id) &&
        (allowed_visibilities.blank? || ! allowed_visibilities.include?(dato_visibility_id))) }

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
      if options[:user].vetted == true && !options[:user].is_admin?
        vetted_ids = [Vetted.trusted.id]
      end
    end

    if options[:toc_id] == TocItem.wikipedia
      show_preview = true
    end

    # removing from the array the ones not mathching our criteria
    data_objects.compact.select do |d|
      tc = options[:taxon_concept]
      dato_association = d.association_with_exact_or_best_vetted_status(tc)
      dato_vetted_id = dato_association.vetted_id unless dato_association.nil?
      dato_visibility_id = dato_association.visibility_id unless dato_association.nil?
      # partners see all their PREVIEW or PUBLISHED objects
      # user can see preview objects
      if show_preview && dato_visibility_id == Visibility.preview.id
        true
      # Users can see text that they have added:
      elsif d.added_by_user? && d.users_data_object.user_id == options[:user].id
        true
      # otherwise object must be PUBLISHED and in the vetted and visibility selection
      elsif d.published == true && vetted_ids.include?(dato_vetted_id) && visibility_ids.include?(dato_visibility_id)
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
  # TODO: do we really need update_user_text and create_user_text methods?
  # A lot of repetition, why do we need to set all these defaults here?

  def self.update_user_text(all_params, user)
    old_dato = DataObject.find(all_params[:id])
    raise I18n.t(:dato_update_users_text_not_owner_exception) unless old_dato.user.id == user.id
    taxon_concept = old_dato.taxon_concept_for_users_text
    raise I18n.t(:dato_create_update_user_text_missing_taxon_id_exception) if taxon_concept.blank?

    do_params = {
      :guid => old_dato.guid,
      :identifier => '',
      :data_type_id => all_params[:data_object][:data_type_id],
      :mime_type_id => MimeType.find_by_translated(:label, 'text/plain').id,
      :location => '',
      :latitude => 0,
      :longitude => 0,
      :altitude => 0,
      :object_url => '',
      :thumbnail_url => '',
      :object_title => ERB::Util.h(all_params[:data_object][:object_title]), # No HTML allowed
      :description => Sanitize.clean(all_params[:data_object][:description].balance_tags, Sanitize::Config::RELAXED), #.allow_some_html,
      :language_id => all_params[:data_object][:language_id],
      :license_id => all_params[:data_object][:license_id],
      :rights_holder => ERB::Util.h(all_params[:data_object][:rights_holder]), # No HTML allowed
      :rights_statement => ERB::Util.h(all_params[:data_object][:rights_statement]), # No HTML allowed
      :bibliographic_citation => ERB::Util.h(all_params[:data_object][:bibliographic_citation]), # No HTML allowed
      :source_url => ERB::Util.h(all_params[:data_object][:source_url]), # No HTML allowed
      :published => 1,
      :data_rating => old_dato.data_rating
    }

    # this is to support problems with things on version2 and prelaunch and will NOT be needed later:
    do_params[:vetted_id] = Vetted.untrusted.id if DataObject.column_names.include?('vetted_id')
    do_params[:visibility_id] = Visibility.visible.id if DataObject.column_names.include?('visibility_id')

    new_dato = DataObject.new(do_params)
    new_dato.toc_items << TocItem.find(all_params[:data_object][:toc_items][:id])

    unless all_params[:references].blank?
      all_params[:references].each do |reference|
        if reference.strip != ''
          new_dato.refs << Ref.new(:full_reference => reference, :user_submitted => true, :published => 1, :visibility => Visibility.visible)
        end
      end
    end

    new_dato.save
    return new_dato if new_dato.nil? || new_dato.errors.any?

    # We need to set all previous revisions of this data object to unpublished
    DataObject.update_all("published = 0", "id != #{new_dato.id} AND guid = '#{new_dato.guid}'")

    no_current_but_new_visibility = Visibility.visible
    current_or_new_vetted = old_dato.users_data_object.vetted
    if user.is_curator? || user.is_admin?
      if user.assistant_curator?
        current_or_new_vetted = (current_or_new_vetted == Vetted.trusted) ? Vetted.trusted : Vetted.unknown
      else
        current_or_new_vetted = Vetted.trusted
      end
    else
      current_or_new_vetted = Vetted.unknown
    end

    DataObjectsTaxonConcept.find_or_create_by_taxon_concept_id_and_data_object_id(taxon_concept.id, new_dato.id)

    udo = UsersDataObject.create(:user => user, :data_object => new_dato, :taxon_concept => taxon_concept,
                                 :visibility => no_current_but_new_visibility, :vetted => current_or_new_vetted)
    new_dato.users_data_object = udo
    new_dato.update_solr_index
    new_dato
  end

  def self.create_user_text(all_params, user, taxon_concept)

    raise I18n.t(:dato_create_user_text_missing_user_exception) if user.nil?
    raise I18n.t(:dato_create_user_text_missing_taxon_id_exception) if taxon_concept.blank?

    if defined?(PhusionPassenger)
      UUID.state_file(0664) # Makes the file writable, which we seem to need to do with Passenger...
    end

    rights_holder = ERB::Util.h(all_params[:data_object][:rights_holder])
    rights_holder ||= user.full_name

    do_params = {
      :guid => UUID.generate.gsub('-',''),
      :identifier => '',
      :data_type_id => all_params[:data_object][:data_type_id],
      :mime_type_id => MimeType.find_by_translated(:label, 'text/plain').id,
      :location => '',
      :latitude => 0,
      :longitude => 0,
      :altitude => 0,
      :object_url => '',
      :thumbnail_url => '',
      :object_title => ERB::Util.h(all_params[:data_object][:object_title]), # No HTML allowed
      :description => Sanitize.clean(all_params[:data_object][:description].balance_tags, Sanitize::Config::RELAXED), #.allow_some_html,
      :language_id => all_params[:data_object][:language_id],
      :license_id => all_params[:data_object][:license_id],
      :rights_holder => rights_holder, # No HTML allowed
      :rights_statement => ERB::Util.h(all_params[:data_object][:rights_statement]), # No HTML allowed
      :bibliographic_citation => ERB::Util.h(all_params[:data_object][:bibliographic_citation]), # No HTML allowed
      :source_url => ERB::Util.h(all_params[:data_object][:source_url]), # No HTML allowed
      :published => 1
    }

    # this is to support problems with things on version2 and prelaunch and will NOT be needed later:
    do_params[:vetted_id] = Vetted.untrusted.id if DataObject.column_names.include?('vetted_id')
    do_params[:visibility_id] = Visibility.visible.id if DataObject.column_names.include?('visibility_id')

    dato = DataObject.new(do_params)
    dato.toc_items << TocItem.find(all_params[:data_object][:toc_items][:id])

    unless all_params[:references].blank?
      all_params[:references].each do |reference|
        if reference.strip != ''
          dato.refs << Ref.new(:full_reference => reference, :user_submitted => true, :published => 1, :visibility => Visibility.visible)
        end
      end
    end

    dato.save
    return dato if dato.nil? || dato.errors.any?

    DataObjectsTaxonConcept.find_or_create_by_taxon_concept_id_and_data_object_id(taxon_concept.id, dato.id)

    default_vetted_status = user.min_curator_level?(:full) || user.is_admin? ? Vetted.trusted : Vetted.unknown
    udo = UsersDataObject.create(:user => user, :data_object => dato, :taxon_concept => taxon_concept, :visibility => Visibility.visible, :vetted => default_vetted_status)
    dato.update_solr_index
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

  def rate(user, new_rating)
    existing_ratings = UsersDataObjectsRating.find_all_by_data_object_guid(guid)
    users_current_ratings, other_ratings = existing_ratings.partition { |r| r.user_id == user.id }

    weight = user.is_curator? ? user.curator_level.rating_weight : 1
    new_udor = nil
    if users_current_ratings.blank?
      new_udor = UsersDataObjectsRating.create(:data_object_guid => guid, :user_id => user.id,
                                               :rating => new_rating, :weight => weight)
    elsif (new_udor = users_current_ratings.first).rating != new_rating
      new_udor.update_attribute(:rating, new_rating)
      new_udor.update_attribute(:weight, weight)
    end

    self.update_attribute(:data_rating, ratings_calculator(other_ratings + [new_udor]))
  end

  def recalculate_rating(debug = false)
    ratings = UsersDataObjectsRating.find_all_by_data_object_guid(guid)
    self.update_attribute(:data_rating, ratings_calculator(ratings, debug))
    self.data_rating
  end

  def ratings_calculator(ratings, debug = false)
    count = 0
    self.data_rating = ratings.blank? ? 2.5 : ratings.inject(0) { |sum, r|
      if r.respond_to?(:weight)
        sum += (r.rating * r.weight)
        count += r.weight
        logger.warn ".. Giving score of #{r.rating} weight of #{r.weight}." if debug
      else
        sum += r.rating
        count += 1
        logger.warn ".. Giving score of #{r.rating} weight of 1 (it had no weight specified)." if debug
      end
      sum
    }.to_f / count
  end

  def rating_from_user(u)
    ratings_from_user = users_data_objects_ratings.select{ |udor| udor.user_id == u.id }
    return ratings_from_user[0] unless ratings_from_user.blank?
  end

  def safe_rating
    return self.data_rating if self.data_rating >= @@minimum_rating && self.data_rating <= @@maximum_rating
    logger.warn "!! WARNING: data object #{self.id} had a data_rating of #{self.data_rating}. Attempted fix:"
    rating = recalculate_rating(true)
    if rating <= @@minimum_rating
      logger.error "** ERROR: data object #{self.id} had a *calculated* rating of #{rating}."
      return @@minimum_rating
    elsif rating >= @@maximum_rating
      logger.error "** ERROR: data object #{self.id} had a *calculated* rating of #{rating}."
      return @@maximum_rating
    else
      return rating
    end
  end

  # Add a comment to this data object
  def comment(user, body)
    comment = comments.create :user_id => user.id, :body => body
    user.comments.reload # be friendly - update the user's comments automatically
    return comment
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

  def citable_data_supplier
    return nil if data_supplier_agent.blank?
    EOL::Citable.new( :agent_id => data_supplier_agent.id,
                                  :link_to_url => data_supplier_agent.homepage,
                                  :display_string => data_supplier_agent.full_name,
                                  :logo_cache_url => data_supplier_agent.logo_cache_url,
                                  :type =>I18n.t(:supplier))
  end

  def citable_rights_holder
    return nil if rights_holder.blank?
    EOL::Citable.new( :display_string => rights_holder, :type => I18n.t("rights_holder"))
  end

  def citable_entities
    citables = []

    unless license.blank?
      citables << EOL::Citable.new( :link_to_url => license.source_url,
                                    :display_string => license.description,
                                    :logo_path => license.logo_url,
                                    :type => I18n.t("license"))
    end

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
                                    :type => I18n.t("rights"))
    end

    unless rights_holder.blank?
      citables << citable_rights_holder
    end

    unless location.blank?
      citables << EOL::Citable.new( :display_string => location,
                                    :type => I18n.t(:location))
    end

    unless source_url.blank?
      citables << EOL::Citable.new( :link_to_url => source_url,
                                    :display_string => 'View original data object',
                                    :type => I18n.t("source_url"))
    end

    unless created_at.blank? || created_at == '0000-00-00 00:00:00'
      citables << EOL::Citable.new( :display_string => created_at.strftime("%B %d, %Y"),
                                    :type => I18n.t("indexed"))
    end

    unless bibliographic_citation.blank?
      citables << EOL::Citable.new( :display_string => bibliographic_citation,
                                    :type => I18n.t("citation"))
    end

    citables
  end

  # need supplier as content partner object, is this right ?
  def content_partner
    # TODO - change this, since it would be more efficient to go through hierarchy_entries... but the first attempt
    # (using hierarchy_entries.first) failed to find the correct data in observed cases. WEB-2850
    hierarchy_entries.first.hierarchy.resource.content_partner rescue (harvest_events.last.resource.content_partner rescue nil)
  end

  # 'owner' chooses someone responsible for this data object in order of preference
  def owner
    # rights holder is preferred
    return rights_holder, nil unless rights_holder.blank?

    # otherwise choose agents ordered by preferred agent_role
    role_order = [ AgentRole.author, AgentRole.photographer, AgentRole.source,
                   AgentRole.editor, AgentRole.contributor ]
    role_order.each do |role|
      best_ado = agents_data_objects.find_all{|ado| ado.agent_role_id == role.id && ado.agent}
      break unless best_ado.blank?
    end

    # if we don't have any agents with the preferred roles then just pick one
    best_ado = agents_data_objects.find_all{|ado| ado.agent_role && ado.agent} if best_ado.blank?
    return nil if best_ado.blank?
    # TODO: optimize this, preload agents and users on DataObject or something
    return best_ado.first.agent.full_name, User.find_by_agent_id(best_ado.first.agent.id)

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
    return all_comments if (not user.nil?) and user.is_admin?
    all_comments.find_all {|c| c.visible? }
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
    self.is_image? && DataType.map_type_ids.include?(data_subtype_id)
  end
  alias is_image_map? image_map?

  def iucn?
    return data_type_id == DataType.iucn.id
  end
  alias is_iucn? iucn?

  def self.image_cache_path(cache_url, size = '580_360', specified_content_host = nil)
    return if cache_url.blank? || cache_url == 0
    size = size ? "_" + size.to_s : ''
    ContentServer.cache_path(cache_url, specified_content_host) + "#{size}.#{$SPECIES_IMAGE_FORMAT}"
  end

  def has_thumbnail_cache?
    return false if thumbnail_cache_url.blank? or thumbnail_cache_url == 0
    return true
  end

  def has_object_cache_url?
    return false if object_cache_url.blank? or object_cache_url == 0
    return true
  end

  def is_subtype_map?
    return true if self.data_subtype.id == DataType.map.id
    false
  end

  def map_from_DiscoverLife?
    last_harvest_event = self.harvest_events.last rescue nil
    if last_harvest_event
      if r = last_harvest_event.resource
        return true if r.from_DiscoverLife? and self.is_subtype_map?
      end
    end
    false
  end

  def access_image_from_remote_server(size)
    return true if ['580_360', :orig].include?(size) && self.map_from_DiscoverLife?
    # we can add here other criterias for image to be hosted remotely
    false
  end

  def thumb_or_object(size = '580_360', specified_content_host = nil)
    if self.is_video? || self.is_sound?
      return DataObject.image_cache_path(thumbnail_cache_url, size, specified_content_host)
    elsif has_object_cache_url?
      if access_image_from_remote_server(size)
        return self.object_url
      else
        return DataObject.image_cache_path(object_cache_url, size, specified_content_host)
      end
    else
      return '#' # Really, this is an error, but we want to handle it pseudo-gracefully.
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
      return ContentServer.cache_path(object_cache_url) + filename_extension
    elsif mime_type.label('en') == 'audio/mpeg'
      return has_object_cache_url? ? ContentServer.cache_path(object_cache_url) + '.mp3' : ''
    else
      return object_url
    end
  end

  def video_url
    if !object_cache_url.blank? && !object_url.blank?
      filename_extension = File.extname(object_url)
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
  def get_taxon_concepts(opts = {})
    return @taxon_concepts if @taxon_concepts
    if created_by_user?
      @taxon_concepts = [taxon_concept_for_users_text]
    else
      @taxon_concepts = taxon_concepts
    end
    if opts[:published]
      published, unpublished = @taxon_concepts.partition {|item| TaxonConcept.find(item.id).published?}
      @taxon_concepts = (!published.empty? || opts[:published] == :strict) ? published : unpublished
    end
    @taxon_concepts
  end

  def linked_taxon_concept
    get_taxon_concepts.first
  end

  def update_solr_index
    if self.published
      EOL::Solr::DataObjects.reindex_single_object(self)
    else
      # hidden, so delete it from solr
      solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
      solr_connection.delete_by_id(self.id)
    end
  end

  def in_wikipedia?
    toc_items.include?(TocItem.wikipedia)
  end

  def publish_wikipedia_article(taxon_concept)
    dato_association = self.association_with_exact_or_best_vetted_status(taxon_concept)
    return false unless in_wikipedia?
    return false unless dato_association.visibility_id == Visibility.preview.id

    SpeciesSchemaModel.connection.execute("UPDATE data_objects SET published=0 WHERE guid='#{guid}'");
    reload

    dato_vetted = self.vetted_by_taxon_concept(taxon_concept)
    dato_vetted_id = dato_vetted.id unless dato_vetted.nil?
    dato_visibility = self.visibility_by_taxon_concept(taxon_concept)
    dato_visibility_id = dato_visibility.id unless dato_visibility.nil?

    dato_association.visibility_id = Visibility.visible.id
    dato_association.vetted_id = Vetted.trusted.id
    dato_association.save!
    self.published = 1
    self.save!
  end

  def visible_references(options = {})
    @all_refs ||= refs.delete_if {|r| r.published != 1 || r.visibility_id != Visibility.visible.id}
  end

  def to_s
    "[DataObject id:#{id}]"
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

  # this method will be run on an instance of an object unlike the above methods. It is best to have preloaded
  # all_published_versions in order for this method to be efficient
  def latest_published_version
    all_published_versions.sort_by{ |d| d.id }.reverse.first rescue nil
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
        if(post.data_type_id == DataType.text.id)then obj_tc_id["datatype#{post.do_id}"] = "text"
                                  else obj_tc_id["datatype#{post.do_id}"] = "image"
        end
      end
    end
    return obj_tc_id
  end

  # To retrieve an association for the data object by using given hierarchy entry
  def association_for_hierarchy_entry(hierarchy_entry)
    association = data_objects_hierarchy_entries.detect{ |dohe| dohe.hierarchy_entry_id == hierarchy_entry.id }
    if association.blank?
      association = curated_data_objects_hierarchy_entries.detect{ |dohe| dohe.hierarchy_entry_id == hierarchy_entry.id }
    end
    association
  end

  # To retrieve an association for the data object by using given taxon concept
  def association_for_taxon_concept(taxon_concept)
    association = data_objects_hierarchy_entries.detect{ |dohe| dohe.hierarchy_entry.taxon_concept_id == taxon_concept.id }
    if association.blank?
      association = curated_data_objects_hierarchy_entries.detect{ |dohe| dohe.hierarchy_entry.taxon_concept_id == taxon_concept.id }
    end
    if association.blank?
      association = users_data_object if users_data_object && users_data_object.taxon_concept_id == taxon_concept.id
    end
    association
  end

  # To retrieve an association for the data object if taxon concept and hierarchy entry are unknown
  def association_with_best_vetted_status
    associations = (data_objects_hierarchy_entries + curated_data_objects_hierarchy_entries + [users_data_object]).compact
    return if associations.empty?
    associations.sort_by{ |a| a.vetted.view_order }.first
  end

  # To retrieve the vetted status of an association by using given hierarchy entry
  def vetted_by_hierarchy_entry(hierarchy_entry)
    association = association_for_hierarchy_entry(hierarchy_entry)
    return association.vetted unless association.blank?
    return nil
  end

  # To retrieve the vetted status of an association by using given taxon concept
  def vetted_by_taxon_concept(taxon_concept, options={})
    association = association_for_taxon_concept(taxon_concept)
    return association.vetted unless association.blank?
    if options[:find_best] == true && association = association_with_best_vetted_status
      return association.vetted
    end
    return nil
  end

  # To retrieve an exact association(if exists) for the given taxon concept,
  # otherwise retrieve an association with best vetted status.
  def association_with_exact_or_best_vetted_status(taxon_concept)
    association = association_for_taxon_concept(taxon_concept)
    return association unless association.blank?
    association = association_with_best_vetted_status
    return association
  end

  # To retrieve the visibility status of an association by using taxon concept
  def visibility_by_taxon_concept(taxon_concept, options={})
    association = association_for_taxon_concept(taxon_concept)
    return association.visibility unless association.blank?
    if options[:find_best] == true && association = association_with_best_vetted_status
      return association.visibility
    end
    return nil
  end

  # To retrieve the reasons provided while untrusting or hiding an association
  def reasons(hierarchy_entry, activity)
    if hierarchy_entry.class == UsersDataObject
      log = CuratorActivityLog.find_all_by_object_id_and_changeable_object_type_id_and_activity_id(
        id, ChangeableObjectType.users_data_object.id, activity.id
      ).last
      log ? log.untrust_reasons.collect{|ur| ur.untrust_reason_id} : []
    elsif hierarchy_entry.associated_by_curator
      log = CuratorActivityLog.find_all_by_object_id_and_changeable_object_type_id_and_activity_id_and_hierarchy_entry_id(
        id, ChangeableObjectType.curated_data_objects_hierarchy_entry.id, activity.id, hierarchy_entry.id
      ).last
      log ? log.untrust_reasons.collect{|ur| ur.untrust_reason_id} : []
    else
      log = CuratorActivityLog.find_all_by_object_id_and_changeable_object_type_id_and_activity_id_and_hierarchy_entry_id(
        id, ChangeableObjectType.data_objects_hierarchy_entry.id, activity.id, hierarchy_entry.id
      ).last
      log ? log.untrust_reasons.collect{|ur| ur.untrust_reason_id} : []
    end
  end

  # To retrieve the reasons provided while untrusting an association
  def untrust_reasons(hierarchy_entry)
    reasons(hierarchy_entry, Activity.untrusted)
  end

  # To retrieve the reasons provided while hiding an association
  def hide_reasons(hierarchy_entry)
    reasons(hierarchy_entry, Activity.hide)
  end

  def self.generate_dataobject_stats(harvest_event_id)
    ids = connection.select_values("SELECT do.id
      FROM data_objects_harvest_events dohe
      JOIN data_objects do ON dohe.data_object_id = do.id
      WHERE dohe.harvest_event_id = #{harvest_event_id}")
    data_objects = DataObject.find_all_by_id(ids, :include => [ :data_type ])

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

  def flickr_photo_id
    if matches = source_url.match(/flickr\.com\/photos\/.*?\/([0-9]+)\//)
      return matches[1]
    end
    nil
  end

  # TODO - we need to make sure that the user_id of curated_dohe is added to the HE...
  def curated_hierarchy_entries
    dohes = data_objects_hierarchy_entries.map { |dohe|
      he = dohe.hierarchy_entry
      if he
        he.vetted_id = dohe.vetted_id
        he.visibility_id = dohe.visibility_id
      end
      he
    }.compact
    cdohes = curated_data_objects_hierarchy_entries.map { |cdohe|
      he = cdohe.hierarchy_entry
      if he
        he.associated_by_curator = cdohe.user
        he.vetted_id = cdohe.vetted_id
        he.visibility_id = cdohe.visibility_id
      end
      he
    }.compact
    dohes + cdohes
  end

  def published_entries
    curated_hierarchy_entries.select{ |he| he.published == 1 }
  end

  def unpublished_entries
    curated_hierarchy_entries.select{ |he| he.published != 1 }
  end

  # This method adds users data object entry in the list of entries to retrieve all associations
  def all_associations(options = {:with_unpublished => false})
    unless options[:with_unpublished]
      entries_with_published_taxon_concepts = published_entries ? published_entries.map{ |pe| pe.taxon_concept.published? ? pe : nil } : nil
      udo_with_published_taxon_concept = users_data_object && users_data_object.taxon_concept.published? ? users_data_object : nil
      (entries_with_published_taxon_concepts + [udo_with_published_taxon_concept]).compact
    else
      (published_entries + unpublished_entries + [users_data_object]).compact
    end
  end

  def first_concept_name
    first_hierarchy_entry.name.string rescue nil
  end

  def first_taxon_concept
    first_hierarchy_entry.taxon_concept rescue nil
  end

  def first_hierarchy_entry(options={})
    sorted_entries = HierarchyEntry.sort_by_vetted(published_entries)
    best_first_entry = sorted_entries[0] rescue nil
    if best_first_entry.nil? && options[:include_preview_entries]
      sorted_entries = HierarchyEntry.sort_by_vetted(curated_hierarchy_entries)
      best_first_entry = sorted_entries[0] rescue nil
    end
    best_first_entry
  end

  def best_title
    return object_title unless object_title.blank?
    return toc_items.first.label unless toc_items.blank?
    return data_type.simple_type
  end
  alias :summary_name :best_title

  def short_title
    return object_title unless object_title.blank?
    # TODO - ideally, we should extract some of the logic from data_objects/show to make this "Image of Procyon Lotor".
    return data_type.label if description.blank?
    st = description.gsub(/\n.*$/, '')
    st.truncate(32)
  end

  def description_teaser
    full_teaser = Sanitize.clean(description[0..300], :elements => %w[b i], :remove_contents => %w[table script])
    return nil if full_teaser.blank?
    truncated_teaser = full_teaser.split[0..10].join(' ').balance_tags
    truncated_teaser << '...' if full_teaser.length > truncated_teaser.length
    truncated_teaser
  end

  def added_by_user?
    users_data_object && !users_data_object.user.blank?
  end

  def add_curated_association(user, hierarchy_entry)
    cdohe = CuratedDataObjectsHierarchyEntry.create(:hierarchy_entry_id => hierarchy_entry.id,
                                                    :data_object_id => self.id, :user_id => user.id,
                                                    :vetted_id => Vetted.trusted.id,
                                                    :visibility_id => Visibility.visible.id)
    if self.data_type == DataType.image
      TopImage.find_or_create_by_hierarchy_entry_id_and_data_object_id(hierarchy_entry.id, self.id, :view_order => 1)
      TopConceptImage.find_or_create_by_taxon_concept_id_and_data_object_id(hierarchy_entry.taxon_concept.id, self.id, :view_order => 1)
    end
    DataObjectsTaxonConcept.find_or_create_by_taxon_concept_id_and_data_object_id(hierarchy_entry.taxon_concept.id, self.id)
  end

  def remove_curated_association(user, hierarchy_entry)
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id(id, hierarchy_entry.id)
    raise EOL::Exceptions::ObjectNotFound if cdohe.nil?
    raise EOL::Exceptions::WrongCurator.new("user did not create this association") unless cdohe.user_id = user.id
    cdohe.destroy
    if self.data_type == DataType.image
      tci_exists = TopConceptImage.find_by_taxon_concept_id_and_data_object_id(hierarchy_entry.taxon_concept.id, self.id)
      tci_exists.destroy unless tci_exists.nil?
      ti_exists = TopImage.find_by_hierarchy_entry_id_and_data_object_id(hierarchy_entry.id, self.id)
      ti_exists.destroy unless ti_exists.nil?
    end
    dotc_exists = DataObjectsTaxonConcept.find_by_taxon_concept_id_and_data_object_id(hierarchy_entry.taxon_concept.id, self.id)
    dotc_exists.destroy unless dotc_exists.nil?
  end

  def translated_from
    data_object_translation ? data_object_translation.original_data_object : nil
  end
  alias :translation_source :translated_from

  def available_translations_data_objects(current_user, taxon)
    dobj_ids = []
    if !translations.empty?
      dobj_ids << id
      translations.each do |tr|
        dobj_ids << tr.data_object.id
      end
    else
      org_tr = data_object_translation
      if org_tr
        org_dobj = org_tr.original_data_object
        dobj_ids << org_dobj.id
        org_dobj.translations.each do |tr|
          dobj_ids << tr.data_object.id
        end
      end
    end
    dobj_ids = dobj_ids.uniq
    if !dobj_ids.empty? && dobj_ids.length>1
      dobjs = DataObject.find_by_sql("SELECT do.* FROM data_objects do INNER JOIN languages l on (do.language_id = l.id) WHERE do.id in (#{dobj_ids.join(',')}) AND l.activated_on <= NOW() ORDER BY l.sort_order")
      if !taxon.nil?
        dobjs = DataObject.filter_list_for_user(dobjs, {:user => current_user, :taxon_concept => taxon})
      end
      return dobjs
    end
    return nil
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
    base_index_hash = {
      'activity_log_unique_key' => "UsersDataObject_#{id}",
      'activity_log_type' => 'UsersDataObject',
      'activity_log_id' => self.users_data_object.id,
      'action_keyword' => options[:keyword],
      'date_created' => self.updated_at.solr_timestamp || self.created_at.solr_timestamp }
    base_index_hash[:user_id] = options[:user].id if options[:user]
    EOL::Solr::ActivityLog.index_activities(base_index_hash, activity_logs_affected(options))
  end

  def activity_logs_affected(options)
    logs_affected = {}
    # activity feed of user making comment
    logs_affected['User'] = [ options[:user].id ] if options[:user]
    watch_collection_id = options[:user].watch_collection.id rescue nil
    logs_affected['Collection'] = [ watch_collection_id ] if watch_collection_id
    # this is when the object is first added. Using the passed-in value to prevent potential slave lag interference
    if options[:taxon_concept]
      logs_affected['TaxonConcept'] = [ options[:taxon_concept].id ]
      logs_affected['AncestorTaxonConcept'] = options[:taxon_concept].flattened_ancestor_ids
    else
      self.curated_hierarchy_entries.each do |he|
        logs_affected['TaxonConcept'] ||= []
        logs_affected['TaxonConcept'] << he.taxon_concept_id
        logs_affected['AncestorTaxonConcept'] ||= []
        logs_affected['AncestorTaxonConcept'] |= he.taxon_concept.flattened_ancestor_ids
      end
    end
    logs_affected
  end

  def contributing_user
    if users_data_object
      users_data_object.user
    else
      content_partner.user
    end
  end

end
