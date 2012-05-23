class IncreaseIsoFieldLengths < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `languages` MODIFY `iso_639_1` varchar(12) NOT NULL, " +
      "MODIFY `iso_639_2` varchar(12) NOT NULL, " +
      "MODIFY `iso_639_3` varchar(12) NOT NULL"
    next_sort_order =
      Language.connection.execute("SELECT MAX(sort_order) so FROM languages").all_hashes.first["so"].to_i
    unless Language.exists?(:iso_639_1 => 'zh-Hans')
      hans = Language.create(:iso_639_1 => 'zh-Hans', :iso_639_2 => 'zh-Hans', :iso_639_3 => 'zh-Hans',
                             :source_form => 'simplified Chinese', :sort_order => next_sort_order)
      TranslatedLanguage.create(:label => 'simplified Chinese', :original_language_id => hans.id,
                                :language_id => hans.id)
    end
  end

  def self.down
    execute "ALTER TABLE `languages` MODIFY `iso_639_1` varchar(6) NOT NULL, " +
      "MODIFY `iso_639_2` varchar(6) NOT NULL, " +
      "MODIFY `iso_639_3` varchar(6) NOT NULL"
  end
end
