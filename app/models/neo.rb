class Neo

  attr_reader :neo

  def initialize
    @neo = Neography::Rest.new
  end

  def create(parent_entry = nil, children = nil, depth = 0)
    return if depth >= 6
    if parent_entry.nil?
      kingdoms = Hierarchy.col.kingdoms.includes([ :name, :rank,
        { :children => [ :name, :rank,
          { :children => [ :name, :rank,
            { :children => [ :name, :rank,
              { :children => [ :name, :rank ] }
            ] }
          ] }
        ] }
      ])
      batch = []
      kingdoms.each do |he|
        start_index = batch.length
        batch << [ :create_node, { "scientific_name" => he.name.string, "rank" => he.rank.label } ]
        batch << [ :add_node_to_index, "taxon_concepts", "id", he.id, "{#{start_index}}" ]
      end
      @neo.batch *batch
      kingdoms.each do |he|
        create(he, he.children, depth + 1)
      end
    else
      parent_node = neo.get_node_index(:taxon_concepts, :id, parent_entry.id)
      batch = []
      HierarchyEntry.preload_associations(children, [ :name, :rank ])
      children[0..100].each do |he|
        start_index = batch.length
        batch << [ :create_node, { "scientific_name" => he.name.string, "rank" => he.rank.label } ]
        batch << [ :add_node_to_index, "taxon_concepts", "id", he.id, "{#{start_index}}" ]
        batch << [ :create_relationship, "has_parent", "{#{start_index}}", parent_node ]
        batch << [ :add_relationship_to_index, "has_parent_index", "id", "#{parent_entry.id}_#{he.id}", "{#{start_index + 2}}" ]
      end
      @neo.batch *batch
      children.each do |he|
        create(he, he.children, depth + 1)
      end
    end
  end

  def create_tc(tc)
    node = neo.create_node(:scientific_name => tc.scientific_name, :rank => tc.rank_label)
    neo.add_node_to_index(:tc_node_index, :id, tc.id, node)
  end

  def add_child(parent, child)
    begin
      parent_node = neo.get_node_index(:tc_node_index, :id, parent.id)
      child_node = neo.get_node_index(:tc_node_index, :id, child.id)
      child_node = create_tc(child) unless child_node
      rel = neo.create_relationship(:parent, child_node, parent_node)
      neo.add_relationship_to_index(:parents_rel_index, :id, "#{parent.id}_#{child.id}", rel) # Needed?  I doubt it
    rescue
      puts "problem adding a child"
      debugger
    end
  end

  def build_tcs
    TaxonConcept.where("id < 100").each do |tc|
      create_tc(tc)
    end
  end

  def build_children
    TaxonConcept.where("id < 100").each do |parent|
      parent.children.each do |child|
        add_child(parent, child)
      end
    end
  end

  def count_descendants_of(tc)
    neo.execute_query("start n=node({id}) match n<-[:parent*0..4]-() return count(*)", {:id => tc.id})["data"].first.first
  end

end
