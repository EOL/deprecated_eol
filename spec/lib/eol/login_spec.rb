require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::Login do

  include EOL::Login

  describe '#log_in' do

    it 'should raise EOL::Exceptions::SecurityViolation if user is inactive' do
      return_to = '/users/recover_account'
      self.should_receive(:recover_account_users_url).once.and_return(return_to)
      self.should_receive(:store_location).once.with(return_to)
      expect { log_in(User.new(:active => false)) }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should raise EOL::Exceptions::SecurityViolation if user is hidden' do
      expect { log_in(User.new(:hidden => true)) }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should not raise EOL::Exceptions::SecurityViolation if user is active and not hidden' do
      expect { log_in(User.new(:hidden => false, :active => true)) }.to_not raise_error(EOL::Exceptions::SecurityViolation)
    end

    # it 'should update user_id in session and current user language' test with controllers or integration

  end

end

