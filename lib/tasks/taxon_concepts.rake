namespace :taxon_concepts do
  desc 'generate json'
  task :generate_json => :environment do
    puts "Started (#{Time.now})\n"
    # Cache the ranks so we're not constantly looking them up:
    ranks = TranslatedRank.where(language_id: Language.english.id)
    languages = TranslatedLanguage.where(language_id: Language.english.id)
    File.open("public/taxon_concepts.json", "wb") do |file|
      # Headers:
      file << ["taxon_concept_id", "rank", "ancestors_taxon_concepts_ids",
        "preferred_scientific_names", "preferred_common_names",
        "hierarchy_entry_id", "content_provider_name", "resource_name",
        "identifier"]
      index = 0
      batch_size = 1000
      # A little weird, but faster to go through the preferred entry rather than
      # calculate it...
      TaxonConceptPreferredEntry.
        includes(hierarchy_entry: [:name, :rank, :flattened_ancestors],
          taxon_concept: { preferred_names: [:name],
            preferred_common_names: [:name],
            hierarchy_entries: { hierarchy: [:resource] } }).
        find_each(batch_size: batch_size) do |tcpe|
        index += 1
        next unless tcpe.taxon_concept
        next unless tcpe.hierarchy_entry
        next unless tcpe.taxon_concept.published?
        next unless tcpe.hierarchy_entry.published?
        puts "  #{index}..." if index % batch_size == 0
        data = {}
        data[:taxon_concept_id] = tcpe.taxon_concept_id
        data[:rank] = ranks.find { |r| r.rank_id == tcpe.hierarchy_entry.rank_id }.try(:label)
        data[:ancestor_taxon_concepts_ids] = HierarchyEntry.select(:taxon_concept_id).
          where(['id IN (?)',
            tcpe.hierarchy_entry.flattened_ancestors.map(&:ancestor_id)]).
          map(&:taxon_concept_id)
        data[:preferred_scientific_names] =
          tcpe.taxon_concept.preferred_names.map { |pn| pn.name.try(:string) }.
          compact.sort.uniq
        data[:preferred_common_names] =
          tcpe.taxon_concept.preferred_common_names.
          map { |pn| { name: pn.name.try(:string) || '[MISSING]',
            language: languages.find { |l|
              l.language_id == pn.language_id } } }
        data[:outlinks] = []
        tcpe.taxon_concept.hierarchy_entries.each do |entry|
          data[:outlinks] << {
            hierarchy_entry_id: tcpe.hierarchy_entry_id,
            resource_id: tcpe.hierarchy_entry.try(:hierarchy).try(:resource).
              try(:id),
            resource: tcpe.hierarchy_entry.try(:hierarchy).try(:label),
            identifier: tcpe.hierarchy_entry.identifier
          }
        end
        file.write(data.to_json)
      end
      print "\n Done \n"
    end
  end
end
