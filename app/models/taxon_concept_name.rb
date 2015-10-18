class TaxonConceptName < ActiveRecord::Base

  self.primary_keys = :taxon_concept_id, :name_id, :source_hierarchy_entry_id, :language_id, :synonym_id

  belongs_to :language
  belongs_to :name
  belongs_to :synonym
  belongs_to :source_hierarchy_entry, class_name: HierarchyEntry.to_s
  belongs_to :taxon_concept
  belongs_to :vetted

  scope :preferred, -> { where(preferred: true) }

  def can_be_deleted_by?(user)
    agents.map(&:user).include?(user)
  end

  def self.sort_by_language_and_name(taxon_concept_names)
    taxon_concept_names.compact.sort_by do |tcn|
      language_iso = tcn.language.blank? ? '' : tcn.language.iso_639_1
      [language_iso,
       tcn.preferred * -1,
       tcn.name.try(:string)]
    end
  end

  def to_jsonld
    jsonld = { '@type' => 'gbif:VernacularName',
                          'dwc:vernacularName' => { language.iso_639_1 => name.string },
                          'dwc:taxonID' => KnownUri.taxon_uri(taxon_concept_id) }
    if preferred?
      jsonld['gbif:isPreferredName'] = true
    end
    jsonld
  end

  # TODO - why pass in by_whom, here? We don't use it. I'm assuming it's a
  # duck-type for now and leaving it, but... TODO - we should actually update
  # the instance, not just the DB. True, in practice we don't care, but it
  # hardly violates the principle of least surprise (I wasted 15 minutes with a
  # test because of it).
  def vet(vet_obj, by_whom)
    raw_update_attribute(:vetted_id, vet_obj.id)
    # We don't want untrusted names to be preferred:
    raw_update_attribute(:preferred, 0) if vet_obj == Vetted.untrusted
    # There *are* TCNs in prod w/o synonyms (from CoL, I think)
    synonym.update_attributes!(vetted: vet_obj) if synonym
  end

  # Our composite primary keys gem is too stupid to handle this change
  # correctly, so we're bypassing it here:
  def raw_update_attribute(key, val)
    raise "Invalid key" unless self.respond_to? key
    TaxonConceptName.connection.execute(ActiveRecord::Base.sanitize_sql_array([%Q{
      UPDATE `#{self.class.table_name}`
      SET `#{key}` = ?
      WHERE name_id = ?
        AND taxon_concept_id = ?
        AND source_hierarchy_entry_id = ?
    }, val, self[:name_id], self[:taxon_concept_id], self[:source_hierarchy_entry_id]]))
  end

  def agents
    all_agents = []
    if synonym
      all_agents += synonym.agents
    elsif source_hierarchy_entry
      all_agents += source_hierarchy_entry.agents
    end
    all_agents.delete(Hierarchy.eol_contributors.agent)
    all_agents.uniq.compact
  end

  def hierarchies
    all_hierarchies = []
    if synonym
      all_hierarchies << synonym.hierarchy unless synonym.hierarchy == Hierarchy.eol_contributors
    elsif source_hierarchy_entry
      all_hierarchies << source_hierarchy_entry.hierarchy unless source_hierarchy_entry.hierarchy == Hierarchy.eol_contributors
    end
    all_hierarchies.uniq.compact
  end

  # Huge, ugly, awful method. You probably want to wrap this in a transaction.
  def update_ids(taxon_concept_ids)
    EOL.log_call
    taxon_concept_ids = Array(taxon_concept_ids)
    taxon_concept_ids.in_groups_of(500, false) do |batch_ids|
      sleep(0.2) # Let's not throttle the DB.
      name_ids = {}
      matching_ids = {}
      common_and_acronym_ids =
      # Gott Im Himmel, I am not going to re-write this PHP monstrosity right
      # now. TODO (For one, this really is NOT worth doing as a UNION. This
      # isn't the SQL olympics, two queries would be JUST FINE, and would avoid
      # the stupid "type" column. It could make this call quite tiny. Sigh)
      query = "(SELECT he.taxon_concept_id, he.id, he.name_id, 'preferred' AS "\
        "type FROM hierarchy_entries he WHERE taxon_concept_id IN ("\
        "#{batch_ids.join(",")}) AND ((he.published = 1 AND "\
        "he.visibility_id = #{Visibility.get_visible.id}) OR "\
        "(he.published = 0 AND he.visibility_id = "\
        "#{Visibility.get_preview.id}))) "\
        "UNION "\
        "(SELECT he.taxon_concept_id, s.hierarchy_entry_id, s.name_id, "\
        "'synonym' AS type FROM hierarchy_entries he JOIN synonyms s ON "\
        "(he.id=s.hierarchy_entry_id) WHERE he.taxon_concept_id IN "\
        "(#{batch_ids.join(",")}) AND s.language_id = 0 AND "\
        "s.synonym_relation_id NOT IN "\
        "(#{SynonymRelation.common_and_acronym_ids.join(",")}) AND "\
        "((he.published = 1 AND he.visibility_id = "\
        "#{Visibility.get_visible.id}) OR (he.published = 0 AND "\
        "he.visibility_id = #{Visibility.get_preview.id})))"
        HierarchyEntry.find_by_sql(query).each do |entry|
          name_ids[entry.id] ||= Set.new
          name_ids[entry.id] << entry.taxon_concept_id
          matching_ids[entry.taxon_concept_id] ||= {}
          matching_ids[entry.taxon_concept_id][entry.name_id] ||= {}
          matching_ids[entry.taxon_concept_id][entry.name_id][entry.id] =
            entry["type"]
        end
        if name_ids.empty?
          EOL.log("No name IDs found...", prefix: ".")
        else
          # "This makes sure we have a scientific name, gets the
          # canonicalFormID"
          Name.joins(canonical_form: [ :names ]).
            select("names.id, names_canonical_forms.id canonical_name_id").
            where(["names.id IN (?) AND "\
              "names_canonical_forms.string = canonical_forms.string",
              name_ids]).
            find_each do |name|
            unless name.id == name["canonical_name_id"]
              name_ids[name.id].each do |taxon_concept_id|
                matching_ids[taxon_concept_id] ||= {}
                matching_ids[taxon_concept_id][name["canonical_name_id"]] ||= {}
                # TODO: WTF?!
                matching_ids[taxon_concept_id][name["canonical_name_id"]][0] = 1
              end
            end
          end
        end
      # YOU WERE HERE
  #
  #     $common_names = array();
  #     $preferred_in_language = array();
  #     $query = "SELECT he.taxon_concept_id, he.published, he.visibility_id, s.id, s.hierarchy_id, s.hierarchy_entry_id, s.name_id, s.language_id, s.preferred, s.vetted_id FROM hierarchy_entries he JOIN synonyms s ON (he.id=s.hierarchy_entry_id) JOIN vetted v ON (s.vetted_id=v.id) WHERE he.taxon_concept_id IN (". implode(",", $batch_ids) .") AND s.language_id!=0 AND (s.synonym_relation_id=".SynonymRelation::genbank_common_name()->id." OR s.synonym_relation_id=".SynonymRelation::common_name()->id.") ORDER BY s.language_id, (s.hierarchy_id=".Hierarchy::contributors()->id.") DESC, v.view_order ASC, s.preferred DESC, s.id DESC";
  #     foreach($mysqli->iterate_file($query) as $row_num => $row)
  #     {
  #         $taxon_concept_id = $row[0];
  #         $published = $row[1];
  #         $visibility_id = $row[2];
  #         $synonym_id = $row[3];
  #         $hierarchy_id = $row[4];
  #         $hierarchy_entry_id = $row[5];
  #         $name_id = $row[6];
  #         $language_id = $row[7];
  #         $preferred = $row[8];
  #         $vetted_id = $row[9];
  #
  #         // skipping Wikipedia common names entirely
  #         if($hierarchy_id == @Hierarchy::wikipedia()->id) continue;
  #         $curator_name = ($hierarchy_id == @Hierarchy::contributors()->id);
  #         $ubio_name = ($hierarchy_id == @Hierarchy::ubio()->id);
  #         if($curator_name || $ubio_name || $curator_name || ($published == 1 && $visibility_id == Visibility::visible()->id))
  #         {
  #             if(isset($preferred_in_language[$taxon_concept_id][$language_id])) $preferred = 0;
  #             if($preferred && $curator_name && ($vetted_id == Vetted::trusted()->id || $vetted_id == Vetted::unknown()->id))
  #             {
  #                 $preferred_in_language[$taxon_concept_id][$language_id] = 1;
  #             }else $preferred = 0;
  #             if(!isset($common_names[$taxon_concept_id])) $common_names[$taxon_concept_id] = array();
  #             $common_names[$taxon_concept_id][] = array(
  #                 'synonym_id' => $synonym_id,
  #                 'language_id' => $language_id,
  #                 'name_id' => $name_id,
  #                 'hierarchy_entry_id' => $hierarchy_entry_id,
  #                 'preferred' => $preferred,
  #                 'vetted_id' => $vetted_id,
  #                 'is_curator_name' => $curator_name);
  #         }
  #     }
  #
  #     // if there was no preferred name
  #     foreach($common_names as $taxon_concept_id => $arr)
  #     {
  #         foreach($arr as $key => $arr2)
  #         {
  #             if(@!$preferred_in_language[$taxon_concept_id][$arr2['language_id']] &&
  #               ($arr2['vetted_id'] == Vetted::trusted()->id || $arr2['vetted_id'] == Vetted::unknown()->id))
  #             {
  #                 $common_names[$taxon_concept_id][$key]['preferred'] = 1;
  #                 $preferred_in_language[$taxon_concept_id][$arr2['language_id']] = 1;
  #             }
  #         }
  #     }
  #
  #
  #     $mysqli->delete("DELETE FROM taxon_concept_names WHERE taxon_concept_id IN (". implode(",", $batch_ids) .")");
  #
  #     $tmp_file_path = temp_filepath();
  #     if(!($LOAD_DATA_TEMP = fopen($tmp_file_path, "w+")))
  #     {
  #       debug(__CLASS__ .":". __LINE__ .": Couldn't open file: " .$tmp_file_path);
  #       return;
  #     }
  #     /* Insert the scientific names */
  #     foreach($matching_ids as $taxon_concept_id => $arr)
  #     {
  #         foreach($arr as $name_id => $arr2)
  #         {
  #             foreach($arr2 as $hierarchy_entry_id => $type)
  #             {
  #                 $preferred = 0;
  #                 if($hierarchy_entry_id && $type == "preferred") $preferred = 1;
  #                 fwrite($LOAD_DATA_TEMP, "$taxon_concept_id\t$name_id\t$hierarchy_entry_id\t0\t0\t$preferred\n");
  #             }
  #         }
  #     }
  #     $mysqli->load_data_infile($tmp_file_path, 'taxon_concept_names');
  #     unlink($tmp_file_path);
  #
  #     $tmp_file_path = temp_filepath();
  #     if(!($LOAD_DATA_TEMP = fopen($tmp_file_path, "w+")))
  #     {
  #       debug(__CLASS__ .":". __LINE__ .": Couldn't open file: " .$tmp_file_path);
  #       return;
  #     }
  #     /* Insert the common names */
  #     foreach($common_names as $taxon_concept_id => $arr)
  #     {
  #         foreach($arr as $key => $arr2)
  #         {
  #             $synonym_id = $arr2['synonym_id'];
  #             $language_id = $arr2['language_id'];
  #             $name_id = $arr2['name_id'];
  #             $hierarchy_entry_id = $arr2['hierarchy_entry_id'];
  #             $preferred = $arr2['preferred'];
  #             $vetted_id = $arr2['vetted_id'];
  #             fwrite($LOAD_DATA_TEMP, "$taxon_concept_id\t$name_id\t$hierarchy_entry_id\t$language_id\t1\t$preferred\t$synonym_id\t$vetted_id\n");
  #         }
  #     }
  #     $mysqli->load_data_infile($tmp_file_path, 'taxon_concept_names');
  #     unlink($tmp_file_path);
  #
  #     unset($matching_ids);
  #     unset($common_names);
  #     unset($name_ids);
  #     unset($preferred_in_language);
  #     $mysqli->commit();
  # }
    end
  end

end
