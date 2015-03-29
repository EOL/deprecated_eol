# Reasons used by curators to explain why they "untrusted" a data object.
#
# Note that these are looked up by "class_name", but they contain a (translated)
# "label" which is what should be displayed to the user.  The class name is used
# not only for lookup, but also for... uhhh... class names in CSS, as well as
# the IDs on some HTML elements.
class UntrustReason < ActiveRecord::Base

  uses_translations
  has_and_belongs_to_many :curator_activity_logs, join_table: CuratorActivityLogsUntrustReason.full_table_name

  include Enumerated
  enumerated :class_name, %w(misidentified incorrect poor duplicate other)

end
