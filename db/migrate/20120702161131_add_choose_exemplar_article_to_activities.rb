class AddChooseExemplarArticleToActivities < ActiveRecord::Migration
  def self.up
    choose_exemplar_image_activity = TranslatedActivity.find_by_language_id_and_name(Language.english.id, 'choose_exemplar') rescue nil
    unless choose_exemplar_image_activity.nil?
      choose_exemplar_image_activity.name = 'choose_exemplar_image'
      choose_exemplar_image_activity.save
    end
    Activity.find_or_create('choose_exemplar_article')
  end

  def self.down
    choose_exemplar_image_activity = TranslatedActivity.find_by_language_id_and_name(Language.english.id, 'choose_exemplar_image') rescue nil
    unless choose_exemplar_image_activity.nil?
      choose_exemplar_image_activity.name = 'choose_exemplar'
      choose_exemplar_image_activity.save
    end
    Activity.destroy('choose_exemplar_article')
  end
end
