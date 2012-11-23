require File.dirname(__FILE__) + '/../spec_helper'

class SomethingActivityLoggable
  include EOL::ActivityLoggable
end

# An incredibly simple but critical class that delegates the pulling of logs to EOL::ActivityLog. It also caches
# similar calls.
describe EOL::ActivityLog do
  before(:each) do
    @something = SomethingActivityLoggable.new
  end
  it '#activity_log should pull an activity log from EOL::ActivityLog with the instance calling it' do
    EOL::ActivityLog.should_receive(:find).with(@something, {})
    @something.activity_log
  end
  it '#activity_log should pass options along to EOL::ActivityLog' do
    EOL::ActivityLog.should_receive(:find).with(@something, {hi: 'there'})
    @something.activity_log(hi: 'there')
  end
  it '#activity_log should cache its value for duplicate options' do
    EOL::ActivityLog.should_receive(:find).exactly(1).times
    @something.activity_log(foo: 'bar')
    @something.activity_log(foo: 'bar')
  end
end
