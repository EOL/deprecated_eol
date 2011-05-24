class TranslatedPrivilege < ActiveRecord::Base
  belongs_to :privilege
  belongs_to :language

  validates_presence_of :name
  validates_uniqueness_of :name
  # Only certain characters are allowed in Privilege names, because we hard code them.  For example "Grant Level 20
  # Privileges" becomes grant_level_20_privileges. And, more importantly, vice-versa.  So if you had one like "This
  # has_an_underscore", that wouldn't work, because we assume underscores become spaces, so it would look for "This
  # has an underscore", and would fail.
  validates_format_of :name, :with => /\A[ A-Za-z0-9]+\Z/i, :on => :create

end
