class CreateTopSpeciesImagesTables < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute("create table top_species_images like top_images")
    execute("create table top_unpublished_species_images like top_unpublished_images")
    
    rank_ids = []
    if r = Rank.find_by_label('sp')
      rank_ids << r.id
    end
    if r = Rank.find_by_label('sp.')
      rank_ids << r.id
    end
    if r = Rank.find_by_label('subspecies')
      rank_ids << r.id
    end
    if r = Rank.find_by_label('subsp')
      rank_ids << r.id
    end
    if r = Rank.find_by_label('subsp.')
      rank_ids << r.id
    end
    if r = Rank.find_by_label('variety')
      rank_ids << r.id
    end
    if r = Rank.find_by_label('var')
      rank_ids << r.id
    end
    if r = Rank.find_by_label('var.')
      rank_ids << r.id
    end
    
    if rank_ids != []
      execute("INSERT INTO top_species_images (SELECT ti.* FROM hierarchy_entries he JOIN top_images ti ON (he.id=ti.hierarchy_entry_id) WHERE he.rank_id IN (#{rank_ids.join(',')}))")
      execute("INSERT INTO top_unpublished_species_images (SELECT tui.* FROM hierarchy_entries he JOIN top_unpublished_images tui ON (he.id=tui.hierarchy_entry_id) WHERE he.rank_id IN (#{rank_ids.join(',')}))")
    end
  end
  
  def self.down
    drop_table "top_species_images"
    drop_table "top_unpublished_species_images"
  end
end
