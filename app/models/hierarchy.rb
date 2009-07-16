# Represents a version of the Tree of Life
#
# Because the tree changes as new species are discovered and other species are 
# reclassified, etc, there's a Hierarchy object available for each version 
# of the Tree of Life that's been imported, eg.
#
#   >> Hierarchy.all.map &:label
#   => [
#        "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2007", 
#        "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2008"
#      ]
#
class Hierarchy < SpeciesSchemaModel

  belongs_to :agent           # This is the attribution.

  has_many :hierarchy_entries
  alias entries hierarchy_entries

  def self.default
    YAML.load(Rails.cache.fetch('hierarchies/default') do
      Hierarchy.find_by_label("Species 2000 & ITIS Catalogue of Life: Annual Checklist 2008").to_yaml
    end)
  end

  # This is the first hierarchy we used, and we need it to serve "old" URLs (ie: /taxa/16222828 => Roenbergensis)
  def self.original
    YAML.load(Rails.cache.fetch('hierarchies/original') do
      Hierarchy.find_by_label("Species 2000 & ITIS Catalogue of Life: Annual Checklist 2007").to_yaml
    end)
  end

  def kingdoms(current_user = User.new(:expertise => $DEFAULT_EXPERTISE, :language => Language.english))
    kingdoms = HierarchyEntry.find_all_by_parent_id_and_hierarchy_id(0, id).reject {|he| he.taxon_concept.nil?}
    kingdoms.sort! do |a,b|
      a.name(current_user.expertise, current_user.language, :classification) <=>
        b.name(current_user.expertise, current_user.language, :classification)
    end
    return kingdoms
  end
  
  def kingdoms_hash(detail_level = :middle, language = Language.english)
    language ||= Language.english # Not sure why; this didn't work as a default to the argument.
        
    kingdoms = SpeciesSchemaModel.connection.execute("
      SELECT n1.string scientific_name, n1.italicized scientific_name_italicized,
             n2.string common_name, n2.italicized common_name_italicized,
             he.taxon_concept_id id, he.id hierarchy_entry_id, he.lft lft, he.rgt rgt, he.rank_id,
             hc.content_level content_level, hc.image image, hc.text text, hc.child_image child_image,
             r.label rank_string, he_source.hierarchy_id source_hierarchy_id
        FROM hierarchy_entries he
          JOIN names n1 ON (he.name_id=n1.id)
          JOIN hierarchies_content hc ON (he.id=hc.hierarchy_entry_id)
          LEFT JOIN (taxon_concept_names tcn JOIN names n2 ON (tcn.name_id=n2.id)
            LEFT JOIN hierarchy_entries he_source ON (tcn.source_hierarchy_entry_id=he_source.id))
            ON (he.taxon_concept_id=tcn.taxon_concept_id AND tcn.preferred=1 AND tcn.language_id=#{language.id})
          LEFT JOIN ranks r ON (he.rank_id=r.id)
        WHERE he.parent_id=0 AND he.hierarchy_id=#{id}
        ORDER BY hierarchy_entry_id
    ").all_hashes
    
    deduped_kingdoms = []
    index = 0
    kingdoms.each do |node|
      if !deduped_kingdoms[index-1].nil? && node['hierarchy_entry_id'] == deduped_kingdoms[index-1]['hierarchy_entry_id']
        deduped_kingdoms[index-1] = node if node['source_hierarchy_id'].to_i == id
      else
        deduped_kingdoms[index] = node
        index += 1
      end
    end
    
    deduped_kingdoms.map do |node|
      node_to_hash(node, detail_level)
    end.sort_by {|k| k[:name]}
  end
  
  def node_to_hash(node, detail_level)
    is_leaf_node = (node['rgt'].to_i - node['lft'].to_i == 1)
    name = (detail_level.to_sym == :expert) ? node['scientific_name'].firstcap : (node['common_name'] == nil  ? node['scientific_name'].firstcap : node['common_name'].firstcap)
    #name = node['scientific_name_italicized'] if (is_leaf_node && (detail_level.to_sym == :expert || node['common_name'] == nil))
    name = node['scientific_name_italicized'] if (Rank.italicized_ids.include?(node['rank_id'].to_i) && (detail_level.to_sym == :expert || node['common_name'] == nil))
    {
      :name => name,
      :italicized => detail_level.to_sym == :expert ? node['scientific_name_italicized'].firstcap : (node['common_name_italicized'] == nil  ? node['scientific_name_italicized'].firstcap : node['common_name_italicized'].firstcap),
      :id => node['id'],
      :rank_string => node['rank_string'],
      :hierarchy_entry_id => node['hierarchy_entry_id'],
      :valid => node['content_level'].to_i > $VALID_CONTENT_LEVEL,
      :enable => is_leaf_node ? (node['text'].to_i == 1 || node['image'].to_i == 1) : (node['text'].to_i == 1 || node['image'].to_i == 1 || node['child_image'].to_i == 1)
    }
  end
  
  def attribution
    string = [agent]
    string.first.full_name = string.first.display_name = label # To change the name from just "Catalogue of Life"
    return string
  end

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: hierarchies
#
#  id                      :integer(4)      not null, primary key
#  hierarchy_group_id      :integer(4)      not null
#  description             :text            not null
#  hierarchy_group_version :integer(1)      not null
#  label                   :string(255)     not null
#  url                     :string(255)     not null
#  indexed_on              :timestamp       not null

