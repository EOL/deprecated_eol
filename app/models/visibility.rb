class Visibility < ActiveRecord::Base
  uses_translations
  has_many :data_objects_hierarchy_entry
  has_many :curated_data_objects_hierarchy_entry
  has_many :users_data_objects

  def self.create_defaults
    %w(Invisible Visible Preview).each do |lbl|
      vis = Visibility.create
      trans = TranslatedVisibility.create(visibility_id: vis.id,
                                          language_id: Language.default.id,
                                          label: lbl,
                                          phonetic_label: nil)
    end
  end

  def self.all_ids
    cached('all_ids') do
      Visibility.all.collect {|v| v.id}
    end
  end

  def self.visible
    @@visible ||= cached_find_translated(:label, 'Visible')
  end

  def self.preview
    @@preview ||= cached_find_translated(:label, 'Preview')
  end
  
  def self.invisible
    @@invisible ||= cached_find_translated(:label, 'Invisible')
  end

  def self.for_curating_selects
    @@for_curating_selects ||= {}
    return(@@for_curating_selects[I18n.locale]) if @@for_curating_selects[I18n.locale]
    @@for_curating_selects ||= {}
    @@for_curating_selects[I18n.locale] =
      [Visibility.visible, Visibility.invisible].map do |v|
        [v.curation_label, v.id, {:class => v.to_action}]
      end.compact.sort
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

  def can_apply?
    [Visibility.visible.id, Visibility.invisible.id].include? id
  end

  def apply_to(object, user)
    raise 'invalid visibility type' unless can_apply?
    case id
    when Visibility.visible.id
      object.show(user)
    when Visibility.invisible.id
      object.hide(user)
    else
      nil
    end
  end

end
