class Activity < LazyLoggingModel

  establish_connection("#{Rails.env}_logging")

  CACHE_ALL_ROWS = true
  uses_translations

  include Enumerated
  # NOTE - These are only activities THAT GET LOGGED.  ...for now.
  # NOTE - The tense is inconsistent, but doesn't *really* matter.  Keep the ones you see as-is (since they are in
  # the DB... but as you add new ones, try to use the verb's present tense ("take", not "taken" or "took").
  # TODO - many of these are not used yet.  Add them to the code in the appropriate place
  enumerated :name,
    %w(create update delete trusted untrusted show hide inappropriate rate unreviewed add_association
       remove_association choose_exemplar_image choose_exemplar_article add_common_name remove_common_name
       preferred_classification curate_classifications split_classifications merge_classifications trust_common_name
       untrust_common_name inappropriate_common_name unreview_common_name unlock unlock_with_error crop add_editor
       bulk_add create collect remove remove_all create delete join leave add_collection change_description
       change_name change_icon add_manager set_exemplar_data unhide resource_validation)

  has_many :activity_logs
  has_many :curator_activity_logs
  has_many :translated_activities

  # This is used by migrations, to safely add "new" activities as needed.
  # TODO - we could generalize this from Enumerated and call that.
  def self.find_or_create(key_sym)
    key = key_sym.to_s
    act = Activity.cached_find_translated(:name, key)
    unless act
      act = Activity.new()
      act.save! # NOTE: #create wasn't working; the ID wasn't being set correctly.
      if transact = TranslatedActivity.find_by_language_id_and_name(Language.english.id, key)
        transact.update_attributes(activity_id: act.id)
      else
        # Doing this with raw sql to override the LoggingModel's default of using INSERT DELAYED
        TranslatedActivity.connection.execute(ActiveRecord::Base.sanitize_sql_array(
          ['INSERT INTO translated_activities (name, activity_id, language_id) VALUES (?, ?, ?)',
            key, act.id, Language.english.id]
        ))
      end
      act = Activity.cached_find_translated(:name, key)
    end
    act
  end

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
