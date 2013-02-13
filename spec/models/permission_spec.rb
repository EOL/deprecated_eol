require 'spec_helper'

describe Permission do
  
  # NOTE - this is a tricky test. It actually also tests that symbols are stringified as expected, that translations
  # work, and of course, that all of the specific defaults we expect to see are really there:
  it 'shoud create defaults' do
    TranslatedPermission.delete_all
    Permission.delete_all
    Permission.create_defaults
    Permission.edit_permissions.should_not be_nil
    Permission.edit_permissions.name.should == "edit permissions"
  end

  it 'should count users properly' do
    perm = TranslatedPermission.gen.permission # NOTE - I hate doing that, but that's the expectation with uses_translations.
    perm.users_count = 0
    perm.inc_user_count
    perm.users_count.should == 1
    perm.inc_user_count
    perm.users_count.should == 2
    perm.dec_user_count
    perm.users_count.should == 1
    perm.dec_user_count
    perm.users_count.should == 0
    perm.dec_user_count
    perm.users_count.should == 0
  end

end
