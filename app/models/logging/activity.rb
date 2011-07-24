class Activity < LazyLoggingModel

  CACHE_ALL_ROWS = true
  uses_translations

  has_many :activity_logs
  has_many :curator_activity_logs

  # NOTE - assumes Language.english exists.  You'll get weird results otherwise.
  # NOTE - I'm leaving duplicates in here, since they should be handled and make deleting rows easier.
  # NOTE - These are only activities THAT GET LOGGED.  ...for now.  In the future, we may want to add a visibility to
  # each of these and include those activities that don't show up on the site's activity logs.
  def self.create_defaults
    Activity.reset_cached_instances
    # Curation:
    Activity.find_or_create('create')
    Activity.find_or_create('update')     #?
    Activity.find_or_create('delete')
    Activity.find_or_create('trusted')
    Activity.find_or_create('untrusted')
    Activity.find_or_create('show')
    Activity.find_or_create('hide')
    Activity.find_or_create('inappropriate')
    Activity.find_or_create('rate')
    Activity.find_or_create('unreviewed') # tense is wrong for historical reasons, please keep.
    Activity.find_or_create('add_association')
    Activity.find_or_create('remove_association')
    Activity.find_or_create('choose_exemplar')
    Activity.find_or_create('add_common_name')
    Activity.find_or_create('remove_common_name')
    # Collection:
    Activity.find_or_create('create')
    Activity.find_or_create('collect')
    Activity.find_or_create('remove')
    # Community:
    Activity.find_or_create('create')
    Activity.find_or_create('delete')
    Activity.find_or_create('add_member')
    Activity.find_or_create('change_description')
    Activity.find_or_create('change_name')
    Activity.find_or_create('change_icon')
    Activity.find_or_create('add_admin')
    Activity.find_or_create('add_curator')
    Activity.find_or_create('add_member_privilege')
    Activity.find_or_create('add_collection_endorsement')
    Activity.find_or_create('remove_collection_endorsement')
  end

  def self.find_or_create(key_sym)
    key = key_sym.to_s
    if act = Activity.cached_find_translated(:name, key)
      return act
    else
      # Doing this with raw sql to override the LoggingModel's default of using INSERT DELAYED
      act = Activity.new()
      act.save! # NOTE: #create wasn't working; the ID wasn't being set correctly.  Second time this has been a prob.
      begin
        if transact = TranslatedActivity.find_by_language_id_and_name(Language.english.id, key)
          transact.update_attributes(:activity_id, act.id)
        else
          TranslatedActivity.connection.execute(ActiveRecord::Base.sanitize_sql_array(['INSERT INTO translated_activities (name, activity_id, language_id) VALUES (?, ?, ?)', key, act.id, Language.english.id]))
        end
      rescue => e
        # We're in a migration; Activity wasn't translated yet.
        Activity.connection.execute(ActiveRecord::Base.sanitize_sql_array(['INSERT INTO activities (name) VALUES (?)', key]))
      end
      return Activity.cached_find_translated(:name, key)
    end
  end

  def self.method_missing(name, *args, &block)
    # TODO - this should be cached, but since we're in method_missing, that's a little tricky.
    transact = TranslatedActivity.find(:first, :conditions => ["name = ? AND language_id = ?", name.to_s,
                                  Language.english.id])
    return super unless transact
    transact.activity
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
