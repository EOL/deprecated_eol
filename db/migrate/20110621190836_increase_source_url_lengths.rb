class IncreaseSourceUrlLengths < ActiveRecord::Migration
  def self.up
    
    execute("ALTER TABLE data_objects MODIFY `source_url` TEXT DEFAULT NULL COMMENT 'a url where users are to be redirected to learn more about this data object'")
    execute("ALTER TABLE data_objects MODIFY `object_url` TEXT DEFAULT NULL COMMENT 'recommended; the url which resolves to this data object. Generally used only for images, video, and other multimedia'")
    execute("ALTER TABLE hierarchy_entries MODIFY `source_url` TEXT DEFAULT NULL")
  end

  def self.down
    execute("ALTER TABLE data_objects MODIFY `source_url` varchar(255) NOT NULL COMMENT 'a url where users are to be redirected to learn more about this data object'")
    execute("ALTER TABLE data_objects MODIFY `object_url` varchar(255) NOT NULL COMMENT 'recommended; the url which resolves to this data object. Generally used only for images, video, and other multimedia'")
    execute("ALTER TABLE hierarchy_entries MODIFY `source_url` varchar(255) NOT NULL")
  end
end
