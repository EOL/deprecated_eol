class ContentTable < ActiveRecord::Base
  uses_translations
  CACHE_ALL_ROWS = true
  has_and_belongs_to_many :toc_items, :join_table => 'content_table_items', :association_foreign_key => 'toc_id'

  def self.create_details
    TranslatedContentTable.reset_cached_instances
    ContentTable.reset_cached_instances
    categories = [ 'Associations', 'Barcode', 'Behavior', 'Benefits', 'Brief Summary', 'Cell Biology', 'Citizen Science',
      'Citizen Science links', 'Commentary', 'Comments', 'Comprehensive Description', 'Conservation', 'Conservation Status',
      'Content Partners', 'Content Summary', 'Cyclicity', 'Data', 'Data Sources', 'Development', 'Diagnostic Description',
      'Diseases and Parasites', 'Dispersal', 'Distribution', 'Ecology', 'Education', 'Evolution',
      'Evolution and Systematics', 'Fossil History', 'Functional Adaptations', 'General Ecology', 'Genetics', 'Genome',
      'Growth', 'Habitat', 'High School Lab Series', 'Identification Resources', 'Legislation', 'Life Cycle',
      'Life Expectancy', 'Life History and Behavior', 'Look Alikes', 'Management', 'Migration', 'Molecular Biology',
      'Molecular Biology and Genetics', 'Morphology', 'Names and Taxonomy ', 'Notes', 'Nucleotide Sequences',
      'On the Web', 'Overview', 'Page Statistics', 'Physical Description', 'Physiology', 'Physiology and Cell Biology',
      'Population Biology', 'Relevance to Humans and Ecosystems', 'Reproduction', 'Risks ', 'Size',
      'Systematics or Phylogenetics', 'Threats', 'Trends', 'Trophic Strategy', 'Wikipedia',
      'Type Information', 'Taxonomy' ]
    english = Language.english
    if english
      content_table = ContentTable.create
      TranslatedContentTable.create(:content_table_id => content_table.id, :label => 'Details', :language_id => english.id, :phonetic_label => '')
      categories.each do |cat|
        toc_item = TocItem.find_by_en_label(cat)
        if toc_item
          toc_item.content_tables = [content_table]
        end
      end
    end
  end

  def self.details
    cached_find_translated(:label, 'Details', 'en', :include => { :toc_items => :info_items })
  end
end
