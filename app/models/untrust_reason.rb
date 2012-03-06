# Reasons used by curators to explain why they "untrusted" a data object.
#
# Note that these are looked up by "class_name", but they contain a (translated) "label" which is what should be
# displayed to the user.  The class name is used not only for lookup, but also for... uhhh... class names in CSS, as
# well as the IDs on some HTML elements.
class UntrustReason < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  uses_translations
  has_and_belongs_to_many :curator_activity_logs, :join_table => "#{UntrustReason.configurations[RAILS_ENV]['database']}.curator_activity_logs_untrust_reasons"

  def self.misidentified
    cached_find(:class_name, 'misidentified')
  end

  def self.incorrect
    cached_find(:class_name, 'incorrect')
  end

  def self.poor
    cached_find(:class_name, 'poor')
  end

  def self.duplicate
    cached_find(:class_name, 'duplicate')
  end

  def self.other
    cached_find(:class_name, 'other')
  end
end
