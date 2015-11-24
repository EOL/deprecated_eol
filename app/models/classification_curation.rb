# provides the ability to bridge ClassificationCurations to PHP
class ClassificurationBridge

  attr_accessor :curation
  attr_reader   :bridger

  delegate :bridge, to: :bridger

  def self.bridge(curation)
    c = ClassificurationBridge.new(curation)
    c.bridge
    c
  end

  def initialize(curation)
    @curation = curation
    @bridger  = BridgeFactory.for(curation)
  end

end

# Builds the correct strategy for bridging classification curations to PHP
class BridgeFactory
  def self.for(curation)
    if curation.split?
      BridgeSplit.new(curation)
    elsif curation.merge?
      BridgeMerge.new(curation)
    elsif curation.move?
      BridgeMove.new(curation)
    end
  end
end

# Classic Stratgey Pattern for bridging classification curations to PHP
class Bridge

  attr_accessor :curation

  def initialize(curation)
    @curation = curation
  end

  def bridge
    raise "Unimplemented abstract method called"
  end

end

class BridgeSplit < Bridge
  def bridge
    curation.hierarchy_entries.each do |he|
      CodeBridge.split_entry(hierarchy_entry_id: he.id, exemplar_id: curation.exemplar_id,
                             notify: curation.user_id, classification_curation_id: curation.id)
    end
  end
end

class BridgeMerge < Bridge
  def bridge
    # TODO: This is no longer needed! Yay!  We just need to background this...
    CodeBridge.merge_taxa(curation.source_id, curation.target_id, notify: curation.user_id,
                          classification_curation_id: curation.id)
  end
end

class BridgeMove < Bridge
  def bridge
    curation.hierarchy_entries.each do |he|
      CodeBridge.move_entry(from_taxon_concept_id: curation.source_id, to_taxon_concept_id: curation.target_id,
                            hierarchy_entry_id: he.id, exemplar_id: curation.exemplar_id,
                            notify: curation.user_id, classification_curation_id: curation.id)
    end
  end
end

class ClassificationCuration < ActiveRecord::Base

  # For convenience, these are the non-relationship fields:
  # completed_at: When it was finished PROCESSING. This does NOT mean it worked! (Check #failed? for that.)
  # :forced       => boolean. ...Whether the move was (had to be) forced due to conflicts in CP assertions.
  # :error        => merges don't have hierarchy_entry_moves, so the errors cannot be stored there. Here it is!

  has_many :hierarchy_entry_moves
  has_many :hierarchy_entries, through: :hierarchy_entry_moves

  # If this is null, it was a merge:
  belongs_to :exemplar, class_name: 'HierarchyEntry', foreign_key: 'exemplar_id'
  # If this has a superceded_id after the operation, it was a merge:
  belongs_to :moved_from, class_name: 'TaxonConcept', foreign_key: 'source_id'
  # If this is null, it's a split:
  belongs_to :moved_to, class_name: 'TaxonConcept', foreign_key: 'target_id'
  # This is the curator that requested the move/merge/split:
  belongs_to :user

  after_create :bridge

  def bridge
    ClassificurationBridge.bridge(self)
  end

  def split?
    moved_to.nil?
  end

  def merge?
    exemplar.nil?
  end

  def move?
    moved_to && exemplar
  end

  def check_status_and_notify
    if ready_to_complete? && ! already_complete?
      mark_as_complete # Nothing else should pick this up for work, now...
      if failed?
        compile_errors_into_log
      else
        reindex_taxa
        log_completion
      end
    end
  end

  def reindex_taxa
    # Allowing large trees, here, since you shouldn't have gotten here unless it was okay.
    TaxonConceptReindexing.reindex(moved_from, allow_large_tree: true) if source_id
    if target_id
      TaxonConceptReindexing.reindex(moved_to, allow_large_tree: true)
    elsif hierarchy_entry_moves
      taxon_concepts = hierarchy_entry_moves.collect{ |m| m.hierarchy_entry.taxon_concept }.compact.uniq
      taxon_concepts.each do |taxon_concept|
        TaxonConceptReindexing.reindex(taxon_concept, allow_large_tree: true)
      end
    end
  end

  def log_completion
    log_activity_on(moved_from || moved_to)
    log_unlock_and_notify(Activity.unlock)
  end

  def already_complete?
    completed_at && hierarchy_entry_moves.all? {|move| move.complete?}
  end

  def ready_to_complete?
    if merge?
      # This is slightly expensive... but not THAT bad... and running in the background. The "magic" is NOT using the
      # direct association, but using #find, so that supercedure is followed.
      TaxonConcept.find(moved_from) == TaxonConcept.find(moved_to)
    else
      hierarchy_entry_moves.all? {|move| move.complete?}
    end
  end

  def failed?
    !(error.blank? && hierarchy_entry_moves.all? {|move| move.error.blank? })
  end

  def to_s
    "ClassificationCuration ##{self.id} (moved_from #{source_id}, moved_to #{target_id})"
  end

  # A split doesn't specify a target (it creates one), so we look to see where it went (for logging):
  def split_to
    hierarchy_entry_moves.first.hierarchy_entry.taxon_concept
  end

