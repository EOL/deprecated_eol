class Activity < LazyLoggingModel

  CACHE_ALL_ROWS = true
  uses_translations

  has_many :activity_logs
  has_many :curator_activity_logs
  has_many :translated_activities

  # NOTE - assumes Language.english exists.  You'll get weird results otherwise.
  # NOTE - I'm leaving duplicates in here, since they should be handled and make deleting rows easier.
  # NOTE - These are only activities THAT GET LOGGED.  ...for now.  In the future, we may want to add a visibility to
  # NOTE - The tense is inconsistent, but doesn't *really* matter.  Keep the ones you see as-is (since they are in
  # the DB... but as you add new ones, try to use the verb's present tense ("take", not "taken" or "took").
  # each of these and include those activities that don't show up on the site's activity logs.
  # TODO - many of these are not used yet.  Add them to the code in the appropriate place
  def self.create_defaults
    TranslatedActivity.reset_cached_instances
    Activity.reset_cached_instances
    # User Data Objects (user-submitted text):
    Activity.find_or_create('create')
    Activity.find_or_create('update')
    Activity.find_or_create('delete')
    # Curation:
    Activity.find_or_create('trusted')
    Activity.find_or_create('untrusted')
    Activity.find_or_create('show')
    Activity.find_or_create('hide')
    Activity.find_or_create('inappropriate')
    Activity.find_or_create('rate')
    Activity.find_or_create('unreviewed')
    Activity.find_or_create('add_association')
    Activity.find_or_create('remove_association')
    Activity.find_or_create('choose_exemplar_image')
    Activity.find_or_create('choose_exemplar_article')
    Activity.find_or_create('add_common_name')
    Activity.find_or_create('remove_common_name')
    Activity.find_or_create('preferred_classification')
    Activity.find_or_create('curate_classifications')
    Activity.find_or_create('split_classifications') # Legacy, but in the DB...
    Activity.find_or_create('merge_classifications') # Legacy, but in the DB...
    Activity.find_or_create('trust_common_name')
    Activity.find_or_create('untrust_common_name')
    Activity.find_or_create('inappropriate_common_name')
    Activity.find_or_create('unreview_common_name')
    Activity.find_or_create('unlock') # ...when a backgrounded process finishes.
    Activity.find_or_create('unlock_with_error') # ...when a backgrounded process fails.
    # Collection:
    Activity.find_or_create('add_editor')
    Activity.find_or_create('bulk_add')
    Activity.find_or_create('create')
    Activity.find_or_create('collect')
    Activity.find_or_create('remove')
    Activity.find_or_create('remove_all')
    # Community:
    Activity.find_or_create('create')
    Activity.find_or_create('delete')
    Activity.find_or_create('join')
    Activity.find_or_create('leave')
    Activity.find_or_create('add_collection')
    Activity.find_or_create('change_description')
    Activity.find_or_create('change_name')
    Activity.find_or_create('change_icon')
    Activity.find_or_create('add_manager')
    Activity.count
  end

  def self.find_or_create(key_sym)
    key = key_sym.to_s
    act = Activity.cached_find_translated(:name, key)
    unless act
      act = Activity.new()
      act.save! # NOTE: #create wasn't working; the ID wasn't being set correctly.
      if transact = TranslatedActivity.find_by_language_id_and_name(Language.english.id, key)
        transact.update_attributes(:activity_id => act.id)
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

  def self.method_missing(name, *args, &block)
    @@activity_local_cache ||= {}
    @@activity_local_cache[name] ||= cached("activity_method_missing_#{name}") do
      # TODO - this should be cached, but since we're in method_missing, that's tricky.
      transact = TranslatedActivity.find(:first, :conditions => ["name = ? AND language_id = ?", name.to_s,
                                    Language.english.id])
      if transact
        transact.activity
      else
        super
      end
    end
  end

  # Since create is normally a reserved word, the method missing won't work for it (all the time):
  def self.create
    act = self.cached_find_translated(:name, 'create')
  end

  # Since delete is normally a reserved word, the method missing won't work for it (all the time):
  def self.delete
    act = self.cached_find_translated(:name, 'delete')
  end

  # Since create is normally a reserved word, the method missing won't work for it (all the time):
  def self.update
    act = self.cached_find_translated(:name, 'update')
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
