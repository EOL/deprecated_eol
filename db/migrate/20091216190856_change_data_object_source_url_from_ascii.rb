class ChangeDataObjectSourceUrlFromAscii < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    # need to make all these fields the default encoding to handle russian characters: utf8
    execute("ALTER TABLE data_objects MODIFY `source_url` varchar(255) NOT NULL COMMENT 'a url where users are to be redirected to learn more about this data object'")
    execute("ALTER TABLE data_objects MODIFY `object_url` varchar(255) NOT NULL COMMENT 'recommended; the url which resolves to this data object. Generally used only for images, video, and other multimedia'")
    
    execute("ALTER TABLE data_objects_taxa MODIFY `identifier` varchar(255) NOT NULL")
    
    execute("ALTER TABLE resources_taxa MODIFY `source_url` varchar(255) NOT NULL")
    execute("ALTER TABLE resources_taxa MODIFY `identifier` varchar(255) NOT NULL")
    
    execute("ALTER TABLE hierarchy_entries MODIFY `identifier` varchar(255) NOT NULL COMMENT 'recommended; a unique id from the provider for this node'")
  end
  
  def self.down
    # chaning them back to ascii
    execute("ALTER TABLE data_objects MODIFY `source_url` varchar(255) character set ascii NOT NULL COMMENT 'a url where users are to be redirected to learn more about this data object'")
    execute("ALTER TABLE data_objects MODIFY `object_url` varchar(255) character set ascii NOT NULL COMMENT 'recommended; the url which resolves to this data object. Generally used only for images, video, and other multimedia'")
    
    execute("ALTER TABLE data_objects_taxa MODIFY `identifier` varchar(255) character set ascii NOT NULL")
    
    execute("ALTER TABLE resources_taxa MODIFY `source_url` varchar(255) character set ascii NOT NULL")
    execute("ALTER TABLE resources_taxa MODIFY `identifier` varchar(255) character set ascii NOT NULL")
    
    execute("ALTER TABLE hierarchy_entries MODIFY `identifier` varchar(255) character set ascii NOT NULL COMMENT 'recommended; a unique id from the provider for this node'")
  end
end
