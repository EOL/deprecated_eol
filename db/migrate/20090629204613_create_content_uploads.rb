class CreateContentUploads < ActiveRecord::Migration
  def self.up
    create_table :content_uploads do |t|
      t.string :description, :limit => 100, :commment=>'description of uploaded content'
      t.string :link_name, :limit => 70, :commment=>'used to generate friendly link (via the content controller, file method)'
      t.integer :attachment_cache_url, :limit=>8, :commment=>'the unique identifier for the uploaded content on the content servers'  # this is a BIGINT
      t.string :attachment_extension, :limit=>10, :comment=>'uploaded content file extension'      
      t.string :attachment_content_type, :limit=>255, :comment=>'uploaded content file content type; used by paperclip plugin'
      t.string :attachment_file_name, :limit=>255, :comment=>'uploaded content file name; used by paperclip plugin'
      t.integer :attachment_file_size, :comment=>'uploaded content file content file size; used by paperclip plugin'
      t.integer :user_id, :comment=>'user_id that uploaded file'
      t.timestamps
    end
  end

  def self.down
    drop_table :content_uploads
  end
end
