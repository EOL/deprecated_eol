class InternationalizeMainTables < ActiveRecord::Migration
  def self.up
    english = Language.english
    # we need to use SQL to get some numeric types we want (smallint)
    
    # === ActionWithObject
    execute("CREATE TABLE `translated_action_with_objects` (
      `id` int NOT NULL auto_increment,
      `action_with_object_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `action_code` varchar(255) NOT NULL,
      `phonetic_action_code` varchar(255) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`action_with_object_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      ActionWithObject.all.each do |r|
        TranslatedActionWithObject.create(:action_with_object_id => r.id, :language_id => english.id, :action_code => r.action_code)
      end
    end
    remove_column :action_with_objects, :action_code
    
    
    # === ContactSubject
    execute("CREATE TABLE `translated_contact_subjects` (
      `id` int NOT NULL auto_increment,
      `contact_subject_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `title` varchar(255) NOT NULL,
      `phonetic_action_code` varchar(255) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`contact_subject_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      ContactSubject.all.each do |r|
        TranslatedContactSubject.create(:contact_subject_id => r.id, :language_id => english.id, :title => r.title)
      end
    end
    remove_column :contact_subjects, :title
    
    
    # === NewsItem
    execute("CREATE TABLE `translated_news_items` (
      `id` int NOT NULL auto_increment,
      `news_item_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `body` varchar(1500) NOT NULL,
      `phonetic_body` varchar(1500) default NULL,
      `title` varchar(255) default '',
      `phonetic_title` varchar(255) default NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`news_item_id`, `language_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
    if english
      NewsItem.all.each do |r|
        TranslatedNewsItem.create(:news_item_id => r.id, :language_id => english.id, :title => r.title, :body => r.body)
      end
    end
    remove_column :news_items, :body
    remove_column :news_items, :title
  end

  def self.down
    english = Language.english
    
    # === ActionWithObject
    execute('ALTER TABLE `action_with_objects` ADD `action_code` varchar(255) NOT NULL AFTER `id`')
    if english
      TranslatedActionWithObject.find_all_by_language_id(english.id).each do |r|
        old_r = ActionWithObject.find(r.action_with_object_id)
        old_r.action_code = r.action_code
        old_r.save
      end
    end
    drop_table :translated_action_with_objects
    
    
    # === ContactSubject
    execute('ALTER TABLE `contact_subjects` ADD `title` varchar(255) NOT NULL AFTER `id`')
    if english
      TranslatedContactSubject.find_all_by_language_id(english.id).each do |r|
        old_r = ContactSubject.find(r.contact_subject_id)
        old_r.title = r.title
        old_r.save
      end
    end
    drop_table :translated_contact_subjects
    
    
    # === NewsItem
    execute('ALTER TABLE `news_items` ADD `body` varchar(1500) NOT NULL AFTER `id`')
    execute('ALTER TABLE `news_items` ADD `title` varchar(255) default \'\' AFTER `body`')
    if english
      TranslatedNewsItem.find_all_by_language_id(english.id).each do |r|
        old_r = NewsItem.find(r.news_item_id)
        old_r.body = r.body
        old_r.title = r.title
        old_r.save
      end
    end
    drop_table :translated_news_items
  end
end
