class TaxonContentSection < SpeciesSchemaModel

  uses_translations

  has_and_belongs_to_many :toc_items, :join_table => 'table_of_contents_taxon_content_sections',
    :association_foreign_key => 'table_of_contents_id'

  def self.create_default
    overview = TaxonContentSection.create(:order => 1)
    TranslatedTaxonContentSection.create(:name => 'Overview', :taxon_content_section_id => overview.id,
                                         :language_id => Language.english.id)
    overview.toc_items = [TocItem.distribution, TocItem.comprehensive_description, TocItem.brief_summary]
    overview.save!
  end

  def self.overview
    cached_find_translated(:name, 'Overview')
  end

end
