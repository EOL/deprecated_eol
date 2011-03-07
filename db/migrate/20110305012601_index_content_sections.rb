class IndexContentSections < ActiveRecord::Migration
  def self.up
    execute('CREATE INDEX `section_active` ON `content_pages`(`content_section_id`, `active`)')
  end

  def self.down
    remove_index :content_pages, :name => 'section_active'
  end
end
