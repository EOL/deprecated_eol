require 'spec_helper'

describe DataPointUri do
  before(:all) do
    load_foundation_cache
  end

  it 'should hide/show user_added_data when hidden/show' do
    d = DataPointUri.gen()
    d.reload  # not exactly sure why the reload is necessary here, but it was failing without it
    d.visibility_id.should == Visibility.visible.id
    d.user_added_data.visibility_id.should == Visibility.visible.id
    d.hide(User.last)
    d.visibility_id.should == Visibility.invisible.id
    d.user_added_data.visibility_id.should == Visibility.invisible.id
    d.show(User.last)
    d.visibility_id.should == Visibility.visible.id
    d.user_added_data.visibility_id.should == Visibility.visible.id
  end

  pending "add some examples to (or delete) #{__FILE__}"

end
