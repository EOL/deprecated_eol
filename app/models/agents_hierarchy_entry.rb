class AgentsHierarchyEntry < SpeciesSchemaModel

  belongs_to :hierarchy_entry
  belongs_to :agent
  belongs_to :agent_role

end

# +--------------------+---------------------+------+-----+---------+-------+
# | Field              | Type                | Null | Key | Default | Extra |
# +--------------------+---------------------+------+-----+---------+-------+
# | hierarchy_entry_id | int(10) unsigned    | NO   | PRI | NULL    |       | 
# | agent_id           | int(10) unsigned    | NO   | PRI | NULL    |       | 
# | agent_role_id      | tinyint(3) unsigned | NO   | PRI | NULL    |       | 
# | view_order         | tinyint(3) unsigned | NO   |     | NULL    |       | 
# +--------------------+---------------------+------+-----+---------+-------+

