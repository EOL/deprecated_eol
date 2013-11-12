class IncreaseIsoFieldLengths < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `languages` MODIFY `iso_639_1` varchar(12) NOT NULL, " +
      "MODIFY `iso_639_2` varchar(12) NOT NULL, " +
      "MODIFY `iso_639_3` varchar(12) NOT NULL"
    Language.create_english # Ensure that we have our default language before inserting any...
    next_sort_order =
      Language.connection.execute("SELECT MAX(sort_order) so FROM languages").first.first.to_i
    unless Language.exists?(:iso_639_1 => 'zh-CN')
      hans = Language.create(:iso_639_1 => 'zh-CN', :iso_639_2 => 'zh-CN', :iso_639_3 => 'zh-CN',
                             :source_form => 'Chinese simplified, China', :sort_order => next_sort_order)
      TranslatedLanguage.create(:label => 'Chinese simplified, China', :original_language_id => hans.id,
                                :language => Language.english_for_migrations)
    end
    unless Language.exists?(:iso_639_1 => 'zh-Hans')
      hans = Language.create(:iso_639_1 => 'zh-Hans', :iso_639_2 => 'zh-Hans', :iso_639_3 => 'zh-Hans',
                             :source_form => 'simplified Chinese', :sort_order => next_sort_order)
      TranslatedLanguage.create(:label => 'simplified Chinese', :original_language_id => hans.id,
                                :language => Language.english_for_migrations)
    end
  end

  def self.down
    execute "ALTER TABLE `languages` MODIFY `iso_639_1` varchar(6) NOT NULL, " +
      "MODIFY `iso_639_2` varchar(6) NOT NULL, " +
      "MODIFY `iso_639_3` varchar(6) NOT NULL"
  end
end
