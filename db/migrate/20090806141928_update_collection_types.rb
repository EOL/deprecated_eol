class UpdateCollectionTypes < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute("INSERT INTO collection_types (parent_id, label) VALUES (0, 'Taxonomy'), (0, 'Molecular bar codes'), (0, 'Description'), (0, 'Images'), (0, 'Distribution'), (0, 'Conservation status'), (0, 'Name information'), (0, 'Molecular data'), (0, 'Nomenclature'), (0, 'Sounds'), (0, 'Links'), (0, 'Literature')")
    
    if c = Collection.find_by_title('ITIS Standard Report Page')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
    end
    if c = Collection.find_by_title('AlgaeBase :: Species Detail')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('ILDIS taxon details')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('FishBase species detail')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('Index Fungorum record details')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
    end
    if c = Collection.find_by_title('2008 Annual Checklist: Taxon Details')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
    end
    if c = Collection.find_by_title('2008 Annual Checklist: Hierarchy')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
    end
    if c = Collection.find_by_title('Nomenclator Zoologicus Record Detail')
      c.collection_types << CollectionType.find_by_label('Nomenclature')
    end
    if c = Collection.find_by_title('NCBI Taxonomy Browser')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
      c.collection_types << CollectionType.find_by_label('Molecular data')
    end
    if c = Collection.find_by_title('Micro*scope taxon details')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('GRIN taxon details')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('The Nearctic Spider Database')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('MarBEF ERMS taxon details')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
    end
    if c = Collection.find_by_title('USDA Plants')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('AntWeb species details')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
      c.collection_types << CollectionType.find_by_label('Images')
      c.collection_types << CollectionType.find_by_label('Distribution')
    end
    if c = Collection.find_by_title('AmphibiaWeb species info')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('ADW: species information')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('Tropicos taxon details')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
    end
    if c = Collection.find_by_title('BioLib.cz Taxon Profile')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('Hymenoptera Name Server taxon details')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
    end
    if c = Collection.find_by_title('Fauna Europaea : Taxon Details')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
    end
    if c = Collection.find_by_title('GBIF Portal')
      c.collection_types << CollectionType.find_by_label('Distribution')
      c.collection_types << CollectionType.find_by_label('Name information')
    end
    if c = Collection.find_by_title('Morphbank taxon images')
      c.collection_types << CollectionType.find_by_label('Imgaes')
    end
    if c = Collection.find_by_title('Tree of Life taxon details')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('IUCN Red List')
      c.collection_types << CollectionType.find_by_label('Conservation status')
    end
    if c = Collection.find_by_title('Namebank record details')
      c.collection_types << CollectionType.find_by_label('Name information')
    end
    if c = Collection.find_by_title('OBIS Species Information')
      c.collection_types << CollectionType.find_by_label('Distribution')
    end
    if c = Collection.find_by_title('ABBI Species Information')
      c.collection_types << CollectionType.find_by_label('Molecular bar codes')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('FISHBOL Species Information')
      c.collection_types << CollectionType.find_by_label('Molecular bar codes')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('POLARBOL Species Information')
      c.collection_types << CollectionType.find_by_label('Description')
      c.collection_types << CollectionType.find_by_label('Molecular bar codes')
    end
    if c = Collection.find_by_title('MARBOL Species Information')
      c.collection_types << CollectionType.find_by_label('Description')
      c.collection_types << CollectionType.find_by_label('Molecular bar codes')
    end
    if c = Collection.find_by_title('Wikipedia, the free encyclopedia')
      c.collection_types << CollectionType.find_by_label('Description')
    end
    if c = Collection.find_by_title('Barcode of Life Data Systems')
      c.collection_types << CollectionType.find_by_label('Molecular bar codes')
    end
    if c = Collection.find_by_title('ARKive - images of life on Earth')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
      c.collection_types << CollectionType.find_by_label('Imgaes')
      c.collection_types << CollectionType.find_by_label('Distribution')
    end
    if c = Collection.find_by_title('xeno-canto Pages')
      c.collection_types << CollectionType.find_by_label('Sounds')
    end
    if c = Collection.find_by_title('SpeciesIndex')
      c.collection_types << CollectionType.find_by_label('Links')
    end
    if c = Collection.find_by_title('Shorefishes of the Tropical Eastern Pacific')
      c.collection_types << CollectionType.find_by_label('Description')
      c.collection_types << CollectionType.find_by_label('Taxonomy')
      c.collection_types << CollectionType.find_by_label('Distribution')
    end
    if c = Collection.find_by_title('LigerCat')
      c.collection_types << CollectionType.find_by_label('Links')
      c.collection_types << CollectionType.find_by_label('Literature')
    end
    
  end

  def self.down
    execute("TRUNCATE TABLE collection_types")
  end
end
