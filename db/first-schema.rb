# This is the version of the schema that Patrick created on May 16th.
#
# It was created by setting the database connection to his table (called "eol_dev" at the time), then running
# the db:schema:dump rake task.
#
# I assume we will eventually be using this (or something like it) as an initial migratation. 

ActiveRecord::Schema.define() do

  create_table "agent_roles", :force => true do |t|
    t.string "label", :limit => 100, :null => false
  end

  add_index "agent_roles", ["label"], :name => "label"

  create_table "agents", :force => true do |t|
    t.string "full_name",                  :null => false
    t.string "acronym",     :limit => 20,  :null => false
    t.string "title",       :limit => 20,  :null => false
    t.string "given_name",                 :null => false
    t.string "family_name",                :null => false
    t.string "homepage",                   :null => false
    t.string "email",       :limit => 75,  :null => false
    t.string "telephone",   :limit => 30,  :null => false
    t.string "address",     :limit => 400, :null => false
    t.string "logo_url",                   :null => false
  end

  create_table "agents_data_objects", :id => false, :force => true do |t|
    t.integer "data_objects_id", :limit => 10, :null => false
    t.integer "agents_id",       :limit => 10, :null => false
    t.integer "agent_roles_id",  :limit => 3,  :null => false
  end

  create_table "agents_resources", :id => false, :force => true do |t|
    t.integer "agents_id",    :limit => 10, :null => false
    t.integer "resources_id", :limit => 10, :null => false
  end

  create_table "audiences", :force => true do |t|
    t.string "label", :limit => 100, :null => false
  end

  add_index "audiences", ["label"], :name => "label"

  create_table "audiences_data_objects", :id => false, :force => true do |t|
    t.integer "data_objects_id", :limit => 10, :null => false
    t.integer "audiences_id",    :limit => 3,  :null => false
  end

  create_table "common_names", :force => true do |t|
    t.string  "common_name",               :null => false
    t.integer "languages_id", :limit => 5, :null => false
  end

  create_table "common_names_taxa", :id => false, :force => true do |t|
    t.integer "taxa_id",         :limit => 10, :null => false
    t.integer "common_names_id", :limit => 10, :null => false
  end

  create_table "concepts", :id => false, :force => true do |t|
    t.integer "names_id",       :limit => 10, :null => false
    t.integer "hierarchies_id", :limit => 10, :null => false
    t.integer "vern",           :limit => 3,  :null => false
    t.integer "languages_id",   :limit => 5,  :null => false
    t.integer "preferred",      :limit => 3,  :null => false
    t.integer "search_for",     :limit => 3,  :null => false
  end

  create_table "data_objects", :force => true do |t|
    t.integer   "data_types_id",          :limit => 5,   :null => false
    t.integer   "mime_types_id",          :limit => 5,   :null => false
    t.string    "object_title",                          :null => false
    t.integer   "languages_id",           :limit => 5,   :null => false
    t.integer   "licenses_id",            :limit => 3,   :null => false
    t.string    "rights_statement",       :limit => 300, :null => false
    t.string    "rights_holder",                         :null => false
    t.string    "bibliographic_citation", :limit => 300, :null => false
    t.string    "source_url",                            :null => false
    t.text      "description",                           :null => false
    t.string    "object_url",                            :null => false
    t.string    "object_cache_url",                      :null => false
    t.string    "location",                              :null => false
    t.float     "latitude",                              :null => false
    t.float     "longitude",                             :null => false
    t.float     "altitude",                              :null => false
    t.timestamp "object_created_at",                     :null => false
    t.timestamp "object_modified_at",                    :null => false
    t.timestamp "created_at",                            :null => false
    t.timestamp "updated_at",                            :null => false
    t.integer   "vetted",                 :limit => 3,   :null => false
    t.integer   "visible",                :limit => 3,   :null => false
  end

  add_index "data_objects", ["data_types_id"], :name => "data_types_id"

  create_table "data_objects_info_items", :id => false, :force => true do |t|
    t.integer "data_objects_id", :limit => 10, :null => false
    t.integer "info_items_id",   :limit => 5,  :null => false
  end

  create_table "data_objects_references", :id => false, :force => true do |t|
    t.integer "data_objects_id", :limit => 10, :null => false
    t.integer "references_id",   :limit => 10, :null => false
  end

  create_table "data_objects_taxa", :id => false, :force => true do |t|
    t.integer "taxa_id",         :limit => 10, :null => false
    t.integer "data_objects_id", :limit => 10, :null => false
    t.string  "identifier",                    :null => false
  end

  create_table "data_types", :force => true do |t|
    t.string "label", :null => false
  end

  add_index "data_types", ["label"], :name => "label"

  create_table "hierarchies", :force => true do |t|
    t.integer "names_id",           :limit => 10,  :null => false
    t.integer "parent_id",          :limit => 10,  :null => false
    t.integer "classifications_id", :limit => 5,   :null => false
    t.integer "ranks_id",           :limit => 5,   :null => false
    t.string  "ancestry",           :limit => 500, :null => false
    t.integer "lft",                :limit => 10,  :null => false
    t.integer "rgt",                :limit => 10,  :null => false
    t.integer "depth",              :limit => 3,   :null => false
  end

  add_index "hierarchies", ["names_id"], :name => "names_id"
  add_index "hierarchies", ["lft"], :name => "lft"

  create_table "hierarchies_names", :primary_key => "hierarchies_id", :force => true do |t|
    t.string "italics",           :limit => 300, :null => false
    t.string "italics_canonical", :limit => 300, :null => false
    t.string "normal",            :limit => 300, :null => false
    t.string "normal_canonical",  :limit => 300, :null => false
    t.string "common_name_en",    :limit => 300, :null => false
    t.string "common_name_fr",    :limit => 300, :null => false
  end

  create_table "info_items", :force => true do |t|
    t.string "label", :null => false
  end

  add_index "info_items", ["label"], :name => "label"

  create_table "languages", :force => true do |t|
    t.string "label", :null => false
  end

  add_index "languages", ["label"], :name => "label"

  create_table "licenses", :force => true do |t|
    t.string "title",                      :null => false
    t.string "description", :limit => 400, :null => false
    t.string "source_url",                 :null => false
    t.float  "version",                    :null => false
    t.string "logo_url",                   :null => false
  end

  add_index "licenses", ["title"], :name => "title"

  create_table "mime_types", :force => true do |t|
    t.string "label", :null => false
  end

  add_index "mime_types", ["label"], :name => "label"

  create_table "references", :force => true do |t|
    t.string "full_reference", :limit => 400, :null => false
    t.string "bici",                          :null => false
    t.string "coden",                         :null => false
    t.string "doi",                           :null => false
    t.string "eissn",          :limit => 100, :null => false
    t.string "handle",                        :null => false
    t.string "isbn",           :limit => 100, :null => false
    t.string "issn",           :limit => 100, :null => false
    t.string "lsid",                          :null => false
    t.string "oclc",                          :null => false
    t.string "sici",                          :null => false
    t.string "url",                           :null => false
    t.string "urn",                           :null => false
  end

  create_table "references_taxa", :id => false, :force => true do |t|
    t.integer "taxa_id",       :limit => 10, :null => false
    t.integer "references_id", :limit => 10, :null => false
  end

  create_table "resources", :force => true do |t|
    t.string    "title",                                 :null => false
    t.string    "accesspoint_url",                       :null => false
    t.string    "metadata_url",                          :null => false
    t.integer   "service_types_id",                      :null => false
    t.string    "service_version",                       :null => false
    t.string    "resource_set_code",                     :null => false
    t.string    "description",            :limit => 400, :null => false
    t.string    "logo_url",                              :null => false
    t.integer   "languages_id",           :limit => 5,   :null => false
    t.string    "subject",                               :null => false
    t.string    "bibliographic_citation", :limit => 400, :null => false
    t.integer   "licenses_id",            :limit => 3,   :null => false
    t.string    "rights_statement",       :limit => 400, :null => false
    t.string    "rights_holder",                         :null => false
    t.integer   "refresh_period_hours",   :limit => 5,   :null => false
    t.timestamp "resource_created_at",                   :null => false
    t.timestamp "resource_modified_at",                  :null => false
    t.timestamp "created_at",                            :null => false
    t.timestamp "harvested_at",                          :null => false
  end

  create_table "service_types", :force => true do |t|
    t.string "label", :null => false
  end

  add_index "service_types", ["label"], :name => "label"

  create_table "table_of_contents", :force => true do |t|
    t.integer "parent_id",  :limit => 5, :null => false
    t.string  "label",                   :null => false
    t.integer "view_order", :limit => 4, :null => false
  end

  add_index "table_of_contents", ["label"], :name => "label"

  create_table "taxa", :force => true do |t|
    t.integer   "resources_id",      :limit => 10, :null => false
    t.string    "identifier",                      :null => false
    t.string    "source_url",                      :null => false
    t.string    "taxon_kingdom",                   :null => false
    t.string    "taxon_phylum",                    :null => false
    t.string    "taxon_class",                     :null => false
    t.string    "taxon_order",                     :null => false
    t.string    "taxon_family",                    :null => false
    t.string    "scientific_name",                 :null => false
    t.integer   "names_id",          :limit => 10, :null => false
    t.timestamp "taxon_created_at",                :null => false
    t.timestamp "taxon_modified_at",               :null => false
    t.timestamp "created_at",                      :null => false
    t.timestamp "updated_at",                      :null => false
  end

  add_index "taxa", ["names_id"], :name => "names_id"

end
