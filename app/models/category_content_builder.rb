#
# Responsible for building Category content, specifically for 
# the following TOC items: Search the web, BHL, Common names, 
# and Specialist projects
# 
class CategoryContentBuilder
  
  # toc_item points to a TocItem object. 
  # options is a hash of content specific options
  def content_for(toc_item, options)
    sub_name = toc_item.label.gsub(/\W/, '_').downcase

    # A list of current sub_names:
    #
    # search_the_web
    # common_names
    # specialist_projects
    # biodiversity_heritage_library

    if sub_name == "search_the_web"
      content = search_the_web(options)
      content[:content_type] = sub_name
    elsif sub_name == "common_names"
      content = common_names(options)
      content[:content_type] = sub_name
      pp [:common_names, content]
    elsif sub_name == "specialist_projects"
      content = specialist_projects(options)
      content[:content_type] = sub_name
    elsif sub_name == "biodiversity_heritage_library"
      content = biodiversity_heritage_library(options)
      content[:content_type] = sub_name
    else
      nil
    end

    content
  end

  private
  
  # =============== The following are methods specific to content_by_category

    # These should never be called; they're containers, not a leaf nodes:
    # references_and_more_information
    # evolution_and_systematics

    def search_the_web(options)
      {
        :category_name => 'Search the Web',
        :items => []
      }
    end

    def common_names(options)
      # NOTES: we had a notion of "unspecified" language.  Results were sorted.
      result = {
          :category_name => 'Common Names',
          :items         => Name.find_by_sql([
                              'SELECT names.string, l.iso_639_1 language_label, l.label, l.name
                                 FROM taxon_concept_names tcn JOIN names ON (tcn.name_id = names.id)
                                   LEFT JOIN languages l ON (tcn.language_id = l.id)
                                 WHERE tcn.taxon_concept_id = ? AND vern = 1
                                 ORDER BY language_label, string', options[:taxon_concept_id]])
        }
      return result
    end

    def specialist_projects(options)
      # I did not include these outlinks as data object in the traditional sense. For now, you'll need to go through the
      # collections and mappings tables to figure out which links pertain to the taxon (mappings has the name_id field). I
      # had some thoughts about including these in the taxa / data_object route, but I don't have plans to make this change
      # any time soon.
      # 
      # I had the table hierarchies_content which was supposed to let us know roughly what we had for each hierarchies_entry
      # (text, images, maps...). But, maybe it makes sense to cache the table of contents / taxon relationships as well as
      # media. Another de-normalized table. It may seem sloppy, but I'm sure we'll have to use de-normalized tables a lot in
      # this project.

  #     mappings = Mapping.find_by_sql([<<EO_MAPPING_SQL, id, @current_user.vetted])
  #       
  #       SELECT DISTINCT m.*, a.full_name agent_full_name, c.*
  #         FROM taxon_concept_names tcn
  #           LEFT JOIN mappings m USING (name_id)
  #           LEFT JOIN collections c ON (m.collection_id = c.id)
  #           LEFT JOIN agents a ON (c.agent_id = a.id)
  #         WHERE tcn.taxon_concept_id = ?
  #           AND (c.vetted = 1 OR c.vetted = ?) # Specialist Projects / Mappings
  # 
  # EO_MAPPING_SQL
  # 
  #     results = []
  #     mappings.each do |mapping|
  #       collection_url = mapping.collection.uri.gsub!(/FOREIGNKEY/, mapping.foreign_key)
  #       results << {
  #         :agent_name       => mapping.agent_full_name || '[unspecified]',
  #         :collection_title => mapping.collection.title,
  #         :collection_link  => mapping.collection.link,
  #         :url              => collection_url,
  #         :icon             => mapping.collection.logo_url # FIX THIS LATER TODO
  #       }
  #     end

      current_user=options[:current_user]
      vetted = current_user.blank? ? '0' : current_user.vetted

      return_mapping_objects = []
      mappings = SpeciesSchemaModel.connection.execute("SELECT DISTINCT m.id mapping_id, m.foreign_key foreign_key, a.full_name agent_name, c.title collection_title, c.link collection_link, c.logo_url icon, c.uri collection_uri FROM taxon_concept_names tcn JOIN mappings m ON (tcn.name_id = m.name_id) JOIN collections c ON (m.collection_id = c.id) JOIN agents a ON (c.agent_id = a.id) WHERE tcn.taxon_concept_id = #{options[:taxon_concept_id]} AND (c.vetted=1 OR c.vetted=#{vetted}) GROUP BY c.id").all_hashes
      mappings.sort_by { |mapping| mapping["agent_name"] }.each do |m|
        mapping_object = Mapping.find(m["mapping_id"].to_i)
        return_mapping_objects << mapping_object
      end

      return {
            :category_name => 'Specialist Projects',
            :projects => return_mapping_objects
          }
      
    end

    def biodiversity_heritage_library(options)

      items = SpeciesSchemaModel.connection.execute(
        "SELECT DISTINCT ti.id item_id, pt.title publication_title, pt.url publication_url,
                         pt.details publication_details, ip.year item_year, ip.volume item_volume,
                         ip.issue item_issue, ip.prefix item_prefix, ip.number item_number, ip.url item_url
         FROM taxon_concept_names tcn
           JOIN page_names pn ON (tcn.name_id = pn.name_id)
           JOIN item_pages ip ON (pn.item_page_id = ip.id)
           JOIN title_items ti ON (ip.title_item_id = ti.id)
           JOIN publication_titles pt ON (ti.publication_title_id = pt.id)
         WHERE tcn.taxon_concept_id = #{id}
         LIMIT 0,1000").all_hashes

      sorted_items = items.sort_by { |item| [item["publication_title"], item["item_year"], item["item_volume"], item["item_issue"], item["item_number"].to_i] }

      return {
            :category_name => 'Biodiversity Heritage Library',
            :items         => sorted_items
          }

    end

end