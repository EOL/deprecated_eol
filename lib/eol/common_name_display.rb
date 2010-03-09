module EOL

  class CommonNameDisplay

    attr_accessor :name_id
    attr_accessor :name_string
    attr_accessor :language_label
    attr_accessor :language_name
    attr_accessor :language_id
    attr_accessor :agent_id
    attr_accessor :synonym_id
    attr_accessor :preferred
 
    # NOTE - this uses TaxonConceptNames, not Synonyms.  For now, that's because TCN is a denormlized version of Synonyms.
    def self.find_by_taxon_concept_id(tc_id)
      names = Name.find_by_sql([%q{
        SELECT names.id name_id, names.string name_string,
               l.label language_label, l.name language_name, l.id language_id,
               agsyn.agent_id agent_id, syn.id synonym_id, tcn.preferred preferred
        FROM taxon_concept_names tcn JOIN names ON (tcn.name_id = names.id)
          LEFT JOIN languages l ON (tcn.language_id = l.id)
          LEFT JOIN synonyms syn ON (tcn.synonym_id = syn.id)
          LEFT JOIN agents_synonyms agsyn ON (syn.id = agsyn.synonym_id)
        WHERE tcn.taxon_concept_id = ? AND vern = 1
        ORDER BY language_label, language_name, string
      }, tc_id])
      names.map {|n| EOL::CommonNameDisplay.new(n)}
    end

    def initialize(name)
      @name_id        = name[:name_id].to_i
      @name_string    = name[:name_string]
      @language_label = name[:language_label]
      @language_name  = name[:language_name]
      @language_id    = name[:language_id].to_i
      @agent_id       = name[:agent_id].to_i
      @synonym_id     = name[:synonym_id].to_i
      @preferred      = name[:preferred].class == String ? name[:preferred].to_i > 0 : name[:preferred]
    end

    alias :id :name_id
    alias :string :name_string

  end

end
