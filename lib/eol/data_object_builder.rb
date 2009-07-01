class EOL
  class DataObjectBuilder

    attr_reader :dato

    include EOL::Spec::Helpers

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
    #     this role.  If missing, 'Author' will be used.
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
    #   +scientific_name+::
    #     Which raw scientific name the content provider assigned to the Taxon.  Defaults to the HE's. 
    #   +taxon+::
    #     Which Taxon (q.v.) to link this to.  If missing, one will be created. 
    #   +toc_item+::
    #     If this is a 'Text' type, this specifies which TocItem to link this to. If left blank, one is randomly
    #     chosen.
    #
    # Any other options on this method will be passed directly to the DataObject#gen method (for example,
    # lattitude, longitude, and the like).
    #
    # NOTE - I am not setting the mime type yet.  We never use it.  NOTE - There are no models for all the
    # refs_* tables, so I'm ignoring them.
    def initialize(type, desc, options = {})
      @type = type
      data_object_gen_options = pull_class_options_from(options)
      @dato = DataObject.gen(dynamic_attributes(desc).merge(data_object_gen_options))
      build
    end

    def build
      build_taxon_relation
      build_type_specific_relations
      build_harvest_event_relation
      build_agent_relation
      add_comments
    end

  private

    def build_agent_relation
      if not @event.nil? and not @event.resource.nil? and not @event.resource.agents.blank?
        @agent ||= @event.resource.agents.first
      end
      @agent ||= Agent.last # Sheesh, they screwed up!  Let's assume they want the most recent agent...
      @agent ||= Agent.gen  # Wow, they have, like, nothing ready.  We have to create one.  Ick.

      AgentsDataObject.gen(:agent => @agent, :agent_role => @agent_role, :data_object => @dato)
    end

    def build_harvest_event_relation
      DataObjectsHarvestEvent.gen(:harvest_event => find_event, :data_object => @dato)
    end

    def add_comments
      user = User.last # not convinced it is faster to assign this rather than calling it repeatedly, but feeling saucy!
      @num_comments.times { Comment.gen(:parent => @dato, :user => user) }
    end

    def build_taxon_relation
      DataObjectsTaxon.gen(:data_object => @dato, :taxon => @taxon)
    end

    def build_type_specific_relations
      if @type == 'Image'
        build_top_image
      elsif @type == 'Text'
        DataObjectsTableOfContent.gen(:data_object => @dato, :toc_item => @toc_item)
      end
    end

    def build_top_image
      if @dato.visibility == Visibility.visible and @dato.vetted == Vetted.trusted
        TopImage.gen :data_object => @dato, :hierarchy_entry => @taxon.hierarchy_entry
      else
        TopUnpublishedImage.gen :data_object => @dato, :hierarchy_entry => @he
      end
    end

    def dynamic_attributes(desc)
      options =
        default_attributes.merge({:data_type   => DataType.find_by_label(@type),
                                  :description => desc,
                                  :mime_type   => mime_types[@type] || mime_type[:default]})
      if @type == 'Image'
         options[:object_cache_url] ||= Factory.next(:image)
      end
      return options
    end

    def pull_class_options_from(options)
      @agent           = options.delete(:agent) || nil # better guesses will be made later, in context.
      @event           = options.delete(:event) || nil # better guesses will be made later...
      @agent_role      = find_agent_role(options.delete(:agent_role))
      @content_partner = options.delete(:content_partner)
      @he              = options.delete(:hierarchy_entry) || HierarchyEntry.last
      name             = options.delete(:name)            || Name.last
      @num_comments    = options.delete(:num_comments)    || 1
      scientific_name  = options.delete(:scientific_name) || @he.name(:expert) || Factory.next(:scientific_name)
      @taxon           = options.delete(:taxon)
      @taxon         ||= Taxon.gen(:name => name, :hierarchy_entry => @he, :scientific_name => scientific_name)
      if @type == 'Text'
        @toc_item      = options.delete(:toc_item)
        @toc_item    ||= TocItem.find(rand(3)+1)   # If foundation was loaded: Overview, Description, or Ecology.
      end
      return options
    end

    def find_agent_role(first_try)
      agent_role = first_try || 'Author'
      unless agent_role.class == AgentRole
        agent_role = AgentRole.find_by_label(agent_role)
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
      agent_resource = @content_partner.agent.agents_resources.detect do |ar|
        ar.resource_agent_role_id == ResourceAgentRole.content_partner_upload_role.id
      end
      if agent_resource.nil?
        @agent = @content_partner.agent
        agent_resource = AgentsResource.gen(:agent => @agent,
                                            :resource_agent_role => ResourceAgentRole.content_partner_upload_role)
      end
      @event = HarvestEvent.gen(:resource => agent_resource.resource)
    end

    # I want to set these once, but I *dont* want them to be a class variable, so that they foundation scenario
    # doesn't have to be loaded when the class is first evaluated (but it DOES need to be loaded the first time this
    # class is *used*... which makes sense, it relies on foundation in many other ways.
    def mime_types
      @mime_types ||= {
        'Image'      => MimeType.find_by_label('image/jpeg'),
        'Sound'      => MimeType.find_by_label('audio/mpeg'),
        'Text'       => MimeType.find_by_label('text/html'),
        'Video'      => MimeType.find_by_label('video/quicktime'),
        'GBIF Image' => MimeType.find_by_label('image/jpeg'),
        'IUCN'       => MimeType.find_by_label('text/plain'),
        'Flash'      => MimeType.find_by_label('video/x-flv'),
        'YouTube'    => MimeType.find_by_label('video/x-flv'),
        :default     => MimeType.find_by_label('image/jpeg')
      }
    end
    def default_attributes
      @default_attributes = {:visibility  => Visibility.visible,
                             :vetted      => Vetted.trusted,
                             :license     => License.first,
                             :language    => Language.english }
    end

  end
end

