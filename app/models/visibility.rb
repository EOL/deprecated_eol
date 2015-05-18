class Visibility < ActiveRecord::Base
  uses_translations
  has_many :data_objects_hierarchy_entry
  has_many :curated_data_objects_hierarchy_entry
  has_many :users_data_objects

  include Enumerated
  enumerated :label, %w(Invisible Visible Preview)

  def self.create_enumerated
    enumeration_creator defaults: { phonetic_label: nil } # TODO - try removing this method, it may not be needed.
  end

  def self.all_ids
    cached('all_ids') do
      Visibility.all.collect {|v| v.id}
    end
  end

  def self.for_curating_selects
    @@for_curating_selects ||= {}
    return(@@for_curating_selects[I18n.locale]) if @@for_curating_selects[I18n.locale]
    @@for_curating_selects ||= {}
    @@for_curating_selects[I18n.locale] =
      [Visibility.visible, Visibility.invisible].map do |v|
        [v.curation_label, v.id, {class: v.to_action}]
      end.compact.sort
  end
  
  def self.get_visible
    Rails.cache.fetch("visibility/visible", expires_in: 10.days) do
      Visibility.visible
    end
  end
  
  def self.get_invisible
    Rails.cache.fetch("visibility/invisible", expires_in: 10.days) do
      Visibility.invisible
    end    
  end
  
  def self.get_preview
    Rails.cache.fetch("visibility/preview", expires_in: 10.days) do
      Visibility.preview
    end    
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

  def view_order
    case id
    when Visibility.visible.id
      1
    when Visibility.invisible.id
      2
    else
      3
    end
  end

end
