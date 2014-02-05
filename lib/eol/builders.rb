# A bunch of methods to let you easily build all kinds of EOL data, including data objects, users, and taxon_concepts.
#
# This is  NOT meant for production!  It's meant for administrative tasks like specs and scenarios.
# 
# NOTE - Taxon Concepts are too complex to include here ( TODO - weird ).  See TaxonConceptBuilder for that.
#
# IMPORTANT NOTE - There is a HUGE section after the module which monkey-patches our models. TODO - reconsider.
module EOL
  module Builders

    def build_data_object(type, desc, options = {})
      dato_builder = EOL::DataObjectBuilder.new(type, desc, options)
      dato_builder.dato
    end

    # Builds a HierarchyEntry and creates all of the ancillary relationships.  Returns the HierarchyEntry.
    #
    # This takes four arguments.  The first is the depth of the HE (0 for kingdom, and so on), defaulting to
    # 0. The second is the taxon concept that this relates to. The third argument is the Name object associated
    # with this HE.  The last is a hash of options.  Some possible values:
    #
    #   +hierarchy+::
    #     Which Hierarchy to link this to.  Defaults to... uhhh... the default (Hierarchy#default).
    #   +identifier+::
    #     The "foreign key" that the Resource supplying this refers to this HE as, used for outlinking.
    #   +map+::
    #     If defined, this HE will be marked as having a map, otherwise marked as not having one.
    #   +parent_id+::
    #     Which HierarchyEntry (by *ID*, not object) this links to.
    #
    # TODO LOW_PRIO - the arguments to this method are lame and should be options with reasonable defaults.
    def build_hierarchy_entry(depth, tc, name, options = {})
      he = HierarchyEntry.gen(:hierarchy     => options[:hierarchy] || Hierarchy.default, # TODO - This should *really*
                                # be the H associated with the Resource that's being "harvested"... technically, CoL
                                # shouldn't even have Data Objects. Hierarchy.last may be clever enough, really.  I
                                # just don't want to change this *right now*--I have other problems...
                              :parent_id     => options[:parent_id] || 0,
                              :identifier    => options[:identifier] || '',
                              :depth         => depth,
                              # Cheating. As long as *we* created Ranks with a scenario, this works:
                              :rank_id       => options[:rank_id] || 0,
                              :vetted_id       => options[:vetted_id] || Vetted.trusted.id,
                              :taxon_concept => tc,
                              :name          => name)
      # TODO - Create two AgentsHierarchyEntry(ies); you want "Source Database" and "Compiler" as partner roles
      return he
    end

    def build_taxon_concept(options = {})
      TaxonConceptBuilder.build(options)
    end

    # TODO - stop using this and switch to either #gen_curator or #build_curator.
    def create_curator
      curator = User.gen(:username => 'curator_for_tc', :password => 'password', :credentials => 'Curator', :curator_scope => 'very scoped')
      curator.grant_curator
      curator.save!
      return curator
    end

    # A dumbed-down version of #build_curator
    def gen_curator(options = {})
      options = {
        curator_level:    options[:curator_level] || CuratorLevel.full,
        curator_approved: true,
        curator_scope:    'scope',
        credentials:      'Curator'
      }.merge(options)
      curator = User.gen(options)
    end

    # Curators are tricky... not just a plain model, but require some activity before they are "active":
    # The first argument is the TaxonConcept or HierarchyEntry to associate the curator to; the second argument is
    # the options hash to use when building the User model.
    def build_curator(entry, options = {})
      curator_level = options[:level].nil? ? :full : options[:level]
      options.delete :level
      entry ||= FactoryGirl.create(:hierarchy_entry)
      tc = nil # scope
      if entry.is_a? TaxonConcept
        tc    = entry
        entry = tc.entry
      end
      tc ||= entry.taxon_concept
      options = {
        curator_approved: true,
        curator_scope: 'scope',
        credentials: 'Curator'
      }.merge(options)

      # These two do "extra work", so I didn't want to use the merge on these (because they would be calculated even
      # if not used:
      options[:curator_verdict_by] ||= FactoryGirl.create(:user)
      options[:curator_verdict_at] ||= 48.hours.ago

      curator = User.gen(options)
      curator.grant_curator(curator_level)

      cot = ChangeableObjectType.gen_if_not_exists(:ch_object_type => 'taxon_concept')
      CuratorActivityLog.gen(:user => curator, :taxon_concept => tc, :changeable_object_type => cot,
                              :target_id => tc.id)

      return curator
    end

    # Create a data object in the IUCN hierarchy. Can take options for :hierarchy and :event, both of which default to the usual IUCN
    # values (which will be created if they don't exist already). Can also take :depth, though I'm not sure that matters much yet.  :name
    # is another option (note this is a Name *object*, not a string); it will default to the TaxonConcept's first name.
    #
    # Returns the data object built.
    def build_iucn_entry(tc, status, options = {})
      options[:hierarchy] ||= iucn_hierarchy
      options[:event]     ||= iucn_harvest_event
      options[:depth]     ||= 3 # Arbitrary, really.
      options[:name]      ||= tc.taxon_concept_names.first.name
      iucn_he = build_hierarchy_entry(options[:depth], tc, options[:name], :hierarchy => options[:hierarchy])
      HarvestEventsHierarchyEntry.gen(:hierarchy_entry => iucn_he, :harvest_event => options[:event])
      build_data_object('IUCN', status, :hierarchy_entry => iucn_he, :published => 1)
    end

    def find_or_build_hierarchy(label)
      Hierarchy.find_by_label(label) || Hierarchy.gen(:label => label)
    end

    def find_or_build_resource(title, options = {})
      first_try = Resource.find_by_title(title)
      return first_try unless first_try.nil?
      options[:content_partner] ||= ContentPartner.gen(:full_name => 'Test content partner')
      resource = Resource.gen(:title => title, :content_partner => options[:content_partner])
      return resource
    end

    def find_or_build_harvest_event(resource)
      HarvestEvent.find_by_resource_id(resource.id) || HarvestEvent.gen(:resource => resource)
    end

    def iucn_hierarchy
      find_or_build_hierarchy('IUCN')
    end

    def default_harvest_event
      find_or_build_harvest_event(find_or_build_resource('Test Framework Import', :content_partner => ContentPartner.last))
    end

    def gbif_harvest_event
      find_or_build_harvest_event(find_or_build_resource('Initial GBIF Import'))
    end

    def iucn_harvest_event
      find_or_build_harvest_event(Resource.iucn)
    end

  end
