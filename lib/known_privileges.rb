# The following are essentially "Hard Coded".  These will be the English names; local versions of the code will change
# these with LOCAL scripts, but the "sym" attribute will remain the same.  ...The sym for each will be the English name run
# through the #string_to_symbol method (essentially, underscored and downcased).  So, "Edit/Delete Community" will be
# Privilege#edit_delete_community.
class KnownPrivileges

  @community = {
    'Edit/Delete Community' => 20,
    'Grant level 20 Privileges' => 20,
    'Revoke level 20 Privileges' => 20,
    'Add members' => 10,
    'Remove members' => 10,
    'Grant level 10 Privileges' => 10,
    'Revoke level 10 Privileges' => 10,
    'Create Badges' => 10,
    'Revoke Badges' => 10,
    'Track User Identities' => 10,
    'Award Badges' => 5,
    'Edit Lists' => 5,
    'Endorse Lists' => 5,
    'Create Newsfeed Posts' => 5,
    'Invite Users' => 5
  }

  @special = {
    'Admin' => 20,
    'Technical' => 20,
    'Site CMS' => 18,
    'News Items' => 18,
    'Web Users' => 15,
    'Content Partners' => 15,
    'Usage Reports' => 15,
    'Comments and Tags' => 12,
    'Contact Us Submissions' => 12,
    'View Admin Page' => 12,
    'Vet' => 10,
    'Trusted Author' => 10,
    'Show/Hide Comments' => 10,
    'Rate' => 1
  }

  # attr_reader wasn't working.  Hmmmn.  Sorry.
  def self.community
    @community
  end
  def self.special
    @special
  end

  # We don't want to send unknown names to $CACHE (nor to the DB), so we need a list of good names:
  def self.symbols
    @symbols ||= (self.community.keys + self.special.keys).map {|s| self.string_to_symbol(s)}
  end

  def self.string_to_symbol(string)
    @@str_to_sym_re = /[^A-Za-z0-9]/
    string.gsub(@@str_to_sym_re, '_').downcase.to_sym
  end

  def self.create_all
    self.special.keys.each do |key|
      Privilege.create(:name => key, :sym => self.string_to_symbol(key).to_s, :level => self.special[key], :special => true)
    end

    self.community.keys.each do |key|
      Privilege.create(:name => key, :sym => self.string_to_symbol(key).to_s, :level => self.community[key], :type => 'community')
    end
  end

end

# In Egpyt, there w/b a script:
# Privilege.administrator.title = "Some Arabic String"
# (etc)
