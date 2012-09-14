class ClassificationCuration < ActiveRecord::Base

  # For convenience, these are the non-relationship fields:
  # :created_at   => When the curator made the request
  # :completed_at => When it was finished PROCESSING. This does NOT mean it worked! (Check #failed? for that.)
  # :forced       => boolean. ...Whether the move was (had to be) forced due to conflicts in CP assertions.
  # :error        => merges don't have hierarchy_entry_moves, so the errors cannot be stored there. Here it is!

  has_many :hierarchy_entries, :through => 'hiearchy_entry_moves'
  has_many :hierarchy_entry_moves

  belongs_to :exemplar, :class_name => 'HierarchyEntry' # If this is null, it was a merge.
  belongs_to :source, :class_name => 'TaxonConcept' # If this has a superceded_id after the operation, it was a merge.
  belongs_to :target, :class_name => 'TaxonConcept' # If this is null, it's a split.
  belongs_to :user # This is the curator that requested the move/merge/split.

  after_create :bridge

  def bridge
    if split?
      bridge_split
    elsif merge?
      bridge_merge
    else
      bridge_move
    end
  end

  def split?
    target.null?
  end

  def merge?
    exemplar.null?
  end

  # This is not used anywhere, but is here for principle of least surprise:
  def move?
    !split? && !merge?
  end

  def bridge_split
    hierarchy_entries.each do |he|
      CodeBridge.split_entry(:hierarchy_entry_id => he.id, :exemplar_id => exemplar.id, :notify => user_id,
                             :classification_curation => self)
    end
  end

  def bridge_merge
    CodeBridge.merge_taxa(source_id, target_id, :notify => user_id, :classification_curation => self)
  end

  def bridge_move
    hierarchy_entries.each do |he|
      CodeBridge.move_entry(:from_taxon_concept_id => source_id, :to_taxon_concept_id => target_id,
                            :hierarchy_entry_id => he.id, :exemplar_id => exemplar.id, :notify => user_id,
                            :classification_curation => self)
    end
  end

  def check_status_and_notify
    if complete?
      update_column(:completed_at, Time.now) if complete?
      if failed?
        compile_errors_into_log
      else
        leave_logs_and_notify(Activity.unlock)
      end
      CodeBridge.reindex(source_id) if source_id
      CodeBridge.reindex(target_id) if target_id
    end
  end

  def complete?
    return completed_at if completed_at
    hierarchy_entry_moves.all? {|move| move.complete?}
  end

  def failed?
    error || hierarchy_entry_moves.any? {|move| move.error}
  end

  def compile_errors_into_log
    # Yes, english. This is a comment and cannot be internationalized:
    comment = "The following error(s) occured during the curation of classifications: "
    comment += ([error] +
                hierarchy_entry_moves.with_errors.map do |m|
                  "\"#{m.error}\" on <a href='#{taxon_hierarchy_entry_overview_url(source, m.hierarchy_entry)}'>#{m.hierarchy_entry.italicized_name}</a>."
                end
               ).join(", ")
    leave_logs_and_notify(Activity.unlock_with_error, :comment => comment)
  end


  # The ugliness of this method is born of the need (or desire) to create only ONE notification (but to leave two
  # logs if required).
  def leave_logs_and_notify(activity, options = {})
    activity_log = nil
    if source_id
      activity_log = leave_log_on_taxon(source, activity, options)
    end
    if target_id
      t_activity_log = leave_log_on_taxon(target, activity, options)
      activity_log ||= t_activity_log
    end
    force_immediate_notification_of(activity_log)
  end

  def leave_log_on_taxon(parent, activity, options = {})
    if options[:comment]
      Comment.create!(:user_id => $BACKGROUND_TASK_USER_ID, :body => options[:comment], :parent => parent)
    end
    CuratorActivityLog.create!(:user_id => user_id,
                               :changeable_object_type_id => ChangeableObjectType.classification_curation.id,
                               :object_id => id,
                               :activity_id => activity.id,
                               :created_at => 0.seconds.from_now,
                               :taxon_concept_id => parent.id)
  end

  def force_immediate_notification_of(target)
    PendingNotification.create!(:user_id => user_id,
                                :notification_frequency_id => NotificationFrequency.immediately.id,
                                :target => target,
                                :reason => 'auto_email_after_curation')
    Resque.enqueue(PrepareAndSendNotifications)
  end

end
