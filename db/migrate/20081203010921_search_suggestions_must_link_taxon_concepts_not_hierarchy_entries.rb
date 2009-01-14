class SearchSuggestionsMustLinkTaxonConceptsNotHierarchyEntries < ActiveRecord::Migration
  def self.up
    SearchSuggestion.all.each do |s|
      begin
        s.taxon_id = HierarchyEntry.find(s.taxon_id).taxon_concept_id
      rescue
        puts "** WARNING: Search Suggestion for #{s.term} pointed to hierarchy_entry #{s.taxon_id}, which does not appear to be valid."
        next
      end
      s.save!
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("Without knowing which hierarchy to use, I cannot reverse this migration.")
  end
end
