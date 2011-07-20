require 'set'
require 'uuid'
require 'erb'

# Represents any kind of object imported from a ContentPartner, eg. an image, article, video, etc.  This is one
# of our primary models, and an awful lot of work occurs here.
class DataObject < SpeciesSchemaModel

  include ModelQueryHelper
  include EOL::ActivityLoggable

  belongs_to :data_type
  belongs_to :data_subtype, :class_name => DataType.to_s, :foreign_key => :data_subtype_id
  belongs_to :language
  belongs_to :license
  belongs_to :mime_type
  belongs_to :visibility
  belongs_to :vetted
  
  # this is the DataObjectTranslation record which links this translated object
  # to the original data object
  has_one :data_object_translation
  
  has_many :top_images
  has_many :feed_data_objects
  has_many :top_concept_images
  has_many :agents_data_objects
  has_many :data_objects_hierarchy_entries
  has_many :curated_data_objects_hierarchy_entries
  has_many :comments, :as => :parent
  has_many :data_objects_harvest_events
  has_many :harvest_events, :through => :data_objects_harvest_events
  has_many :data_object_tags, :class_name => DataObjectTags.to_s
  has_many :tags, :class_name => DataObjectTag.to_s, :through => :data_object_tags, :source => :data_object_tag
  has_many :data_objects_table_of_contents
  has_many :data_objects_info_items
  has_many :info_items, :through => :data_objects_info_items
  has_many :taxon_concept_exemplar_images
  # has_many :user_ignored_data_objects
  has_many :collection_items, :as => :object
  has_many :users_data_objects
  has_many :translations, :class_name => DataObjectTranslation.to_s, :foreign_key => :original_data_object_id
  has_many :users_data_objects_ratings, :foreign_key => 'data_object_guid', :primary_key => :guid
  has_many :all_comments, :class_name => Comment.to_s, :foreign_key => 'parent_id', :finder_sql => 'SELECT c.* FROM #{Comment.full_table_name} c JOIN #{DataObject.full_table_name} do ON (c.parent_id = do.id) WHERE do.guid=\'#{guid}\' AND c.parent_type = \'DataObject\''
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
    :include => [:data_type, :mime_type, :language, :license, :vetted, :visibility, {:info_items => :toc_item},
      {:hierarchy_entries => [:name, { :hierarchy => :agent }] }, {:agents_data_objects => [ { :agent => :user }, :agent_role]}]

  # this method is not just sorting by rating
  def self.sort_by_rating(data_objects, sort_order = [:type, :toc, :visibility, :vetted, :rating, :date])
    data_objects.sort_by do |obj|
      type_order = obj.data_type_id
      toc_view_order = (!obj.is_text? || obj.info_items.blank? || obj.info_items[0].toc_item.blank?) ? 0 : obj.info_items[0].toc_item.view_order
      vetted_view_order = obj.vetted.blank? ? 0 : obj.vetted.view_order
      visibility_view_order = 2
      visibility_view_order = 1 if obj.visibility_id == Visibility.preview.id
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

  def self.custom_filter(data_objects, type, status)

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
        allowed_visibilities << Visibility.inappropriate.id
      else
        allowed_vetted_status << Vetted.send(sta.to_sym).id
      end
    end unless status.blank?

    # we only delete objects by type, visibility or vetted respectively if allowed parameters exist
    data_objects.delete_if { |object|
      # filter by type: delete object if type is not allowed
      (! allowed_data_types.blank? && ! allowed_data_types.include?(object.data_type_id)) ||
      # photosynth: delete non-photosynth images if type does not also include images or all
      (! type.blank? && ! object.source_url.match(/http:\/\/photosynth.net/i) &&
        object.is_image? && type.include?('photosynth') && ! type.include?('image') && ! type.include?('all')) ||
      # filter by visibility: only delete by visibility if vetted status is blank or also not allowed
      (! allowed_visibilities.blank? && ! allowed_visibilities.include?(object.visibility_id) &&
        (allowed_vetted_status.blank? || ! allowed_vetted_status.include?(object.vetted_id))) ||
      # filter by vetted status: only delete by vetted if visibility is blank or also not allowed
      (! allowed_vetted_status.blank? && ! allowed_vetted_status.include?(object.vetted_id) &&
        (allowed_visibilities.blank? || ! allowed_visibilities.include?(object.visibility_id))) }

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
      if options[:user] && options[:user].is_content_partner? && d.data_supplier_agent.id == options[:user].agent.id
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
      :data_type => DataType.find_by_translated(:label, 'Text'),
      :rights_statement => '',
      :rights_holder => '',
      :mime_type_id => MimeType.find_by_translated(:label, 'text/plain').id,
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

    tc = TaxonConcept.find(all_params[:taxon_concept_id])
    udo = UsersDataObject.create(:user => user, :data_object => d, :taxon_concept => tc)
    d.users_data_objects << udo
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
      :mime_type_id => MimeType.find_by_translated(:label, 'text/plain').id,
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
      :mime_type_id => MimeType.find_by_translated(:label, 'text/plain').id,
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
    raise "Unable to build a UsersDataObject if user is nil" if user.nil?
    raise "Unable to build a UsersDataObject if DataObject is nil" if dato.nil?
    raise "Unable to build a UsersDataObject if taxon_concept_id is missing" if all_params[:taxon_concept_id].blank?
    udo = UsersDataObject.create(:user => user, :data_object => dato,
                              :taxon_concept => taxon_concept)
    dato.users_data_objects << udo

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

  def best_title
    return object_title unless object_title.blank?
    return toc_items.first.label unless toc_items.blank?
    return data_type.simple_type
  end
  alias :summary_name :best_title

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

  # 'owner' chooses someone responsible for this data object in order of preference
  def owner
    # rights holder is preferred
    return rights_holder, nil unless rights_holder.blank?

    # otherwise choose agents ordered by preferred role
    role_order = [ AgentRole.author, AgentRole.photographer, AgentRole.source,
                   AgentRole.editor, AgentRole.contributor ]
    role_order.each do |role|
      best_ado = agents_data_objects.find_all{|ado| ado.agent_role_id == role.id && ado.agent}
      break unless best_ado.empty?
    end

    # if we don't have any agents with the preferred roles then just pick one
    best_ado = agents_data_objects.find_all{|ado| ado.agent_role && ado.agent}
    return nil if best_ado.blank?
    return best_ado.first.agent.full_name, best_ado.first.agent.user

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

  def sound?
    return DataType.sound_type_ids.include?(data_type_id)
  end
  alias is_sound? sound?

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

  def sound_url
    if !object_cache_url.blank? && !object_url.blank?
      filename_extension = File.extname(object_url)
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
    raise I18n.t(:you_must_be_logged_in_to_add_tags)  unless user
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
        raise EOL::Exceptions::FailedToCreateTag.new("Failed to add #{key}:#{value} tag")
      end
    end
    tags.reset
    user.tags.reset
  end

  def public_tags
    DataObjectTags.public_tags_for_data_object self
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

  def update_solr_index(options)
    return false if options[:vetted_id].blank? && options[:visibility_id].blank?
    solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
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
    show_unpublished = (options[:user].is_content_partner? || options[:user].is_curator? || options[:user].is_admin?)

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
      if options[:user].is_content_partner?
        DataObject.preload_associations(image_data_objects,
          [ :hierarchy_entries => { :hierarchy => :agent } ],
          :select => {
            :hierarchy_entries => :hierarchy_id,
            :agents => [:id, :full_name, :homepage, :logo_cache_url] } )
      end
      if show_unpublished
        TaxonConcept.preload_associations(taxon_concept,
          [ :top_unpublished_concept_images => { :data_object => { :hierarchy_entries => { :hierarchy => :agent } } } ],
          :select => {
            :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating ],
            :hierarchy_entries => :hierarchy_id,
            :agents => [:id, :full_name, :homepage, :logo_cache_url] } )
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

    unless options[:skip_metadata]
      objects_with_metadata = eager_load_image_metadata(unique_image_objects[start..last].collect {|r| r.id})
      unique_image_objects[start..last] = objects_with_metadata unless objects_with_metadata.blank?
      if options[:user] && options[:user].is_curator? && options[:user].can_curate?(taxon_concept)
        DataObject.preload_associations(unique_image_objects[start..last], :users_data_objects_ratings, :conditions => "users_data_objects_ratings.user_id=#{options[:user].id}")
      end
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

  def untrust_reasons(hierarchy_entry)
    if hierarchy_entry.associated_by_curator
      object_id = CuratedDataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id_and_user_id(
        id,hierarchy_entry.id,hierarchy_entry.associated_by_curator
      ).id
      log = CuratorActivityLog.find_all_by_object_id_and_changeable_object_type_id_and_action_id(
        object_id, ChangeableObjectType.hierarchy_entry.id, Activity.untrusted.id
      ).last
      log ? log.untrust_reasons.collect{|ur| ur.untrust_reason_id} : []
    else
      log = CuratorActivityLog.find_all_by_object_id_and_changeable_object_type_id_and_action_id(
        id, ChangeableObjectType.data_object.id, Activity.untrusted.id
      ).last
      log ? log.untrust_reasons.collect{|ur| ur.untrust_reason_id} : []
    end
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

  def flickr_photo_id
    if matches = source_url.match(/flickr\.com\/photos\/.*?\/([0-9]+)\//)
      return matches[1]
    end
    nil
  end

  # TODO - we need to make sure that the user_id of curated_dohe is added to the HE...
  def curated_hierarchy_entries
    hierarchy_entries + curated_data_objects_hierarchy_entries.map do |cdohe|
      he = cdohe.hierarchy_entry
      he.associated_by_curator = cdohe.user
      he.vetted_id = cdohe.vetted_id
      he.visibility_id = cdohe.visibility_id
      he
    end
  end

  def published_entries
    curated_hierarchy_entries.select{ |he| he.published == 1 }
  end

  def first_concept_name
    first_hierarchy_entry.name.string rescue nil
  end

  def first_taxon_concept
    first_hierarchy_entry.taxon_concept rescue nil
  end

  def first_hierarchy_entry
    sorted_entries = HierarchyEntry.sort_by_vetted(published_entries)
    sorted_entries[0] rescue nil
  end

  # TODO - check this against rating_for_user ... why the difference?
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
  
  def description_teaser
    full_teaser = Sanitize.clean(description, :elements => %w[b i], :remove_contents => %w[table script])
    return nil if full_teaser.blank?
    truncated_teaser = full_teaser.split[0..10].join(' ').balance_tags + '...'
  end

  def added_by_user?
    users_data_objects && users_data_objects[0] && ! users_data_objects[0].user.blank?
  end

  def add_curated_association(user, hierarchy_entry)
    cdohe = CuratedDataObjectsHierarchyEntry.create(:hierarchy_entry_id => hierarchy_entry.id,
                                                    :data_object_id => self.id, :user_id => user.id,
                                                    :vetted_id => Vetted.trusted.id,
                                                    :visibility_id => Visibility.visible.id)
  end

  def remove_curated_association(user, hierarchy_entry)
    cdohe = CuratedDataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id(id, hierarchy_entry.id)
    raise EOL::Exceptions::ObjectNotFound if cdohe.nil?
    raise EOL::Exceptions::WrongCurator.new("user did not create this association") unless cdohe.user_id = user.id
    cdohe.destroy
  end
  
  def translated_from
    data_object_translation ? data_object_translation.original_data_object : nil
  end
  
  def translation_source
    org_tr = DataObjectTranslation.find_by_data_object_id(self.id)
    if org_tr
      return  org_tr.original_data_object 
    else
      return nil 
    end
  end

  
  def available_translations_data_objects(current_user)
    dobj_ids = []
    if !translations.empty?
      dobj_ids << id
      translations.each do |tr| 
        dobj_ids << tr.data_object.id
      end
    else 
      org_tr = DataObjectTranslation.find_by_data_object_id(self.id)
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
      dobjs = DataObject.filter_list_for_user(dobjs, {:user => current_user})      
      return dobjs
    end
    return nil     
  end
  
  
  def available_translation_languages(current_user)
    dobjs = available_translations_data_objects(current_user)
    if dobjs and !dobjs.empty?    
      lang_ids = []
      dobjs.each do |dobj| 
        lang_ids << dobj.language_id
      end    
  
      lang_ids = lang_ids.uniq
      if !lang_ids.empty? && lang_ids.length>1
        languages = Language.find_by_sql("SELECT * FROM languages WHERE id in (#{lang_ids.join(',')}) AND activated_on <= NOW() ORDER BY sort_order")      
        return languages
      end
    end
    return nil     

  end


end
