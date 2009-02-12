namespace :denormal do

  desc 'Recreate Normalized Names & Links'
  task :names_and_links => :environment do
    require 'spec/eol_spec_helpers' # this has the truncate method
    NormalizedName.truncate
    NormalizedLink.truncate
    Name.all.each {|name| NormalizedLink.parse! name }
  end

  desc <<EODESC
DEPRECATED.  Use PHP.

Builds random taxa table.

Runs in blocks of 100 rows, and each block can take upwards of three minutes!

At no point will the table be empty, but old entries will be removed at the end.
EODESC
  task (:build_random_taxa => :environment)  do

#    raise "This has been deprecated.  Use the PHP code to build this table."
    
    page_size = 100
    ping_rate = 5     # The user will see some feedback every time we're done making this many taxa.
    
    # NOTES:
    # - Content_level must be 3 or greater; we don't want to show any taxon where the material isn't mature enough.
    # - This was a much longer query (see commented version below) before Patrick pointed out that the id for the top image for a given
    #   taxon is stored in the hc table.  Much cleaner, now.
    # - We only want leaf nodes: species and infraspecies, currently.
    # - There may be taxa that 'stop' at the family level; we will be missing those.  We think that's preferable. (Patrick and JRice)
    # - I had to break this into chunks (pages), because the full dataset was HUGE and killed my machine's memory.  I made page size small,
    #   so that counting was "prettier" on the command line... didn't think it much mattered aside from that.
    sql = <<EOIMAGESSQL
    
    # Building random_taxa table by finding images and salient info for each
    SELECT
        dato.id, dato.thumbnail_url, dato.thumbnail_cache_url, dato.object_url, dato.object_cache_url, dato.language_id,
        he.name_id, n.italicized, hc.content_level, he.taxon_concept_id
      FROM hierarchy_entries he
        INNER JOIN names n ON (he.name_id = n.id)
        INNER JOIN hierarchies_content hc ON (hc.hierarchy_entry_id = he.id)
        INNER JOIN data_objects dato ON (dato.id = hc.image_object_id)
        INNER JOIN top_images ti ON (he.id = ti.hierarchy_entry_id)
      WHERE
        hc.content_level >= 3 AND
        he.rank_id IN (?) AND
        ti.view_order IS NOT NULL
      LIMIT ?, ?
    
EOIMAGESSQL

    first_create_date = nil
    page = 0
    empty = false
    until empty do
      print ".. Creating results #{'%4d'%(page * page_size)} - #{'%4d'%(page * page_size + page_size - 1)} "
      taxa = DataObject.find_by_sql([sql, HierarchyEntry.leaf_node_ranks.join(','), page * page_size, page_size])
      print "[#{'%04d'%(taxa.length)}]"
      taxa.each_with_index do |taxon, index|
        rt = RandomTaxon.create(
          :language_id => taxon.language_id,
          :data_object_id => taxon.id,
          :taxon_concept_id => taxon.taxon_concept_id,
          :name_id => taxon.name_id,
          :image_url => taxon.smart_image,
          :thumb_url => taxon.smart_thumb,
          :name => taxon.italicized,
          :common_name_en => taxon.italicized,
          :common_name_fr => taxon.italicized,
          :content_level => taxon.content_level
        )
        first_create_date ||= rt.created_at
        print '.' if index % ping_rate == 0 # We give them indication that we're still working.
      end
      print "\n" # Because otherwise we would be on the same line as last time.
      page += 1
      empty = (taxa.length == 0)
    end
    RandomTaxon.delete_all(['created_at < ?', first_create_date])
    puts "++ There are now #{RandomTaxon.count} random taxa in the table."
    puts "   Of those, #{RandomTaxon.count(:conditions => 'content_level = 4')} are at content level 4."
  end
end
