class Vetted < ActiveRecord::Base
  self.table_name = "vetted"
  uses_translations
  has_many :taxon_concepts
  has_many :hierarchy_entries
  has_many :data_objects_hierarchy_entries
  has_many :curated_data_objects_hierarchy_entries
  has_many :users_data_objects

  def self.inappropriate
    cached_find_translated(:label, 'Inappropriate')
  end

  def self.untrusted
    cached_find_translated(:label, 'Untrusted')
  end

  def self.trusted
    cached_find_translated(:label, 'Trusted')
  end

  def self.unknown
    cached_find_translated(:label, 'Unknown')
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
      [Vetted.trusted, Vetted.unknown, Vetted.untrusted].map {|v| [v.curation_label, v.id] }.compact.sort
  end

  def curation_label
    self.id == Vetted.unknown.id ? I18n.t(:unreviewed) : self.label
  end

  def sort_weight
    weights = vetted_weight
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

  # curate an object, without the curating code needing to know anything about the methods used to do so.
  def apply_to(object, user)
    case id
    when Vetted.untrusted.id
      object.untrust(user)
    when Vetted.trusted.id
      object.trust(user)
    when Vetted.unknown.id
      object.unreviewed(user)
    end
  end

private

  # TODO - this should be in the DB.
  def vetted_weight
    @@vetted_weight = {Vetted.trusted.id => 1, Vetted.unknown.id => 2, Vetted.untrusted.id => 3, Vetted.inappropriate.id => 4} if
      Rails.env.test?
    @@vetted_weight ||= {Vetted.trusted.id => 1, Vetted.unknown.id => 2, Vetted.untrusted.id => 3, Vetted.inappropriate.id => 4}
  end

end
