class Neo

  attr_reader :neo

  def initialize
    @neo = Neography::Rest.new
  end

  def create_tc(tc)
    node = neo.create_node(:scientific_name => tc.scientific_name, :rank => tc.rank_label)
    neo.add_node_to_index(:tc_node_index, :id, tc.id, node)
  end

  def add_child(parent, child)
    parent_node = neo.get_node_index(:tc_node_index, :id, parent.id)
    child_node = neo.get_node_index(:tc_node_index, :id, child.id)
    rel = neo.create_relationship(:parent, child_node, parent_node)
    neo.add_relationship_to_index(:parents_rel_index, :id, "#{parent.id}_#{child.id}", rel) # Needed?  I doubt it.
  end
  
  def init_old
    Neography.configure do |config|
      config.protocol       = "http://"
      config.server         = "localhost"
      config.port           = 7474
      config.directory      = "/neo4j-community-1.8.1"
      config.cypher_path    = "/cypher"
      config.gremlin_path   = "/ext/GremlinPlugin/graphdb/execute_script"
      config.log_file       = "neography.log"
      config.log_enabled    = false
      config.max_threads    = 20
      config.authentication = nil  # 'basic' or 'digest'
      config.username       = nil
      config.password       = nil
      config.parser         = {:parser => MultiJsonParser}
    end
    @neo = Neography::Rest.new
  end

  def build_tcs
    TaxonConcept.all.each do |tc|
      create_tc(tc)
    end
  end

  def build_children
    TaxonConcept.all.each do |parent|
      parent.children.each do |child|
        add_child(parent, child)
      end
    end
  end

  def count_descendants_of(tc)
    neo.execute_query("start n=node({id}) match n<-[:parent*0..4]-() return count(*)", {:id => tc.id})["data"].first.first
  end

end
