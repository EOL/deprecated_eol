 namespace :hierarchy_entries do
  desc 'delete mixed hierarchy entries'
     task :delete => :environment do
        resource= Resource.find_by_sql([ "select id from resources where content_partner_id=?", 9])
        harvest_event_ids= HarvestEvent.find_by_sql( ["select id from harvest_events where resource_id IN (?) ;",resource ])
        he_id= HarvestEventsHierarchyEntry.find_by_sql(["select hierarchy_entry_id from harvest_events_hierarchy_entries where harvest_event_id IN (?)", harvest_event_ids])
        hierarchy_entries = []
        he_id.each  do |i|
          hierarchy_entries<< i.hierarchy_entry_id
        end
        name_id=  Name.find_by_sql([ "select id from names where string=?", 'Dictyoptera Latreille 1829'])
        he = HierarchyEntry.find_by_sql(["select id from hierarchy_entries  where taxon_concept_id=?  AND id IN  (?) AND name_id= ? ;",2636291, hierarchy_entries, name_id])

        if taxon_he= TaxonConcept.find(2636291).hierarchy_entries.find_by_id(he)
          taxon_he.delete
        end
        if dato_he = DataObjectsHierarchyEntry.find_all_by_hierarchy_entry_id(he)
          dato_he.each do |d|
            d.delete
          end
        end
        
        resource= Resource.find_by_sql([ "select id from resources where content_partner_id=?", 74])
        harvest_event_ids= HarvestEvent.find_by_sql( ["select id from harvest_events where resource_id IN (?) ;",resource ])
        he_id= HarvestEventsHierarchyEntry.find_by_sql(["select hierarchy_entry_id from harvest_events_hierarchy_entries where harvest_event_id IN (?)", harvest_event_ids])
        hierarchy_entries = []
        he_id.each  do |i|
          hierarchy_entries<< i.hierarchy_entry_id  
        end
        parent_name_id=  Name.find_by_sql([ "select id from names where string=?", 'Dictyoptera'])
        parent_he_id = HierarchyEntry.find_by_sql(["select id from hierarchy_entries  where taxon_concept_id=?  AND id IN  (?) AND name_id= ? ;",110476, hierarchy_entries, parent_name_id])
        he= HierarchyEntry.find_by_parent_id(parent_he_id)
        if taxon_he= TaxonConcept.find(he.taxon_concept_id).hierarchy_entries.find_by_id(he)
          taxon_he.delete
        end
        if dato_he = DataObjectsHierarchyEntry.find_all_by_hierarchy_entry_id(he)
          dato_he.each do |d|
            d.delete
          end
        end
        Rake::Task["solr:rebuild_all"].invoke
  end
end
