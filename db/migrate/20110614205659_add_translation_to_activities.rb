class AddTranslationToActivities < EOL::LoggingMigration
  def self.up
    execute("CREATE TABLE `translated_activities` (
      `id` int NOT NULL auto_increment,
      `activity_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `name` varchar(255) NOT NULL,
      PRIMARY KEY (`id`),
      UNIQUE (`activity_id`, `language_id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8")
    if english = Language.english
      Activity.all.each do |a|
        TranslatedActivity.create(:activity_id => a.id, :language_id => english.id, :name => a.name) unless a.name.blank?
      end
    end
    remove_column :activities, :name
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("Activities table was translated, not worth reversing.")
  end
end
