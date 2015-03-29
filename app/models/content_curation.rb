# This is a class used by Tramea.
#
#   t.integer :content_id
#   t.integer :user_id
#   t.integer :curator_activity_log_id # I wish we didn't care, but...
#   t.string :attribute # NOT meant to be human-readable, but based on ATTRIBUTES.
#   t.string :was
#   t.string :now
#   t.string :reason
#   t.datetime :originally_curated_at # If set, this was inherited during harvest.
#   t.timestamps
# end
# add_index :content_curations, :content_id
# add_index :content_curations, [:curator_activity_log_id, :content_id],
#   name: "cal_content", uniqe: true
# add_index :content_curations, :user_id
class ContentCuration < ActiveRecord::Base
  belongs_to :content
  belongs_to :user
  belongs_to :curator, class: "User" # Sigh. I wish it weren't.
  # ONLY if this curation was denormalized from another:
  belongs_to :original_curation, class: "ContentCuration"

  # Useful scope for looking at what users have actually done. i.e.:
  # user.content_curations.primary
  #
  # RAILS4: this could be where.not(original_curation_id: null)
  scope :primary, -> { where("original_curation_id IS NOT NULL") }

  def self.from_curator_activity_log(curation, content)
    return find_by_content_id_and_curator_activity_log_id(
      content.id, curation.id
    ) if exists?(content_id: content.id, curator_activity_log_id: curation.id)
    create(
      curator_activity_log_id: curation.id
      content_id: content.id,
      user_id: curation.user_id,
      reason: reason_from_curation(curation)
    ).merge(attributes_from_activity(curation.activity)
  end

  def self.attributes_from_activity(activity)
    case activity.id
    when Activity.trusted.id
      { attribute: "trusted", was: "false", now: "true" }
    when Activity.untrusted.id
      { attribute: "untrusted", was: "false", now: "true" }
    when Activity.show.id
      { attribute: "shown", was: "false", now: "true" }
    when Activity.hide.id
      { attribute: "hidden", was: "false", now: "true" }
    when Activity.inappropriate.id
      raise "Attempt to add inappropriate ContentCuration: just delete it"
    when Activity.unreviewed.id
      { attribute: "trusted", was: "true", now: "false" }
    when Activity.add_association.id
      raise "Attempt to add ContentCuration for add_association: just create it"
    when Activity.remove_association.id
      raise "Attempt to add ContentCuration for remove_association: just delete it"
    when Activity.choose_exemplar_image.id
      { attribute: "exemplar", was: "false", now: "true" }
    when Activity.choose_exemplar_article.id
      { attribute: "exemplar", was: "false", now: "true" }
    when Activity.unhide.id
      { attribute: "hidden", was: "true", now: "false" }
    else
      { attribute: "Unknown", was: "Unknown", now: activity.name(Language.default) }
    end
  end

  def self.reason_from_curation(curation)
    reasons = []
    curation.untrust_reasons.each do |reason|
      reasons << reason.label(Language.default) # Yes, we lose translations.
    end
    reasons << comment.body
    reasons.to_sentence
  end

  # Did this curation happen on THIS very content association, or was this
  # inherited (denormalized) from another curation event?
  def inherited?
    original_curation_id
  end

  def inherited_from_harvest?
    originally_curated_at
  end
end
