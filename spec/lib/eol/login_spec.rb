require File.dirname(__FILE__) + '/../../spec_helper'

describe EOL::Login do

  include EOL::Login

  describe '#log_in' do

    it 'should raise EOL::Exceptions::SecurityViolation if user is inactive' do
      expect { log_in(User.new(:active => false)) }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should raise EOL::Exceptions::SecurityViolation if user is hidden' do
      expect { log_in(User.new(:hidden => true)) }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should not raise EOL::Exceptions::SecurityViolation if user is active and not hidden' do
      expect { log_in(User.new(:hidden => false, :active => true)) }.to_not raise_error(EOL::Exceptions::SecurityViolation)
    end

    # it 'should update user_id in session and current user language'
    # we test this elsewhere when we have session and so on available

  end

end