end

# MONKEY-PATCHING OUR MODELS...
#
# The problem is that we have *no* methods that make relating data between models easy... because this project is
# largely read-only, so the methods have *no use* in production.  Therefore, we monkey-patch them here (TODO - move
# these to a separate file) in order to have these methods available ONLY when we're testing. This keeps us from
# worrying about the methods screwing things up in production: they don't exist.
#
# Please *try* and KEEP THESE ALPHABETICAL for now.  When we have too many, we'll break them up into files, but that
# will make loading much more complicated.

def DataObject.build_reharvested_dato(dato)
  new_dato = self.gen(
  :guid                   => dato.guid,
  :identifier             => dato.identifier,
  :data_type              => dato.data_type,
  :mime_type              => dato.mime_type,
  :object_title           => dato.object_title,
  :language               => dato.language,
  :license                => dato.license,
  :rights_statement       => dato.rights_statement,
  :rights_holder          => dato.rights_holder,
  :bibliographic_citation => dato.bibliographic_citation,
  :source_url             => dato.source_url,
  :description            => dato.description,
  :object_url             => dato.object_url,
  :object_cache_url       => dato.object_cache_url,
  :thumbnail_url          => dato.thumbnail_url,
  :thumbnail_cache_url    => dato.thumbnail_cache_url,
  :location               => dato.location,
  :latitude               => dato.latitude,
  :longitude              => dato.longitude,
  :altitude               => dato.altitude,
  :object_created_at      => dato.object_created_at,
  :object_modified_at     => dato.object_modified_at,
  :created_at             => Time.now,
  :updated_at             => Time.now,
  :data_rating            => dato.data_rating,
  :published              => true
  )

  #   2c) data_objects_table_of_contents
  if dato.text?
    old_dotoc = DataObjectsTableOfContent.find_by_data_object_id(dato.id)
    DataObjectsTableOfContent.gen(:data_object_id => new_dato.id,
                                  :toc_id => old_dotoc.toc_id)
  end
  #   2d) data_objects_hierarchy_entries
  dato.hierarchy_entries.each do |he|
    DataObjectsHierarchyEntry.gen(:data_object_id => new_dato.id, :hierarchy_entry_id => he.id)
    DataObjectsTaxonConcept.gen(:taxon_concept => he.taxon_concept, :data_object => new_dato)
  end
  # TODO - this could also handle tags, info items, and refs.
  # 3) unpublish old version
  dato.published = false
  dato.save!
  return new_dato
