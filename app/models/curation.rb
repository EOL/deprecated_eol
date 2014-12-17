class Curation

  attr_reader :errors, :association, :vetted, :visibility, :user, :comment, :untrust_reason_ids, :hide_reason_ids

  # Curate without checking validations first. Exceptions will be raised if anything is invalid.
  def self.curate(options)
    Curation.new(options).curate
  end

  def initialize(options)
    @user = options[:user]
    @association = options[:association]
    @vetted = options[:vetted] || @association.vetted
    @visibility = options[:visibility] || @association.visibility
    @comment = options[:comment]
    @untrust_reason_ids = options[:untrust_reason_ids] || []
    @hide_reason_ids = options[:hide_reason_ids] || []

    # Automatically hide it, if the curator made it untrusted:
    @visibility = Visibility.invisible if untrusting?
  end

  def warnings
    return @warnings if @warnings # NOTE - this means we cannot check twice, but hey.
    @warnings = []
    @warnings << 'nothing changed' unless something_needs_curation?
    @warnings
  end

  # Aborts if nothing changed. Otherwise, decides what to curate, handles that, and logs the changes:
  def curate
    return unless something_needs_curation?
    raise(@errors.to_sentence) unless valid?
    handle_vetting if vetted_changed?
    handle_visibility if visibility_changed?
  end
  
  def curate_as_deleted
    @vetted.apply_to(@association, @user) if vetted_changed?
    if visibility_changed?
      @visibility.apply_to(@association, @user)
      @association.taxon_concept.clear_for_data_object(@association.data_object)
    end
  end

  def valid?
    validate
    @errors.empty?
  end

private

  def hiding?
    @visibility == Visibility.invisible
  end

  def untrusting?
    @vetted == Vetted.untrusted
  end

  # TODO - this just raises the first error. We shoudln't do that.
  def validate
    return @errors if @errors # Note you cannot try validation twice.
    @errors = []
    check_hide_reasons_missing
    check_untrust_reasons_missing
    check_vetted_invalid
    check_visibility_invalid
    check_untrust_reasons_invalid
    check_for_preview
    @errors
  end

  # NOTE carefully that we don't care about hide reasons when we're untrusting...
  def check_hide_reasons_missing
    @errors << 'no hide reasons given' if
      hiding? && !untrusting? && @hide_reason_ids.empty? && @comment.nil?
  end

  def check_untrust_reasons_missing
    @errors << 'no untrust reasons given' if untrusting? && @untrust_reason_ids.empty? && @comment.nil?
  end

  def check_vetted_invalid
    @errors << 'vetted invalid' unless @vetted.can_apply?
  end

  def check_visibility_invalid
    @errors << 'visibility invalid' unless @visibility.can_apply?
  end

  def check_untrust_reasons_invalid
    if untrusting? # Important to check vetted first; we don't care about hiding if untrusting...
      @untrust_reason_ids.each do |reason|
        @errors << 'untrust reasons invalid' unless
          [UntrustReason.misidentified.id, UntrustReason.incorrect.id].include?(reason.to_i)
      end
    elsif hiding?
      @hide_reason_ids.each do |reason|
        @errors << 'hide reasons invalid' unless
          [UntrustReason.poor.id, UntrustReason.duplicate.id].include?(reason.to_i)
      end
    end
  end

  def check_for_preview
    @errors << 'object in preview state cannot be curated' if object_in_preview_state?
  end

  def object_in_preview_state?
    @association.preview?
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

  def handle_vetting
    @vetted.apply_to(@association, @user)
    log = log_action(@vetted.to_action)
    log.untrust_reasons = UntrustReason.find(@untrust_reason_ids) if untrusting?
  end

  def handle_visibility
    @visibility.apply_to(@association, @user)
    log = log_action(@visibility.to_action)
    if hiding?
      log.untrust_reasons = UntrustReason.find(@hide_reason_ids)
    end
    @association.taxon_concept.clear_for_data_object(@association.data_object)
  end

  def log_action(action)
    CuratorActivityLog.factory(
      action: action,
      association: @association.source,
      data_object: @association.data_object,
      user: @user
    )
  end

end
