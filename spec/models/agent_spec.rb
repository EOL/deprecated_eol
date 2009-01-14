require File.dirname(__FILE__) + '/../spec_helper'

describe Agent do

  it '#create_valid should be valid' do
    Agent.create_valid!.should be_valid
  end

end

describe Agent, 'with fixtures' do
  fixtures :agent_statuses, :agents

  describe "authentication" do
    after(:each) do
      agents(:quentin).update_attributes(:username => 'quentin', :password => 'test', :password_confirmation => 'test')      
    end
    
    it 'authenticates' do
      Agent.authenticate('quentin', 'test').should == agents(:quentin)
    end
  
    it 'works with reset password' do
      agents(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
      Agent.authenticate('quentin', 'new password').should == agents(:quentin).reload
    end

    it 'does not rehash password' do
      agents(:quentin).update_attributes(:username => 'quentin2', :password => 'test', :password_confirmation => 'test')
      Agent.authenticate('quentin2', 'test').should == agents(:quentin)
    end
  end

  it 'sets remember token' do
    agents(:quentin).remember_me
    agents(:quentin).remember_token.should_not be_nil
    agents(:quentin).remember_token_expires_at.should_not be_nil
  end

  it 'unsets remember token' do
    agents(:quentin).remember_me
    agents(:quentin).remember_token.should_not be_nil
    agents(:quentin).forget_me
    agents(:quentin).remember_token.should be_nil
  end

  it 'remembers me for one week' do
    before = 1.week.from_now.utc
    agents(:quentin).remember_me_for 1.week
    after = 1.week.from_now.utc
    agents(:quentin).remember_token.should_not be_nil
    agents(:quentin).remember_token_expires_at.should_not be_nil
    agents(:quentin).remember_token_expires_at.between?(before, after).should be_true
  end

  it 'remembers me until one week' do
    time = 1.week.from_now.utc
    agents(:quentin).remember_me_until time
    agents(:quentin).remember_token.should_not be_nil
    agents(:quentin).remember_token_expires_at.should_not be_nil
    agents(:quentin).remember_token_expires_at.should == time
  end

  it 'remembers me default two weeks' do
    before = 2.weeks.from_now.utc
    agents(:quentin).remember_me
    after = 2.weeks.from_now.utc
    agents(:quentin).remember_token.should_not be_nil
    agents(:quentin).remember_token_expires_at.should_not be_nil
    agents(:quentin).remember_token_expires_at.between?(before, after).should be_true
  end
  
  describe "overall agreement validation" do
    
    it "should be ready for agreement when they enter enough info" do 
      agent=Agent.new(:project_name=>'Project')
      agent.agent_contacts << mock_model(AgentContact)
      agent.content_partner = mock_model(ContentPartner,'partner_complete_step?'=>true,'ipr_accept?'=>true,'attribution_accept?'=>true,'roles_accept?'=>true)
      agent.terms_agreed_to?.should be_true
      agent.ready_for_agreement?.should be_true
    end

    it "should not be ready for agreement before all info is entered and agreements are made" do
      agent=Agent.new(:project_name=>'Project')
      agent.agent_contacts << mock_model(AgentContact)
      agent.content_partner = mock_model(ContentPartner,'partner_complete_step?'=>false,'ipr_accept?'=>false,'attribution_accept?'=>true,'roles_accept?'=>true)
      agent.terms_agreed_to?.should_not be_true
      agent.ready_for_agreement?.should_not be_true
    end
        
  end  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: agents
#
#  id                        :integer(4)      not null, primary key
#  agent_status_id           :integer(1)      not null
#  acronym                   :string(20)      not null
#  display_name              :string(255)     not null
#  email                     :string(75)      not null
#  full_name                 :string(255)     not null
#  hashed_password           :string(100)     not null
#  homepage                  :string(255)     not null
#  logo_content_type         :string(255)
#  logo_file_name            :string(255)
#  logo_file_size            :integer(4)      default(0)
#  logo_url                  :string(255)
#  remember_token            :string(255)
#  username                  :string(100)     not null
#  created_at                :timestamp       not null
#  remember_token_expires_at :timestamp
#  updated_at                :timestamp       not null

