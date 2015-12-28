class SolrCore
  class SiteSearch < SolrCore::Base
    CORE_NAME = "site_search"
    MIN_CHAR_REGEX = /^[0-9a-z]{32}/i
    TAXON_NAME_FIELDS = {
      preferred_scientifics: { keyword: 'PreferredScientific', weight: 1 },
      synonyms: { keyword: 'Synonym', weight: 3 },
      surrogates: { keyword: 'Surrogate', weight: 500 },
      preferred_commons: { keyword: 'PreferredCommonName', weight: 2 },
      commons: { keyword: 'CommonName', weight: 4 }
    }

    def initialize
      connect(CORE_NAME)
    end

    def index_type(klass, ids)
      ids.in_groups_of(10_000, false) do |batch|
        insert_batch(klass, batch)
      end
      EOL.log("committing...")
      commit
    end

    def insert_batch(klass, ids)
      EOL.log_call
      # Used when building indexes with this class:
      @objects = Set.new
      send("get_#{klass.name.underscore.pluralize}", ids)
      EOL.log("Delete old items...")
      ids.in_groups_of(1000, false) do |group|
        delete("resource_type:#{klass.name} AND "\
          "resource_id:(#{group.join(" OR ")})")
      end
      @objects.delete(nil)
      @objects.delete({})
      @objects.to_a.in_groups_of(6400, false) do |group|
        EOL.log("Adding #{group.count} items...")
        connection.add(group)
      end
      EOL.log("Committing...")
      connection.commit
      EOL.log_return
      @objects = nil # Saves some memory (hopefully).
    end

    # NOTE: called by #insert_batch via dynamic #send
    def get_taxon_concepts(ids)
      EOL.log_call
      @taxa ||= {}
      get_taxon_names(ids)
      get_taxon_ancestors(ids)
      get_taxon_richness(ids)
      convert_taxa_to_search_objects
    end

    def get_taxon_names(ids)
      EOL.log_call
      TaxonConceptName.includes(:taxon_concept, :name).joins(:taxon_concept).
        merge(TaxonConcept.unsuperceded.published.where(id: ids)).
        find_each do |tcn|
        next if tcn.name.string.blank?
        id = tcn.taxon_concept_id
        vetted_id = tcn.taxon_concept.vetted_id
        language_id = tcn.language_id
        string = SolrCore.string(tcn.name.string)
        if string.blank?
          EOL.log("WARNING: Blank string from #{tcn.name.string}; name id "\
            "#{tcn.name.id} taxon_concept_id #{tcn.taxon_concept_id}")
          next
        end
        name_vetted_id = tcn.vetted_id
        if tcn.vern?
          iso = Language.iso_code(language_id) || 'unknown'
          if tcn.preferred? && iso != 'unknown'
            add_to_taxa(id, preferred_commons: { iso => string })
          elsif name_vetted_id != Vetted.untrusted.id &&
            vetted_id != Vetted.inappropriate.id
            add_to_taxa(id, commons: { iso => string })
          end
        elsif tcn.source_hierarchy_entry_id && tcn.source_hierarchy_entry_id > 0
          if Name.is_surrogate_or_hybrid?(string)
            add_to_taxa(id, surrogates: string)
          elsif tcn.preferred?
            add_to_taxa(id, preferred_scientifics: string)
          else
            add_to_taxa(id, synonyms: string)
          end
        end
      end
      remove_common_names_in_scientifics
    end

    def add_to_taxa(id, add = {})
      @taxa[id] ||= {}
      [:surrogates, :preferred_scientifics, :synonyms].each do |attribute|
        @taxa[id][attribute] ||= Set.new
        if add.has_key?(attribute)
          @taxa[id][attribute] << add[attribute]
        end
      end
      # Trickier to set: common languages contain hashes, keyed by language ISO
      # code and with values of strings in that language.
      [:preferred_commons, :commons].each do |common_type|
        @taxa[id][common_type] ||= {}
        if add.has_key?(common_type)
          add[common_type].each do |iso, string|
            @taxa[id][common_type][iso] ||= Set.new
            @taxa[id][common_type][iso] << string
          end
        end
      end
    end

    def remove_common_names_in_scientifics
      EOL.log_call
      @taxa.each do |id, object|
        remove_duplicate_common_names_in(:preferred_commons, object, id)
        remove_duplicate_common_names_in(:commons, object, id)
      end
    end

    def remove_duplicate_common_names_in(type, object, id)
      object[type].each do |iso, names|
        names.each do |name|
          if object[:preferred_scientifics].include?(name) ||
             object[:synonyms].include?(name)
            @taxa[id][type][iso].delete(name)
            @taxa[id][type].delete(iso) if
              @taxa[id][type][iso].empty?
          end
        end
      end
    end

    def get_taxon_ancestors(ids)
      EOL.log_call
      TaxonConceptsFlattened.where(["taxon_concept_id IN (?)", @taxa.keys]).
        find_each do |tcf|
        @taxa[tcf.taxon_concept_id][:ancestor_taxon_concept_id] ||= []
        @taxa[tcf.taxon_concept_id][:ancestor_taxon_concept_id] <<
          tcf.ancestor_id
      end
    end

    def get_taxon_richness(ids)
      EOL.log_call
      TaxonConceptMetric.select("taxon_concept_id, richness_score").
        where(["taxon_concept_id IN (?)", @taxa.keys]).find_each do |tcr|
        @taxa[tcr.taxon_concept_id][:richness_score] = tcr.richness_score
      end
    end

    # TODO: it looks like this takes a LONG time to run; improve.
    def convert_taxa_to_search_objects
      EOL.log("converting #{@taxa.count} taxa to search objects", prefix: "#")
      @taxa.each do |id, taxon|
        base_attributes = {
          resource_type:             "TaxonConcept",
          resource_id:               id,
          resource_unique_key:       "TaxonConcept_#{id}",
          ancestor_taxon_concept_id: taxon[:ancestor_taxon_concept_id],
          richness_score:            taxon[:richness_score]
        }
        [:preferred_scientifics, :synonyms, :surrogates].each do |field|
          objs = add_scientific_to_objects(base_attributes, taxon, field)
          @objects += objs
        end
        [:commons, :preferred_commons].each do |field|
          objs = add_common_to_objects(base_attributes, taxon, field)
          @objects += objs
        end
      end
    end

    def add_scientific_to_objects(base, object, field)
      return [] if object[field].empty?
      [base.merge(
        keyword_type: TAXON_NAME_FIELDS[field][:keyword],
        keyword: object[field].to_a,
        language: 'sci',
        resource_weight: TAXON_NAME_FIELDS[field][:weight]
      )]
    end

    def add_common_to_objects(base, object, field)
      return [] if object[field].empty?
      object[field].map do |iso, names|
        base.merge(
          keyword_type: TAXON_NAME_FIELDS[field][:keyword],
          keyword: names.to_a,
          language: iso,
          resource_weight: TAXON_NAME_FIELDS[field][:weight]
        )
      end
    end

    # TODO: Yech. The scores seem arbitrary, the queries are huge and probably
    # not necessary (so many nulls); I'm not sure nulls are handled properly
    # (well, it does remove blanks, but that's a lot of work to find out it's
    # null!), and this is all VERY obfuscated. :| I'm not pleased with this
    # code. I definitely wouldn't have done it this way! # NOTE: called by
    # #insert_batch via dynamic #send
    def get_data_objects(ids)
      EOL.log_call
      set_data_type_and_weight
      get_object_agents(ids)
      get_object_users(ids)
      # Sorry, I am not re-writing this now. Too much complexity. :\
      query = "
          SELECT do.id, do.guid,
          REPLACE(REPLACE(do.object_title, '\n', ' '), '\r', ' '),
          REPLACE(REPLACE(do.description, '\n', ' '), '\r', ' '),
          REPLACE(REPLACE(do.rights_statement, '\n', ' '), '\r', ' '),
          REPLACE(REPLACE(do.rights_holder, '\n', ' '), '\r', ' '),
          REPLACE(REPLACE(do.bibliographic_citation, '\n', ' '), '\r', ' '),
          REPLACE(REPLACE(do.location, '\n', ' '), '\r', ' '),
          do.created_at, do.updated_at,  l.iso_639_1, do.data_type_id
          FROM data_objects do
          LEFT JOIN languages l ON (do.language_id=l.id)
          LEFT JOIN data_objects_hierarchy_entries dohe
            ON (do.id=dohe.data_object_id)
          LEFT JOIN curated_data_objects_hierarchy_entries cdohe
            ON (do.id=cdohe.data_object_id)
          LEFT JOIN users_data_objects udo ON (do.id=udo.data_object_id)
          WHERE do.published=1
          AND (dohe.visibility_id = #{Visibility.visible.id}
            OR cdohe.visibility_id = #{Visibility.visible.id}
            OR udo.visibility_id = #{Visibility.visible.id})
          AND do.id IN (#{ids.join(',')})"
      used_ids = []
      DataObject.connection.select_rows(query).each do |row|
        id = row[0]
        next if used_ids.include?(id)
        used_ids << id
        guid = row[1]
        next if row[3].blank? || guid !~ MIN_CHAR_REGEX
        object_title = SolrCore.string(row[2])
        description = SolrCore.string(row[3])
        rights_statement = SolrCore.string(row[4])
        rights_holder = SolrCore.string(row[5])
        bibliographic_citation = SolrCore.string(row[6])
        location = SolrCore.string(row[7])
        created_at = SolrCore.date(row[8])
        updated_at = SolrCore.date(row[9])
        iso = SolrCore.string(row[10]) # NOTE: ATM we don't use this, but...
        data_type_id = row[11]
        unless @data_type_and_weight.has_key?(data_type_id)
          EOL.log("WARNING: unknown data type id #{data_type_id}", prefix: "!")
        end
        data_types = ["DataObject"]
        extra_type = @data_type_and_weight[data_type_id][:type]
        data_types << extra_type if !extra_type.blank?
        resource_weight = @data_type_and_weight[data_type_id][:weight]
        base_attributes = {
          resource_type:       data_types,
          resource_id:         id,
          resource_unique_key: "DataObject_#{id}",
          language:            'en', # TODO: should this be iso ?
          date_created:        created_at,
          date_modified:       updated_at
        }
        fields_to_index = [
          { keyword_type:    "object_title",
            keyword:         object_title,
            full_text:       false,
            resource_weight: resource_weight
          },
          { keyword_type:    "description",
            keyword:         description,
            full_text:       true,
            resource_weight: resource_weight + 2
          },
          { keyword_type:    "rights_statement",
            keyword:         rights_statement,
            full_text:       false,
            resource_weight: resource_weight + 3
          },
          { keyword_type:    "rights_holder",
            keyword:         rights_holder,
            full_text:       false,
            resource_weight: resource_weight + 4
          },
          { keyword_type:    "bibliographic_citation",
            keyword:         bibliographic_citation,
            full_text:       false,
            resource_weight: resource_weight + 5
          },
          { keyword_type:    "location",
            keyword:         location,
            full_text:       false,
            resource_weight: resource_weight + 6
          }
        ]
        fields_to_index.each do |field_to_index|
          next if field_to_index[:keyword].nil?
          keyword = field_to_index[:keyword].gsub(/ +/, " ").strip
          next if keyword.blank?
          @objects << base_attributes.merge(
            keyword_type:    field_to_index[:keyword_type],
            keyword:         keyword,
            full_text:       field_to_index[:full_text],
            resource_weight: field_to_index[:resource_weight]
          )
        end
        if ! @agents_for_objects.blank?
          @agents_for_objects[id].each do |agent_name|
            next if agent_name.blank?
            @objects << base_attributes.merge(
              keyword_type:    "agent",
              keyword:         agent_name,
              resource_weight: resource_weight + 1
            )
          end
        end
      end
    end

    def get_object_agents(ids)
      EOL.log_call
      @agents_for_objects ||= {}
      # NOTE: I tried using find_each, here, but it causes an ORDER BY clause
      # (it needs to, to keep track of things), so I'll just limit the query
      # size by grouping ids:
      ids.in_groups_of(500, false) do |group|
        Agent.includes(:data_objects).joins(:data_objects).
          where(["agents_data_objects.data_object_id IN (?) "\
            "AND data_objects.published = 1", group]).each do |agent|
          agent_name = SolrCore.string("#{agent.full_name} "\
            "#{agent.given_name} #{agent.family_name}")
          if agent_name.blank?
            EOL.log("WARNING: Agent with no names: #{agent.id}", prefix: "!")
          else
            agent.data_objects.each do |dato|
              @agents_for_objects[dato.id] ||= []
              @agents_for_objects[dato.id] << agent_name
            end
          end
        end
      end
    end

    def get_object_users(ids)
      EOL.log_call
      User.includes(:data_objects).
        where(["users_data_objects.data_object_id IN (?) AND "\
          "data_objects.published = 1", ids]).
        find_each do |user|
        username = SolrCore.string(user.username)
        full_name = SolrCore.string(user.full_name)
        user.data_objects.each do |dato|
          @agents_for_objects[dato.id] ||= []
          unless username.blank?
            @agents_for_objects[dato.id] << username
          end
          if ! full_name.blank?
            @agents_for_objects[dato.id] << full_name
          end
        end
      end
    end

    def set_data_type_and_weight
      EOL.log_call
      @data_type_and_weight = {}
      DataType.sound_type_ids.each do |dt_id|
        @data_type_and_weight[dt_id] = { type: 'Sound', weight: 70 }
      end
      DataType.image_type_ids.each do |dt_id|
        @data_type_and_weight[dt_id] = { type: 'Image', weight: 60 }
      end
      DataType.video_type_ids.each do |dt_id|
        @data_type_and_weight[dt_id] = { type: 'Video', weight: 50 }
      end
      DataType.text_type_ids.each do |dt_id|
        @data_type_and_weight[dt_id] = { type: 'Text', weight: 40 }
      end
      DataType.map_type_ids.each do |dt_id|
        @data_type_and_weight[dt_id] = { type: '', weight: 100 }
      end
      DataType.link_type_ids.each do |dt_id|
        @data_type_and_weight[dt_id] = { type: '', weight: 100 }
      end
    end

    # NOTE: called by #insert_batch via dynamic #send
    def get_users(ids)
      EOL.log_call
      User.active.not_hidden.where(id: ids).find_each do |user|
        base = {
          resource_type:       'User',
          resource_id:         user.id,
          resource_unique_key: "User_#{id}",
          language:            'en',
          resource_weight:     30,
          date_created:        SolrCore.date(user.created_at),
          date_modified:       SolrCore.date(user.updated_at)
        }
        add_object_with_keyword_if_non_blank(base, "username", user.username)
        add_object_with_keyword_if_non_blank(base, "full_name", user.full_name)
      end
    end

    # NOTE: called by #insert_batch via dynamic #send
    def get_collections(ids)
      EOL.log_call
      Collection.published.non_watch.where(id: ids).find_each do |collection|
        base = {
          resource_type:       "Collection",
          resource_id:         collection.id,
          resource_unique_key: "Collection_#{id}",
          language:            "en",
          resource_weight:     20,
          date_created:        SolrCore.date(collection.created_at),
          date_modified:       SolrCore.date(collection.updated_at)
        }
        add_object_with_keyword_if_non_blank(base, "name", collection.name)
        base[:full_text] = true
        add_object_with_keyword_if_non_blank(base, "description",
          collection.description)
      end
    end

    # NOTE: called by #insert_batch via dynamic #send
    def get_communities(ids)
      EOL.log_call
      Community.published.where(id: ids).find_each do |community|
        base = {
          resource_type:       'Community',
          resource_id:         community.id,
          resource_unique_key: "Community_#{id}",
          language:            'en',
          resource_weight:     10,
          date_created:        created_at,
          date_modified:       updated_at
        }
        add_object_with_keyword_if_non_blank(base, "name", community.name)
        base[:full_text] = true
        add_object_with_keyword_if_non_blank(base, "description",
          community.description)
      end
    end

    # NOTE: called by #insert_batch via dynamic #send
    def get_content_pages(ids)
      EOL.log_call
      TranslatedContentPage.active.joins(:content_page).
        where(["content_page_id IN (?) AND content_pages.active = 1"]).
        find_each do |page|
        iso = Language.iso_code(page.language_id)
        next unless iso
        base = {
          resource_type:       "ContentPage",
          resource_id:         page.id,
          resource_unique_key: "ContentPage_#{id}",
          resource_weight:     25,
          date_created:        SolrCore.date(page.created_at),
          date_modified:       SolrCore.date(page.updated_at)
        }
        if name = SolrCore.string(page.content_page.name) && ! name.blank?
          @objects << base.merge(keyword_type: "page_name", keyword: name,
            language: Language.default.iso_code)
        end
        # Now safe to add:
        base[:language] = iso
        { "title" => page.title,
          "meta_keywords" => page.meta_keywords,
        }.each do |type, value|
          add_object_with_keyword_if_non_blank(base, type, value)
        end
        # Safe to add:
        base[:full_text] = true
        { "left_content" => page.left_content,
          "main_content" => page.main_content,
          "meta_description" => page.meta_description
        }.each do |type, value|
          add_object_with_keyword_if_non_blank(base, type, value)
        end
      end
    end

    def add_object_with_keyword_if_non_blank(base, type, value)
      if keyword = SolrCore.string(value) && ! keyword.blank?
        @objects << base.merge(keyword_type: type, keyword: keyword)
      end
    end
  end
end
