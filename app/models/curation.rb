class Curation

  attr_reader :clearables

  def initialize(options)
    @clearables = []
    @user = options[:user]
    @association = options[:association]
    @data_object = options[:data_object]
    debugger if $FOO
    curate_association(@user, options)
  end

  # Aborts if nothing changed. Otherwise, decides what to curate, handles that, and logs the changes:
  def curate_association(user, opts)
    if something_needs_curation?(opts)
      curated_object = get_curated_object
      return if curated_object.visibility_id == Visibility.preview.id
      handle_curation(curated_object, user, opts).each do |action|
        log = log_action(curated_object, action)
        # Saves untrust reasons, if any
        unless opts[:untrust_reason_ids].blank?
          save_untrust_reasons(log, action, opts[:untrust_reason_ids])
        end
        unless opts[:hide_reason_ids].blank?
          save_hide_reasons(log, action, opts[:hide_reason_ids])
        end
        clear_cached_media_count_and_exemplar if action == :hide
      end
    end
  end

  def something_needs_curation?(opts)
    opts[:vet?] || opts[:visibility?]
  end

  def get_curated_object
    if @association.class == UsersDataObject
      curated_object = UsersDataObject.find_by_data_object_id(@data_object.latest_published_version_in_same_language.id)
    elsif @association.associated_by_curator
      curated_object = CuratedDataObjectsHierarchyEntry.find_by_data_object_guid_and_hierarchy_entry_id(@data_object.guid, @association.id)
    else
      curated_object = DataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id(@data_object.latest_published_version_in_same_language.id, @association.id)
    end
  end

  # Figures out exactly what kind of curation is occuring, and performs it.  Returns an *array* of symbols
  # representing the actions that were taken.  ...which you may want to log.  :)
  def handle_curation(object, user, opts)
    actions = []
    raise "Curator should supply at least visibility or vetted information" unless (opts[:vet?] || opts[:visibility?])
    actions << handle_vetting(object, opts[:vetted_id].to_i, opts[:visibility_id].to_i, opts) if opts[:vet?]
    actions << handle_visibility(object, opts[:vetted_id].to_i, opts[:visibility_id].to_i, opts) if opts[:visibility?]
    return actions.flatten
  end

  def handle_vetting(object, vetted_id, visibility_id, opts)
    if vetted_id
      case vetted_id
      when Vetted.inappropriate.id
        object.inappropriate(@user)
        return :inappropriate
      when Vetted.untrusted.id
        raise "Curator should supply at least untrust reason(s) and/or curation comment" if (opts[:untrust_reason_ids].blank? && opts[:curation_comment].nil?)
        object.untrust(@user)
        return :untrusted
      when Vetted.trusted.id
        if visibility_id == Visibility.invisible.id && opts[:hide_reason_ids].blank? && opts[:curation_comment].nil?
          raise "Curator should supply at least reason(s) to hide and/or curation comment"
        end
        object.trust(@user)
        return :trusted
      when Vetted.unknown.id
        if visibility_id == Visibility.invisible.id && opts[:hide_reason_ids].blank? && opts[:curation_comment].nil?
          raise "Curator should supply at least reason(s) to hide and/or curation comment"
        end
        object.unreviewed(@user)
        return :unreviewed
      else
        raise "Cannot set data object vetted id to #{vetted_id}"
      end
    end
  end

  def handle_visibility(object, vetted_id, visibility_id, opts)
    if visibility_id
      case visibility_id
      when Visibility.visible.id
        object.show(@user)
        return :show
      when Visibility.invisible.id
        if vetted_id != Vetted.untrusted.id && opts[:hide_reason_ids].blank? && opts[:curation_comment].nil?
          raise "Curator should supply at least reason(s) to hide and/or curation comment"
        end
        object.hide(@user)
        return :hide
      else
        raise "Cannot set data object visibility id to #{visibility_id}"
      end
    end
  end

  def clear_cached_media_count_and_exemplar
    @clearables << @association
  end

  def save_untrust_reasons(log, action, untrust_reason_ids)
    untrust_reason_ids.each do |untrust_reason_id|
      case untrust_reason_id.to_i
      when UntrustReason.misidentified.id
        log.untrust_reasons << UntrustReason.misidentified if action == :untrusted
      when UntrustReason.incorrect.id
        log.untrust_reasons << UntrustReason.incorrect if action == :untrusted
      else
        raise "Please re-check the provided untrust reasons"
      end
    end
  end

  def save_hide_reasons(log, action, hide_reason_ids)
    hide_reason_ids.each do |hide_reason_id|
      case hide_reason_id.to_i
      when UntrustReason.poor.id
        log.untrust_reasons << UntrustReason.poor if action == :hide
      when UntrustReason.duplicate.id
        log.untrust_reasons << UntrustReason.duplicate if action == :hide
      else
        raise "Please re-check the provided hide reasons"
      end
    end
  end

  # TODO - this was mostly stolen from data_objects controller. Generalize.
  def log_action(object, method)
    object_id = object.data_object_id if object.class.name == "DataObjectsHierarchyEntry" || object.class.name == "CuratedDataObjectsHierarchyEntry" || object.class.name == "UsersDataObject"
    return if object.blank?
    object_id = object.id if object_id.blank?

    if object.class.name == "DataObjectsHierarchyEntry" || object.class.name == "CuratedDataObjectsHierarchyEntry"
      he = object.hierarchy_entry
    elsif object.class.name == "HierarchyEntry"
      he = object
    end

    create_options = {
      :user_id => @user.id,
      :changeable_object_type => ChangeableObjectType.send(object.class.name.underscore.to_sym),
      :object_id => object_id,
      :activity => Activity.send(method),
      :data_object => @data_object,
      :data_object_guid => @data_object.guid,
      :hierarchy_entry_id => he.id,
      :created_at => 0.seconds.from_now
    }
    if object.class.name == "UsersDataObject"
      create_options.merge!(:taxon_concept_id => object.taxon_concept_id)
    end
    CuratorActivityLog.create(create_options)
  end

end
