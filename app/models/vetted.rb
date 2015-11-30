class Vetted < ActiveRecord::Base

  self.table_name = "vetted"
  uses_translations
  has_many :taxon_concepts
  has_many :hierarchy_entries
  has_many :data_objects_hierarchy_entries
  has_many :curated_data_objects_hierarchy_entries
  has_many :users_data_objects

  include Enumerated
  enumerated :label, %w(Trusted Unknown Untrusted Inappropriate)

  def self.create_enumerated
    enumeration_creator defaults: { phonetic_label: nil }, autoinc: :view_order
  end

  def self.trusted_ids
    self.trusted.id.to_s
  end

  def self.untrusted_ids
    [self.untrusted.id,self.unknown.id].join(',')
  end

  def self.for_curating_selects
    @@for_curating_selects ||= {}
    return(@@for_curating_selects[I18n.locale]) if @@for_curating_selects[I18n.locale]
    @@for_curating_selects ||= {}
    @@for_curating_selects[I18n.locale] =
      [Vetted.trusted, Vetted.unknown, Vetted.untrusted].map do |v|
        [v.curation_label, v.id, { class: v.to_action }]
      end.compact.sort
  end

  def self.weight
    @@weight ||= { Vetted.trusted.id => 1, Vetted.unknown.id => 2,
      Vetted.untrusted.id => 3, Vetted.inappropriate.id => 4 }
  end

  def curation_label
    self.id == Vetted.unknown.id ? I18n.t(:unreviewed) : self.label
  end

  def sort_weight
    weights = Vetted.weight
    return weights.has_key?(id) ? weights[id] : 4
  end

  def to_action
    case id
    when Vetted.inappropriate.id
      'inappropriate'
    when Vetted.unknown.id
      'unreviewed'
    when Vetted.untrusted.id
      'untrusted'
    when Vetted.trusted.id
      'trusted'
    else
      nil
    end
  end

  def can_apply?
    [Vetted.trusted.id, Vetted.untrusted.id, Vetted.unknown.id].include? id
  end

  # curate an object, without the curating code needing to know anything about the methods used to do so.
  def apply_to(object, user)
    raise 'invalid vetted type' unless can_apply?
    case id
    when Vetted.untrusted.id
      object.untrust(user)
    when Vetted.trusted.id
      object.trust(user)
    when Vetted.unknown.id
      object.unreviewed(user)
    end
  end

end
