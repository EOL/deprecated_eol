module EOL

  class CommonNameDisplay

    attr_accessor :taxon_concept_name
    attr_accessor :name
    attr_accessor :name_string
    attr_accessor :language
    attr_accessor :language_label
    attr_accessor :agents
    attr_accessor :hierarchies
    attr_accessor :agent_synonyms
    attr_accessor :preferred
    attr_accessor :duplicate
    attr_accessor :duplicate_with_curator
    attr_accessor :vetted

    # NOTE - this uses TaxonConceptNames, and Synonyms.  TCN is a denormlized version of Synonyms.
    def self.find_by_taxon_concept_id(tc_id, hierarchy_entry_id = nil, options = {})
      inc = [ :name, :language, :vetted, { :synonym => [ :agents, { :hierarchy => :agent } ] }, { :source_hierarchy_entry => :agents } ]
      sel = { :taxon_concept_names => [ :preferred, :vetted_id, :name_id, :language_id, :vetted_id, :synonym_id ],
              :synonyms => [ :id, :hierarchy_id ],
              :hierarchies => [ :id, :agent_id ],
              :agents_synonyms => '*',
              :agents => '*',
              :names => [ :id, :string],
              :vetted => [ :id, :view_order],
              :languages => '*' }
      conditions = nil
      if options[:name_id] && options[:language_id]
        conditions = "taxon_concept_names.name_id = #{options[:name_id]} AND taxon_concept_names.language_id = #{options[:language_id]}"
      end
      unless hierarchy_entry_id.blank?
        taxon_concept_names = TaxonConceptName.find_all_by_source_hierarchy_entry_id_and_vern(hierarchy_entry_id, 1,
          :conditions => conditions)
      else
        taxon_concept_names = TaxonConceptName.find_all_by_taxon_concept_id_and_vern(tc_id, 1,
          :conditions => conditions)
      end
      TaxonConceptName.preload_associations(taxon_concept_names, inc, :select => sel)
      display_names = taxon_concept_names.map do |tcn|
        EOL::CommonNameDisplay.new(tcn)
      end
      EOL::CommonNameDisplay.group_by_name(display_names)
    end

    def self.find_by_hierarchy_entry_id(hierarchy_entry_id, options)
      find_by_taxon_concept_id(nil, hierarchy_entry_id, options)
    end

    def initialize(tcn)
      @taxon_concept_name = tcn
      @name               = tcn.name
      @name_string        = tcn.name.string
      @language           = tcn.language
      @language           = Language.unknown if @language.blank? || Language.all_unknowns.include?(@language)
      @language_label     = @language.label rescue 'Unknown'
      @synonyms           = [ tcn.synonym ]
      @preferred          = tcn.preferred?
      @vetted             = tcn.vetted
      @agents             = tcn.agents
      @hierarchies        = tcn.hierarchies
      @agent_synonyms     = {}
      tcn.agents.each{ |a| @agent_synonyms[a.id] = tcn.synonym_id }
      # TODO - the methods that set these are in taxa_helper.  Move the methods here.  (Or, better, to an Enumerable for CNDs.)
      @duplicate              = false
      @duplicate_with_curator = false
    end
    
    def self.group_by_name(names)
      new_names = []
      previous = nil
      names.sort.each do |name|
        if previous
          if previous === name
            new_names.last.merge!(name)
          else
            new_names << name
          end
        else # this is the first one.
          new_names << name
        end
        previous = name
      end
      new_names
    end

    def known_language?
      !(language.iso_639_1.blank? && language.iso_639_2.blank?)
    end

    def synonym_id_for_user(user)
      @agent_synonyms[user.agent.id] rescue nil
    end

    # This is only used in the scope of a single TaxonConcept... otherwise I would add that (at the cost of some obfuscation).
    def unique_id
      "name-#{@language.id}-#{@taxon_concept_name.name.id}"
    end

    def merge!(other)
      @preferred = (@preferred || other.preferred)
      @vetted = other.vetted if other.vetted && other.vetted.view_order < @vetted.view_order
      @agents += other.agents
      @hierarchies += other.hierarchies
      other.agent_synonyms.each do |agent_id, synonym_id|
        @agent_synonyms[agent_id] = synonym_id
      end
    end

    # Sort by language label first, then by name, then by source.
    def <=>(other)
      if self.language_label == other.language_label
        if self.name_string.downcase == other.name_string.downcase
          (self.vetted.view_order rescue 500) <=> (other.vetted.view_order rescue 500)
        else
         self.name_string.downcase <=> other.name_string.downcase
        end
      else
        self.language_label.to_s <=> other.language_label.to_s
      end
    end

    def ===(other)
      self.name_string.downcase == other.name_string.downcase &&
        self.language_label == other.language_label
    end
  end
end