end

class ActiveRecord::Base

  # truncate's this model's table
  def self.truncate
    connection.execute "TRUNCATE TABLE #{ table_name }"
  rescue => ex
    puts "#{ self.name }.truncate failed ... does the table exist?  #{ ex }"
  end

end

DataObject.class_eval do
  def add_ref(full_reference, published, visibility)
    self.refs << ref = Ref.gen(:full_reference => full_reference, :published => published, :visibility => visibility)
    ref
  end
end

KnownUri.class_eval do
  def add_value(value_known_uri)
    raise 'cannot add value to KnownUri' unless value_known_uri.is_a?(KnownUri) && value_known_uri != self
    known_uri_relationships_as_subject <<
      KnownUriRelationship.create(from_known_uri: self, to_known_uri: value_known_uri,
                                  relationship_uri: KnownUriRelationship::ALLOWED_VALUE_URI)
    Rails.cache.delete(KnownUri.cached_name_for('unit_of_measure')) if self == KnownUri.unit_of_measure
  end

  def add_unit(value_known_uri)
    raise 'cannot add value to KnownUri' unless value_known_uri.is_a?(KnownUri) && value_known_uri != self
    KnownUriRelationship.gen_if_not_exists(:from_known_uri => self, :to_known_uri => value_known_uri,
      :relationship_uri => KnownUriRelationship::ALLOWED_UNIT_URI)
  end

  def add_implied_unit(value_known_uri)
    raise 'cannot add value to KnownUri' unless value_known_uri.is_a?(KnownUri) && value_known_uri != self
    KnownUriRelationship.gen_if_not_exists(:from_known_uri => self, :to_known_uri => value_known_uri,
      :relationship_uri => KnownUriRelationship::MEASUREMENT_URI)
  end
end

UserAddedData.class_eval do
  def self.delete_graph
    EOL::Sparql.connection.delete_graph(UserAddedData::GRAPH_NAME)
  end

  def self.recreate_triplestore_graph
    delete_graph
    UserAddedData.where("deleted_at IS NULL").each do |uad|
      uad.add_to_triplestore
      uad.user_added_data_metadata.each do |meta|
        meta.add_to_triplestore
      end
    end
  end
end

Ref.class_eval do
  def add_identifier(type, identifier)
    type = RefIdentifierType.find_by_label(type) || RefIdentifierType.gen_if_not_exists(:label => type)
    # TODO - I can take off the :ref => self, right?  For now, being safe.
    self.ref_identifiers << RefIdentifier.gen_if_not_exists(:ref_identifier_type => type, :identifier => identifier, :ref => self)
  end
end

