class Visibility < ActiveRecord::Base
  uses_translations
  has_many :data_objects_hierarchy_entry
  has_many :curated_data_objects_hierarchy_entry
  has_many :users_data_objects

  def self.all_ids
    cached('all_ids') do
      Visibility.all.collect {|v| v.id}
    end
  end

  def self.visible
    cached_find_translated(:label, 'Visible')
  end

  def self.preview
    cached_find_translated(:label, 'Preview')
  end
  
  def self.invisible
    cached_find_translated(:label, 'Invisible')
  end

  def self.for_curating_selects
    @@for_curating_selects ||= {}
    return(@@for_curating_selects[I18n.locale]) if @@for_curating_selects[I18n.locale]
    @@for_curating_selects ||= {}
    @@for_curating_selects[I18n.locale] =
      [Visibility.visible, Visibility.invisible].map {|v| [v.curation_label, v.id] }.compact.sort
  end

  def curation_label
    self.id == Visibility.invisible.id ? I18n.t(:hidden) : self.label
  end

  def to_action
    case id
    when Visibility.visible.id
      'show'
    when Visibility.invisible.id
      'hide'
    else
      nil
    end
  end

end
