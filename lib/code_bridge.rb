# What this represents is a way for Ruby to talk to PHP.  If PHP and Ruby share class names (exactly--that's why this
# is not EOL::CodeBridge; nesting classes isn't the same), they can talk to one another using normal JSON...
# The library is needed for the translation.
class CodeBridge
  @queue = 'php' # Anything in the php queue will be handled by php, DUH.

  # This method is called when PHP talks to Ruby!
  def self.perform(args)
    if args['cmd'] == 'unlock_notify'

      cal = CuratorActivityLog.create(:user_id => args['user_id'],
                                      :changeable_object_type_id => ChangeableObjectType.taxon_concept.id, 
                                      :object_id => args['taxon_concept_id'],
                                      :activity_id => Activity.unlock.id,
                                      :taxon_concept_id => args['taxon_concept_id'])

      # FORCE immediate notification.  Right now:
      PendingNotification.create(:user_id => args['user_id'],
                                 :notification_frequency_id => NotificationFrequency.immediately.id,
                                 :target_id => cal.id,
                                 :target_type => 'CuratorActivityLog',
                                 :reason => 'auto_email_after_curation')

    else
      puts "** ERROR: NO command responds to #{args['cmd']}"
    end
  end

  # These methods are here for actually enqueing the jobs. Thus, you call CodeBridge.split_classification(data),
  # and the data will be moved to PHP and handled there. These class methods are NOT called by Resque!
  def self.move_entry(options = {})
    Resque.enqueue(CodeBridge, {'cmd'                          => 'move',
                                'taxon_concept_id_from'        => options[:from_taxon_concept_id],
                                'hierarchy_entry_id'           => options[:hierarchy_entry_id],
                                'taxon_concept_id_to'          => options[:to_taxon_concept_id],
                                'bad_match_hierarchy_entry_id' => options[:exemplar_id],
                                'confirmed'                    => 'confirmed',
                                'notify'                       => options[:notify],
                                'reindex'                      => options[:reindex] ? 'reindex' : '' })
  end

  def self.split_entry(options = {})
    Resque.enqueue(CodeBridge, {'cmd'                          => 'split',
                                'hierarchy_entry_id'           => options[:hierarchy_entry_id],
                                'bad_match_hierarchy_entry_id' => options[:exemplar_id],
                                'confirmed'                    => 'confirmed',
                                'notify'                       => options[:notify],
                                'reindex'                      => options[:reindex] ? 'reindex' : '' })
  end

  def self.merge_taxa(id1, id2, options = {})
    Resque.enqueue(CodeBridge, {'cmd'       => 'merge',
                                'id1'       => id1,
                                'id2'       => id2,
                                'notify'    => options[:notify],
                                'confirmed' => 'confirmed'})
  end

end
