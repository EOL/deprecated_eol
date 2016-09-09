class SolrCore
  class SiteSearch < SolrCore::Base
    CORE_NAME = "site_search"
    MIN_CHAR_REGEX = /^[0-9a-z]{32}/i

    def initialize
      connect(CORE_NAME)
    end

    def named_taxon_id(name)
      name = name[1...-1] if name =~ /^".*"$/
      name.gsub!(/"/, "\\\"")
      name.fix_spaces
      r = connection.paginate(1, 1, "select", params: {
        q: "keyword_exact:\"#{name}\"^5 AND resource_type:TaxonConcept",
        sort: "richness_score desc" })
      if r && r["response"]["docs"] && r["response"]["docs"].size > 0
        return r["response"]["docs"].first["resource_id"]
      end
      nil # Not found.
    end

    # NOTE: This does NOT include spellchecking and is ONLY sorted by score.
    def taxa(q, page = 1, per_page = 30)
      response = connection.paginate(page, per_page, "select",
        params: { q: q, fq: "resource_type:TaxonConcept", fl: "score",
          sort: "richness_score desc" })
      ids = response["response"]["docs"].map { |d| d["resource_id"] }
      taxa = TaxonConcept.with_titles.where(id: ids)
      response["response"]["docs"].each do |doc|
        doc["instance"] = taxa.find { |t| t.id == doc["resource_id"] }
      end
      response["response"]
    end

    def index_type(klass, ids)
      ids.in_groups_of(10_000, false) do |batch|
        insert_batch(klass, batch)
      end
      EOL.log("committing...")
      commit
    end

    def delete_item(item)
      delete("resource_type:#{item.class.name} AND "\
        "resource_id:(#{item.id})")
    end

    def insert_batch(klass, ids)
      EOL.log("SolrCore::SiteSearch#insert_batch(#{ids.size} "\
        "#{klass.name.underscore.humanize.pluralize})")
      # Used when building indexes with this class:
      @objects = Set.new
      send("get_#{klass.name.underscore.pluralize}", ids)
      @objects.delete(nil)
      @objects.delete({})
      @objects.to_a.in_groups_of(2500, false) do |group|
        delete_batch(klass, group.map { |item| item[:resource_id] })
        EOL.log("Adding #{group.size} items...")
        begin
          connection.add(group)
        rescue => e
          find_failing_add(group)
          raise e
        end
      end
      EOL.log("Committing...")
      connection.commit
      EOL.log_return
      @objects = nil # Saves some memory (hopefully).
    end

    def find_failing_add(objects)
      EOL.log("Carefully adding #{objects.size} items...")
      objects.to_a.in_groups_of(5, false) do |group|
        EOL.log("Adding #{group.count} items...")
        begin
          connection.add(group)
        rescue => e
          EOL.log("ERROR adding #{group.inspect}", prefix: "*")
          raise e
        end
      end
    end

    def delete_batch(klass, ids)
      EOL.log_call
      ids.in_groups_of(1000, false) do |group|
        EOL.log("deleting #{group.count}", prefix: ".")
        delete("resource_type:#{klass.name} AND "\
        "resource_id:(#{group.join(" OR ")})")
      end
    end

    # NOTE: called by #insert_batch via dynamic #send # TODO: long method, break
    # up. (I couldn't feel a really great place to break it on first pass, so:
    # think about it.)
    def get_taxon_concepts(ids)
      EOL.log("SolrCore::SiteSearch#get_taxon_concepts(#{ids.size} taxa)")
      # Smaller than average group because each taxon can have hundreds of
      # names, so this gets ugly fast.
      ids.in_groups_of(200, false) do |batch|
        TaxonConcept.unsuperceded.published.
                     includes(:taxon_concept_metric, :flattened_ancestors,
                       taxon_concept_names: :name).where(id: batch).
                     each do |concept|
          begin
            id = concept.id
            is_appropriate = concept.vetted_id != Vetted.inappropriate.id
            solr_strings = {}
            concept.taxon_concept_names.compact.map { |tcn| tcn.name.string }.
                    uniq.each do |str|
              normal_string = SolrCore.string(str)
              solr_strings[str] = normal_string unless normal_string.empty?
            end

            # Break up the TaxonConceptName objects by type. Order matters: each
            # precludes the next.
            names = concept.taxon_concept_names
            (preferred_commons, names) = names.partition { |tcn| tcn.vern? && tcn.preferred? && Language.iso_code(tcn.language_id) }
            (commons, names) = names.partition { |tcn| tcn.vern? && tcn.vetted_id != Vetted.untrusted.id && is_appropriate }
            # Lose any remaining names with no entry attached:
            names.delete_if { |tcn| tcn.source_hierarchy_entry_id.nil? || tcn.source_hierarchy_entry_id <= 0 }
            (surrogates, names) = names.partition { |tcn| Name.is_surrogate_or_hybrid?(solr_strings[tcn.name.string]) }
            (preferred_scientifics, synonyms) = names.partition { |tcn| tcn.preferred? }

            # Now pull out unique versions of the normalized names:
            surrogates = surrogates.map { |tcn| solr_strings[tcn.name.string] }.uniq
            preferred_scientifics = preferred_scientifics.map { |tcn| solr_strings[tcn.name.string] }.uniq
            synonyms = synonyms.map { |tcn| solr_strings[tcn.name.string] }.uniq
            scientifics = preferred_scientifics + synonyms

            # Common names are slightly trickier—they need a language and they
            # cannot be found in the scientific names...
            preferred_commons_by_iso = {}
            preferred_commons.each do |common|
              string = solr_strings[common.name.string]
              next if scientifics.include?(string)
              preferred_commons_by_iso[Language.solr_iso_code(common.language_id)] = string
            end
            commons_by_iso = {}
            commons.each do |common|
              string = solr_strings[common.name.string]
              next if scientifics.include?(string)
              commons_by_iso[Language.solr_iso_code(common.language_id)] = string
            end

            # Now build the objects:
            richness = concept.taxon_concept_metric.try(:richness_score)
            base = {
              resource_type:             "TaxonConcept",
              resource_unique_key:       "TaxonConcept_#{id}",
              resource_id:               id,
              ancestor_taxon_concept_id: concept.flattened_ancestors.map(&:ancestor_id).sort.uniq,
              richness_score:            richness
            }
            add_scientific_to_objects(base, surrogates, "Surrogate", 500)
            add_scientific_to_objects(base, preferred_scientifics, "PreferredScientific", 1)
            add_scientific_to_objects(base, synonyms, "Synonym", 3)
            add_common_to_objects(base, preferred_commons_by_iso, "PreferredCommonName", 2)
            add_common_to_objects(base, commons_by_iso, "CommonName", 4)
          rescue => e
            EOL.log("WARN: Unable to index #{concept} for Site Search: #{e.message}",
              prefix: "*")
          end
        end
      end
    end

    def add_scientific_to_objects(base, names, type, weight)
      names = Array(names)
      return if names.compact.empty?
      @objects << base.merge(
        keyword_type: type,
        keyword: names.compact,
        language: 'sci',
        resource_weight: weight
      )
    end

    def add_common_to_objects(base, names_by_iso, type, weight)
      return if names_by_iso.empty?
      @objects += names_by_iso.map do |iso, names|
        names = Array(names)
        base.merge(
          keyword_type: type,
          keyword: names.compact,
          language: iso,
          resource_weight: weight
        ) unless names.compact.empty?
      end
    end

    # TODO: Long method, break up. # NOTE: called by #insert_batch via dynamic
    # #send
    def get_data_objects(ids)
      EOL.log_call
      set_data_type_and_weight
      fields_to_index = {
        object_title: { full_text: false, resource_weight: 0 },
        description: { full_text: true, resource_weight: 2 },
        rights_statement: { full_text: false, resource_weight: 3 },
        rights_holder: { full_text: false, resource_weight: 4 },
        bibliographic_citation: { full_text: false, resource_weight: 5 },
        location: { full_text: false, resource_weight: 6 }
      }

      DataObject.with_visible_associations.
                 # TODO: we should try adding a select in here and see how that
                 # affects performance.
                 published.
                 where(id: ids).
                 find_each do |object|
        # Don't index any objects that aren't visible somewhere:
        next if object.visible_associations_empty?
        # Interesting. I wonder how common this is?
        next if object.guid !~ MIN_CHAR_REGEX
        type_and_weight = @data_type_and_weight[object.data_type_id]
        data_types = ["DataObject"]
        extra_type = type_and_weight[:type]
        data_types << extra_type if !extra_type.blank?
        resource_weight = type_and_weight[:weight]
        base_attributes = {
          resource_type:       data_types,
          resource_id:         object.id,
          resource_unique_key: "DataObject_#{object.id}",
          # TODO: should language be Language.solr_iso_code(object.language_id)?
          language:            'en',
          date_created:        SolrCore.date(object.created_at),
          date_modified:       SolrCore.date(object.updated_at)
        }
        fields_to_index.each do |field, hash|
          value = object[field]
          next if value.blank?
          value = SolrCore.string(value)
          next if value.blank?
          @objects << base_attributes.merge(
            keyword_type:    field.to_s,
            keyword:         [value],
            full_text:       hash[:full_text],
            resource_weight: resource_weight + hash[:resource_weight]
          )
        end
        # Yes, this is loading the user one at a time. We have so few, it's not
        # worth fixing that! ;)
        if vodo = object.visible_users_data_object
          unless vodo.user.username.blank?
            @objects << base_attributes.merge(
              keyword_type:    "agent",
              keyword:         vodo.user.username,
              resource_weight: resource_weight + 1
            )
          end
          unless vodo.user.full_name.blank?
            @objects << base_attributes.merge(
              keyword_type:    "agent",
              keyword:         vodo.user.full_name,
              resource_weight: resource_weight + 1
            )
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
