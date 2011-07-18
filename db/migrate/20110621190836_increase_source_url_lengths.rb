class IncreaseSourceUrlLengths < ActiveRecord::Migration
  def self.up
    
    begin
      execute("DROP INDEX object_url ON data_objects")
    rescue
      # this index for whatever reason may not exist, and that's OK because we're getting rid of it
    end
    execute("ALTER TABLE data_objects MODIFY `source_url` TEXT DEFAULT NULL COMMENT 'a url where users are to be redirected to learn more about this data object',
      MODIFY `object_url` TEXT DEFAULT NULL COMMENT 'recommended; the url which resolves to this data object. Generally used only for images, video, and other multimedia'")
    execute("CREATE INDEX object_url ON data_objects(object_url(255))")
    execute("ALTER TABLE hierarchy_entries MODIFY `source_url` TEXT DEFAULT NULL")
  end

  def self.down
    execute("ALTER TABLE data_objects MODIFY `source_url` varchar(255) NOT NULL COMMENT 'a url where users are to be redirected to learn more about this data object',
    MODIFY `object_url` varchar(255) NOT NULL COMMENT 'recommended; the url which resolves to this data object. Generally used only for images, video, and other multimedia'")
    execute("ALTER TABLE hierarchy_entries MODIFY `source_url` varchar(255) NOT NULL")
  end
end
