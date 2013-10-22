# NOTE - The tense is inconsistent, but doesn't *really* matter.  Keep the ones you see as-is (since they are in
# the DB... but as you add new ones, try to use the verb's present tense ("take", not "taken" or "took").
class Activity < LazyLoggingModel
  establish_connection("#{Rails.env}_logging")

  CACHE_ALL_ROWS = true
  uses_translations

  has_many :activity_logs
  has_many :curator_activity_logs
  has_many :translated_activities

  include EnumDefaults

  # NOTE - These are only activities THAT GET LOGGED.  ...for now.
  # TODO - many of these are not used yet.  Add them to the code in the appropriate place
  # NOTE - some of these override default methods, but we don't care: #create, #update, #delete...
  set_defaults :name,
    %w(create update delete trusted untrusted show hide inappropriate rate unreviewed add_association
       remove_association choose_exemplar_image choose_exemplar_article add_common_name remove_common_name
       preferred_classification curate_classifications split_classifications merge_classifications trust_common_name
       untrust_common_name inappropriate_common_name unreview_common_name unlock unlock_with_error crop add_editor
       bulk_add create collect remove remove_all create delete join leave add_collection change_description
       change_name change_icon add_manager set_exemplar_data unhide),
    translated: true

  def self.synonym_activity_ids
    @@synonym_activity_ids ||= cached("synonym_activity_ids") do
      [Activity.add_common_name.id, Activity.remove_common_name.id, Activity.trust_common_name.id,
        Activity.unreview_common_name.id, Activity.untrust_common_name.id, Activity.inappropriate_common_name.id]
    end
  end

  # Helper to provide consistent calculation of curator actions when using curator_activity_logs_on_data_objects
  # association
  def self.raw_curator_action_ids
        [ trusted.id,
          untrusted.id,
          show.id,
          hide.id,
          inappropriate.id,
          unreviewed.id ]
  end

end