private

  def compile_errors_into_log
    # Yes, english. This is a comment and cannot be internationalized:
    comment = "The following error(s) occured during the curation of classifications: "
    comment += ([error] +
                hierarchy_entry_moves.with_errors.map do |m|
                  "\"#{m.error}\" on the classification from #{m.hierarchy_entry.hierarchy.display_title}"
                end
               ).to_sentence
    log_unlock_and_notify(Activity.unlock_with_error, comment: comment)
  end


  # The ugliness of this method is born of the need (or desire) to create only ONE notification (but to leave two
  # logs if required).
  def log_unlock_and_notify(activity, options = {})
    activity_log = nil
    if moved_from
      activity_log = leave_log_on_taxon(moved_from, activity, options)
    end
    if moved_to && activity_log.nil?
      activity_log = leave_log_on_taxon(moved_to, activity, options)
    end
    if activity_log
      force_immediate_notification_of(activity_log)
    else
      logger.error "** ERROR: #{self} not reported; no activity log was created."
    end
  end

  def leave_log_on_taxon(parent, activity, options = {})
    comment = nil
    log = nil
    begin
      if options[:comment]
        comment = Comment.create!(user_id: $BACKGROUND_TASK_USER_ID, body: options[:comment], parent: parent)
      end
      log = CuratorActivityLog.create!(user_id: user_id,
                                       changeable_object_type_id: comment ?
                                          ChangeableObjectType.comment.id :
                                          ChangeableObjectType.classification_curation.id,
                                       target_id: options[:comment] ? comment.id : id,
                                       activity: activity,
                                       taxon_concept_id: parent.id)
    rescue => e
      logger.error "** ERROR: Could not create CuratorActivityLog for #{self}: #{e.message}"
    end
    log
  end

  def force_immediate_notification_of(moved_to)
    PendingNotification.create!(user_id: user_id,
                                notification_frequency_id: NotificationFrequency.immediately.id,
                                target: moved_to,
                                reason: 'auto_email_after_curation')
    Resque.enqueue(PrepareAndSendNotifications)
  rescue => e
    # Do nothing (for now)...
  end

  def log_activity_on(taxon_concept)
    CuratorActivityLog.create(
      user: user,
      taxon_concept: taxon_concept,
      changeable_object_type: ChangeableObjectType.classification_curation,
      target_id: id,
      activity: Activity.curate_classifications
    )
  end

  # This method makes sure we don't process a ClassificationCuration twice, and makes sure that classifications don't
  # show up as "pending curation" on the names tab anymore.
  def mark_as_complete
    hierarchy_entry_moves.each do |move|
      move.update_column(:completed_at, Time.now)
    end
    update_column(:completed_at, Time.now)
  end

end