TaxonConcept.class_eval do
  # Quickly adds some user-submitted text to a TaxonConcept.
  #
  # Options are:
  #
  #   +description+:
  #     The actual text to add. Defaults to 'some random text' (literally).
  #   +language+:
  #     The language submitted, defaults to English.
  #   +license+:
  #     The license the text was submitted as.  Defaults to Public Domain, if you choose another one make sure you add Rights Holder.
  #   +rights_holder+:
  #     Owner of rights for the text. Must NOT be blank if License is NOT Public Domain. Must be blank if License is Public Domain.
  #   +title+:
  #     The title provided by the user (note none is required, and the default is none).
  #   +toc_item+:
  #     Under which TOC item it was added (careful, it's possible to add things to TocItems that the GUI disallows)
  #   +user+:
  #     The user who added it. Defaults to the last user in the DB.
  #   +vetted+:
  #     The text object will only be visible if the user is logged in with "All" rather than "Authoritative" mode.
  #     Set this to true if you want it to be visible to "Authoritative", or to remove the yellow background.
  def add_user_submitted_text(options = {})
    options = {:description       => 'some random text',
               :user              => User.last,
               :toc_item          => TocItem.overview,
               :license           => License.public_domain,
               :rights_holder     => '',
               :language          => Language.english,
               :vetted            => false
              }.merge(options)
    dato = DataObject.create_user_text(
      { :object_title => options[:title],
        :license_id => options[:license].id,
        :language_id => options[:language].id,
        :description => options[:description],
        :rights_holder     => options[:rights_holder]
      },
      :toc_id => [options[:toc_item].id],
      :user => options[:user],
      :taxon_concept => self
    )
    if options[:vetted]
      curator = User.find(self.curators.first) # Curators array doesn't return "full" user objects...
      curator ||= User.first
      dato.curate(curator, :vetted_id => Vetted.trusted.id)
    end
    return dato
  end

  # Add a specific toc item to this TC's toc:
  def add_toc_item(toc_item, options = {})
    dato = DataObject.gen(:data_type => DataType.find_by_translated(:label, 'Text'))
    if options[:vetted] == false
      dato.vetted = Vetted.untrusted
    end
    DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => toc_item)
    dato.save!
    DataObjectsHierarchyEntry.gen(:data_object => dato, :hierarchy_entry => hierarchy_entries.first)
    DataObjectsTaxonConcept.gen(:taxon_concept => self, :data_object => dato)
  end

  # Add a specific toc item to this TC's toc:
  def add_data_object(dato, options = {})
    if dato.data_type_id == DataType.text.id
      toc_item = dato.info_items[0] ? dato.info_items[0].toc_item : dato.toc_items.first
      begin
        DataObjectsTableOfContent.gen(:data_object => dato, :toc_item => toc_item)
      rescue ActiveRecord::RecordNotUnique
        # do nothing
      end
      dato.save!
    end
    DataObjectsHierarchyEntry.gen(:data_object => dato, :hierarchy_entry => hierarchy_entries.first)
    DataObjectsTaxonConcept.gen(:taxon_concept => self, :data_object => dato)
  end

  def add_object_as_subject(object, info_item_label)
    object.info_items << InfoItem.gen_if_not_exists(label: info_item_label)
    object.save!
    add_data_object(object)
    object.reload
    object.update_solr_index
  end

  # Add a synonym to this TC.
  def add_scientific_name_synonym(name_string, options = {})
    language  = Language.scientific # Note, this could be id 0
    preferred = false
    relation = SynonymRelation.find_by_translated(:label, "synonym")
    name_obj = Name.find_by_clean_name(Name.prepare_clean_name name_string) || Name.gen(:canonical_form => canonical_form_object, :string => name_string, :italicized => name_string)
    Synonym.generate_from_name(name_obj, :agent => Agent.first, :preferred => preferred, :language => language,
                               :entry => entry, :relation => relation)
  end

  # Only used in testing context, this returns the actual Name object for the canonical form for this TaxonConcept.
  # Note that, since the canonical form is what you see when browsing the site, this really comes from the Catalogue
  # of Life specifically, which may present a problem later.
  def canonical_form_object
    CanonicalForm.find(entry.name.canonical_form_id) # Yuck.  But true.
  end

end

