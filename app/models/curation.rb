class Curation

  attr_reader :clearables

  def initialize(options)
    @clearables = []
    @user = options[:user]
    @association = options[:association]
    @data_object = options[:data_object] # TODO - Change association to a class, give it a #data_object, stop passing
    @vetted = options[:vetted] || @association.vetted
    @visibility = options[:visibility] || @association.visibility
    @comment = options[:comment]
    @untrust_reason_ids = options[:untrust_reason_ids] || []
    @hide_reason_ids = options[:hide_reason_ids] || []

    # Automatically hide it, if the curator made it untrusted:
    @visibility = Visibility.invisible if @vetted == Vetted.untrusted

    curate_association
  end

  def warnings
    return @warnings if @warnings # NOTE - this means we cannot check twice, but hey.
    @warnings = []
    @warnings << 'nothing changed' unless something_needs_curation?
    @warnings << 'object in preview state cannot be curated' if object_in_preview_state? # TODO - error!
    @warnings
  end

private

  def object_in_preview_state?
    curated_object.visibility == Visibility.preview
  end

  # Aborts if nothing changed. Otherwise, decides what to curate, handles that, and logs the changes:
  def curate_association
    return unless something_needs_curation?
    return if object_in_preview_state?
    handle_curation.each do |action|
      log = log_action(action)
      save_untrust_reasons(log, action)
      save_hide_reasons(log, action)
      clear_cached_media_count_and_exemplar if action == :hide
    end
  end

  def something_needs_curation?
    vetted_changed? || visibility_changed?
  end

  def vetted_changed?
    @vetted_changed ||= @vetted && @association.vetted != @vetted
  end

  def visibility_changed?
    @visibility_changed ||= @visibility && @association.visibility != @visibility
  end

  def curated_object
    @curated_object ||= if @association.class == UsersDataObject
        UsersDataObject.find_by_data_object_id(@data_object.latest_published_version_in_same_language.id)
      elsif @association.associated_by_curator
        CuratedDataObjectsHierarchyEntry.find_by_data_object_guid_and_hierarchy_entry_id(@data_object.guid, @association.id)
      else
        DataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id(@data_object.latest_published_version_in_same_language.id, @association.id)
      end
  end

  # Figures out exactly what kind of curation is occuring, and performs it.  Returns an *array* of symbols
  # representing the actions that were taken.  ...which you may want to log.  :)
  def handle_curation
    actions = []
    actions << handle_vetting if vetted_changed?
    actions << handle_visibility if visibility_changed?
    return actions
  end

  def handle_vetting
    if @vetted
      case @vetted
      when Vetted.untrusted
        raise "Curator should supply at least untrust reason(s) and/or curation comment" if no_untrust_reasons_given?
        curated_object.untrust(@user)
        return :untrusted
      when Vetted.trusted
        fail_if_no_hide_reasons_given
        curated_object.trust(@user)
        return :trusted
      when Vetted.unknown
        fail_if_no_hide_reasons_given
        curated_object.unreviewed(@user)
        return :unreviewed
      else
        raise "Cannot set data object vetted id to #{@vetted.label}"
      end
    end
  end

  def fail_if_no_hide_reasons_given
    raise 'no hide reasons given' if @visibility == Visibility.invisible && @vetted != Vetted.untrusted && no_hide_reasons_given?
  end

  def no_untrust_reasons_given?
    @untrust_reason_ids.blank? && @comment.nil?
  end

  def no_hide_reasons_given?
    @hide_reason_ids.blank? && @comment.nil?
  end

  def handle_visibility
    if @visibility
      case @visibility
      when Visibility.visible
        curated_object.show(@user)
        return :show
      when Visibility.invisible
        fail_if_no_hide_reasons_given
        curated_object.hide(@user)
        return :hide
      else
        raise "Cannot set data object visibility id to #{@visibility.label}"
      end
    end
  end

  def clear_cached_media_count_and_exemplar
    @clearables << @association
  end

  # TODO - wrong place for this logic; the curator activity log should handle these validations.
  def save_untrust_reasons(log, action)
    @untrust_reason_ids.each do |untrust_reason_id|
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

  def save_hide_reasons(log, action)
    @hide_reason_ids.each do |hide_reason_id|
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
  def log_action(method)
    object_id = curated_object.data_object_id if curated_object.class.name == "DataObjectsHierarchyEntry" || curated_object.class.name == "CuratedDataObjectsHierarchyEntry" || curated_object.class.name == "UsersDataObject"
    return if curated_object.blank?
    object_id = curated_object.id if object_id.blank?

    if curated_object.class.name == "DataObjectsHierarchyEntry" || curated_object.class.name == "CuratedDataObjectsHierarchyEntry"
      he = curated_object.hierarchy_entry
    elsif curated_object.class.name == "HierarchyEntry"
      he = curated_object
    # TODO - what if object is a UsersDataObject?  Why isn't it clear?
    end

    create_options = {
      :user_id => @user.id,
      :changeable_object_type => ChangeableObjectType.send(curated_object.class.name.underscore.to_sym),
      :object_id => object_id,
      :activity => Activity.send(method),
      :data_object => @data_object,
      :data_object_guid => @data_object.guid,
      :hierarchy_entry => he,
      :created_at => 0.seconds.from_now
    }
    if curated_object.class.name == "UsersDataObject"
      create_options.merge!(:taxon_concept_id => curated_object.taxon_concept_id)
    end
    CuratorActivityLog.create(create_options)
  end

end
