module EOL
  class DataObjectBuilder

    attr_reader :dato

    include EOL::Builders

    # Builds a DataObject and creates all of the ancillary relationships.  Returns the DataObject.
    #
    # As a matter of course, you had better load the foundation scenario before using this.  It relies on many of the
    # enum-like classes being populated.
    #
    # This takes three arguments.  The first is the type of the DataObject: acceptable values include 'Text',
    # 'Image', 'GBIF Image', 'Flash', and 'YouTube'.  The second argument is the description, since all
    # DataObject instances make use of this one.  The third argument is a hash of options.  Some key values are:
    #
    #   +agent+::
    #     If specified, this dato will be related to this agent.  If you don't supply this, an agent will try to be
    #     intelligently deduced from other options, or picked as the last Agent created, or created from scratch if
    #     nothing else worked.
    #   +agent_role+::
    #     If specified (as either a string or an AgentRole instance), this dato will be related to the agent with
    #     this agent_role.  If missing, 'Author' will be used.
    #   +association+::
    #     This is a flag to make distinction between data_object_hierarchy_entry(DOHE) and curated_DOHE(CDOHE) while
    #     building the hierarchy entry relation(i.e. adding an association between data object and hierarchy entry).
    #     If missing, the association will be added in DOHE.
    #   +content_partner+::
    #     If specified, a Resource, HarvestEvent, and all relationships between them will be created.
    #   +hierarchy_entry+::
    #     Which HE to link this object to. If missing, defaults to the last HE in the table, so be careful.
    #   +language+::
    #     Which language you want this to be given.  If missing, defaults to English.
    #   +license+::
    #     Which license you want this to be given.  If missing, defaults to the first license in the DB.
    #   +mime_type+::
    #     If you care about it, set it.  Otherwise, a useful default will be chosen.
    #   +name+::
    #     Which Name object (q.v.) to link the Taxon to.
    #   +num_comments+::
    #     How many comments to attach to this object.
    #   +rights_holder+::
    #     Owner of usage rights, can't be blank for CC-BY licenses, must be blank for Public Domain license.
    #   +scientific_name+::
    #     Which raw scientific name the content provider assigned to the Taxon.  Defaults to the HE's.
    #   +taxon+::
    #     Which Taxon (q.v.) to link this to.  If missing, one will be created.
    #   +toc_item+::
    #     If this is a 'Text' type, this specifies which TocItem to link this to. If left blank, one is randomly
    #     chosen.
    #   +user+::
    #     This argument should be added if adding an association to CDOHE otherwise doesn't matter.
    #     If missing, defaults to the last User in the users table, so be careful.
    #   +vetted+::
    #     A Vetted object to assign to the DataObjectHierarchyEntry (DOHE) or Curated_DOHE(CDOHE).
    #     If missing, the default vetted status added will Trusted.
    #   +visibility+::
    #     A Visibility object to assign to the DataObjectHierarchyEntry (DOHE) or Curated_DOHE(CDOHE).
    #     If missing, the default visibility status added will Visible.
    #
    # Any other options on this method will be passed directly to the DataObject#gen method (for example,
    # lattitude, longitude, and the like).
    def initialize(type, desc, options = {})
      @type = type
      data_object_gen_options = pull_class_options_from(options)
      gen_opts = dynamic_attributes(desc).merge(data_object_gen_options)
      @dato = DataObject.gen(gen_opts)
      build
    end

    def build
      build_hierarchy_entry_relation
      build_type_specific_relations
      build_harvest_event_relation
      build_agent_relation
      add_comments
    end

  private

    def build_agent_relation
      unless @event.nil? || @event.resource.nil? || @event.resource.content_partner.blank? || @event.resource.content_partner.user.agent.blank?
        @agent ||= @event.resource.content_partner.user.agent
      end
      @agent ||= Agent.last # Sheesh, they screwed up!  Let's assume they want the most recent agent...
      @agent ||= Agent.gen  # Wow, they have, like, nothing ready.  We have to create one.  Ick.

      AgentsDataObject.gen(:agent => @agent, :agent_role => @agent_role, :data_object => @dato)
    end

    def build_harvest_event_relation
      DataObjectsHarvestEvent.gen(:harvest_event => find_event, :data_object => @dato)
    end

    def add_comments
      # You cannot add comments to anything but images and text (for now):
      if @type == 'Image' or @type == 'Text'
        @num_comments.times { Comment.gen(:parent => @dato, :user => @user) }
      end
    end

    def build_hierarchy_entry_relation
      if @association == "DOHE"
        DataObjectsHierarchyEntry.gen(:data_object => @dato, :hierarchy_entry => @he, :vetted => @vetted, :visibility => @visibility)
      elsif @association == "CDOHE"
        CuratedDataObjectsHierarchyEntry.gen(:data_object_id => @dato.id, :data_object_guid => @dato.guid, :hierarchy_entry => @he, :vetted => @vetted, :visibility => @visibility, :user => @user)
      else
        raise 'Please specify association as "DOHE" or "CDOHE"'
      end
      DataObjectsTaxonConcept.gen(:data_object => @dato, :taxon_concept_id => @he.taxon_concept_id)
    end

    def build_type_specific_relations
      if @type == 'Text'
        DataObjectsTableOfContent.gen(:data_object => @dato, :toc_item => @toc_item)
        @toc_item.info_items.each do |ii|
          DataObjectsInfoItem.gen(:data_object => @dato, :info_item => ii)
        end
      end
    end

    def dynamic_attributes(desc)
      options =
        default_attributes.merge({:data_type   => DataType.find_by_translated(:label, @type),
                                  :description => desc,
                                  :mime_type   => MimeType.find_by_translated(:label, mime_types[@type] || mime_types[:default])
                                 })
      if @type == 'Image'
         options[:object_cache_url] ||= FactoryGirl.generate(:image)
      end
      return options
    end

    def pull_class_options_from(options)
      @agent           = options.delete(:agent)           || nil # better guesses will be made later, in context.
      @association     = options.delete(:association)     || "DOHE"
      @event           = options.delete(:event)           || nil # better guesses will be made later...
      @agent_role      = find_agent_role(options.delete(:agent_role))
      @content_partner = options.delete(:content_partner)
      @he              = options.delete(:hierarchy_entry) || HierarchyEntry.last
      name             = options.delete(:name)            || Name.last
      @num_comments    = options.delete(:num_comments)    || 1
      @user            = options.delete(:user)            || User.last
      @vetted          = options.delete(:vetted)          || Vetted.trusted
      @visibility      = options.delete(:visibility)      || Visibility.get_visible
      scientific_name  = options.delete(:scientific_name) || @he.name(:expert) || FactoryGirl.generate(:scientific_name)
      if @type == 'Text'
        @toc_item = options.delete(:toc_item)
        @toc_item ||= [TocItem.comprehensive_description,
                       TocItem.overview,
                       TocItem.brief_summary].sample
      end
      return options
    end

    def find_agent_role(first_try)
      agent_role = first_try || 'Author'
      unless agent_role.class == AgentRole
        agent_role = AgentRole.find_by_translated(:label, agent_role)
        raise "Could not find an AgentRole matching '#{agent_role}'.  Was the foundation scenario loaded?" if
          agent_role.nil?
      end
      return agent_role
    end

    def find_event
      if @event.class == HarvestEvent
        return @event
      elsif not @content_partner.nil?
        @event = build_new_harvest_event
      else
        @event = default_harvest_event
      end
      return @event
    end

    def build_new_harvest_event
      if @content_partner.resources.blank?
        @content_partner.resources << Resource.gen(:content_partner => @content_partner)
      end
      @event = HarvestEvent.gen(:resource => @content_partner.resources.first)
    end

    # I want to set these once, but I *dont* want them to be a class variable, so that they foundation scenario
    # doesn't have to be loaded when the class is first evaluated (but it DOES need to be loaded the first time this
    # class is *used*... which makes sense, it relies on foundation in many other ways.
    def mime_types
      @mime_types ||= {
        'Image'      => 'image/jpeg',
        'Sound'      => 'audio/mpeg',
        'Text'       => 'text/html',
        'Video'      => 'video/quicktime',
        'GBIF Image' => 'image/jpeg',
        'IUCN'       => 'text/plain',
        'Flash'      => 'video/x-flv',
        'YouTube'    => 'video/x-flv',
        :default     => 'image/jpeg'
      }
    end
    def default_attributes
      @default_attributes = {:license     => License.public_domain,
                             :rights_holder => '',
                             :language    => Language.english }
    end

  end
end

