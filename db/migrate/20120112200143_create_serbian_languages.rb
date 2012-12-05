# encoding: utf-8
class CreateSerbianLanguages < ActiveRecord::Migration
  def self.up
    Language.reset_column_information
    serbian_cyrillic = Language.create(:iso_639_1 => 'sr-EC', :iso_639_2 => '', :iso_639_3 => '',
      :source_form => 'српски', :sort_order => 1, :activated_on => Time.now)
    TranslatedLanguage.create(:original_language => serbian_cyrillic, :language => Language.english_for_migrations, :label => 'Serbian (Cyrillic)')
    
    serbian_latin = Language.create(:iso_639_1 => 'sr-el', :iso_639_2 => '', :iso_639_3 => '',
      :source_form => 'srpski', :sort_order => 1, :activated_on => Time.now)
    TranslatedLanguage.create(:original_language => serbian_latin, :language => Language.english_for_migrations, :label => 'Serbian (Latin)')
  end

  def self.down
    serbian_cyrillic = Language.find_by_iso_639_1('sr-EC')
    serbian_cyrillic.translations.each{ |tr| tr.destroy }
    serbian_cyrillic.destroy
    
    serbian_latin = Language.find_by_iso_639_1('sr-el')
    serbian_latin.translations.each{ |tr| tr.destroy }
    serbian_latin.destroy
  end
end
