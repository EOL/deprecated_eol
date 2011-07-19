class InternationalizePrivileges < ActiveRecord::Migration
  def self.up
    english = Language.english_for_migrations
    execute("CREATE TABLE `translated_privileges` (
      `id` int NOT NULL auto_increment,
      `privilege_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `name` varchar(300) NOT NULL,
      `phonetic_name` varchar(300) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`privilege_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      Privilege.all.each do |r|
        TranslatedPrivilege.create(:privilege_id => r.id, :language_id => english.id, :name => r.name) unless
          r.name.blank?
      end
    end
    remove_column :privileges, :name
    remove_column :privileges, :sym
  end

  def self.down
    english = Language.english_for_migrations
    execute('ALTER TABLE `privileges` ADD `name` varchar(255) default "" AFTER `id`') rescue nil
    execute('ALTER TABLE `privileges` ADD `sym` varchar(255) default "" AFTER `id`') rescue nil
    begin
      if english
        TranslatedPrivilege.find_all_by_language_id(english.id).each do |r|
          old_r = Privilege.find(r.privilege_id)
          old_r.name = r.name
          old_r.save
        end
      end
    rescue
      # no nothing, nothing to change here
    end
    add_index :privileges, :name, :name => 'name' rescue nil
    drop_table :translated_privileges rescue nil
  end
end
