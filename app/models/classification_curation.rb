class ClassificationCuration < ActiveRecord::Base

  # For convenience, these are the non-relationship fields:
  # :created_at   => When the curator made the request
  # :completed_at => When it was finished PROCESSING. This does NOT mean it worked! (Check #failed? for that.)
  # :forced       => boolean. ...Whether the move was (had to be) forced due to conflicts in CP assertions.
  # :error        => merges don't have hierarchy_entry_moves, so the errors cannot be stored there. Here it is!

  has_many :hierarchy_entry_moves
  has_many :hierarchy_entries, :through => :hierarchy_entry_moves

  # If this is null, it was a merge:
  belongs_to :exemplar, :class_name => 'HierarchyEntry', :foreign_key => 'exemplar_id'
  # If this has a superceded_id after the operation, it was a merge:
  belongs_to :moved_from, :class_name => 'TaxonConcept', :foreign_key => 'source_id'
  # If this is null, it's a split:
  belongs_to :moved_to, :class_name => 'TaxonConcept', :foreign_key => 'target_id'
  # This is the curator that requested the move/merge/split:
  belongs_to :user

  after_create :bridge

  def moved_to
    self[:target_id].nil? ? nil : TaxonConcept.find(self[:target_id])
  end

  def bridge
    if split?
      bridge_split
    elsif merge?
      bridge_merge
    else
      bridge_move
    end
    log_activity_on(moved_from) if moved_from
    log_activity_on(moved_to) if moved_to
  end

  def split?
    moved_to.nil?
  end

  def merge?
    exemplar.nil?
  end

  # This is not used anywhere (in practice, use split? / merge? / else), but is here for principle of least surprise:
  def move?
    !split? && !merge?
  end

  def bridge_split
    hierarchy_entries.each do |he|
      CodeBridge.split_entry(:hierarchy_entry_id => he.id, :exemplar_id => exemplar_id, :notify => user_id,
                             :classification_curation_id => id)
    end
  end

  def bridge_merge
    CodeBridge.merge_taxa(source_id, target_id, :notify => user_id, :classification_curation_id => id)
  end

  def bridge_move
    hierarchy_entries.each do |he|
      CodeBridge.move_entry(:from_taxon_concept_id => source_id, :to_taxon_concept_id => target_id,
                            :hierarchy_entry_id => he.id, :exemplar_id => exemplar_id, :notify => user_id,
                            :classification_curation_id => id)
    end
  end

  def check_status_and_notify
    if ready_to_complete? && ! already_complete?
      if failed?
        compile_errors_into_log
      else
        leave_logs_and_notify(Activity.unlock)
      end
      CodeBridge.reindex_taxon_concept(source_id) if source_id
      CodeBridge.reindex_taxon_concept(target_id) if target_id
      mark_as_complete
    end
  end

  def already_complete?
    return completed_at
  end

  def ready_to_complete?
    if merge?
      moved_from == moved_to # This is slightly expensive... but not THAT bad... and running in the background.
    else
      hierarchy_entry_moves.all? {|move| move.complete?}
    end
  end
  alias :complete? :ready_to_complete? # Try not to use this one, though... it's confusing.

  def failed?
    !(error.blank? && hierarchy_entry_moves.all? {|move| move.error.blank? })
  end

  def compile_errors_into_log
    # Yes, english. This is a comment and cannot be internationalized:
    comment = "The following error(s) occured during the curation of classifications: "
    comment += ([error] +
                hierarchy_entry_moves.with_errors.map do |m|
                  "\"#{m.error}\" on the classification from #{m.hierarchy_entry.hierarchy.display_title}"
                end
               ).to_sentence
    leave_logs_and_notify(Activity.unlock_with_error, :comment => comment)
  end


  # The ugliness of this method is born of the need (or desire) to create only ONE notification (but to leave two
  # logs if required).
  def leave_logs_and_notify(activity, options = {})
    activity_log = nil
    if moved_from
      activity_log = leave_log_on_taxon(moved_from, activity, options)
    end
    if moved_to && activity_log.nil?
      activity_log = leave_log_on_taxon(moved_to, activity, options)
    end
    if split?
      # ...What I want to do here is to comment on the source taxon about the target (new) taxon... but the problem
      # is that we don't have linking ability in models (which, IMO, is lame)... so, in the meantime, I'm leaving a
      # LAME comment (I really don't want to do URL generation like this) :
      Comment.create!(:user_id => user_id,
                      :parent => moved_from,
                      :body => I18n.t(:classification_curation_split_comment_with_count,
                                      :count => hierarchy_entry_moves.count,
                                      :url => "http://#{$SITE_DOMAIN_OR_IP}/pages/#{split_to_id}"))
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
        comment = Comment.create!(:user_id => $BACKGROUND_TASK_USER_ID, :body => options[:comment], :parent => parent)
      end
      log = CuratorActivityLog.create!(:user_id => user_id,
                                       :changeable_object_type_id => comment ?
                                          ChangeableObjectType.comment.id :
                                          ChangeableObjectType.classification_curation.id,
                                       :object_id => options[:comment] ? comment.id : id,
                                       :activity_id => activity.id,
                                       :created_at => 0.seconds.from_now,
                                       :taxon_concept_id => parent.id)
    rescue => e
      logger.error "** ERROR: Could not create CuratorActivityLog for #{self}: #{e.message}"
    end
    log
  end

  def force_immediate_notification_of(moved_to)
    begin
      PendingNotification.create!(:user_id => user_id,
                                  :notification_frequency_id => NotificationFrequency.immediately.id,
                                  :target => moved_to,
                                  :reason => 'auto_email_after_curation')
      Resque.enqueue(PrepareAndSendNotifications)
    rescue => e
      # Do nothing (for now)...
    end
  end

  def log_activity_on(taxon_concept)
    CuratorActivityLog.create(
      :user => user,
      :taxon_concept => taxon_concept,
      :changeable_object_type => ChangeableObjectType.classification_curation,
      :object_id => id,
      :activity_id => Activity.curate_classifications.id,
      :created_at => 0.seconds.from_now
    )
  end

  def to_s
    "ClassificationCuration ##{self.id} (moved_from #{source_id}, moved_to #{target_id})"
  end

  # TODO - update_column, after upgrade merge
  # This method makes sure we don't process a ClassificationCuration twice, and makes sure that classifications don't
  # show up as "pending curation" on the names tab anymore.
  def mark_as_complete
    hierarchy_entry_moves.each do |move|
      move.update_attribute(:completed_at, Time.now)
    end
    update_attribute(:completed_at, Time.now)
  end

  def split_to_id
    hierarchy_entry_moves.first.hierarchy_entry.taxon_concept_id
  end
end
