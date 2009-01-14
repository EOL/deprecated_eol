require File.dirname(__FILE__) + '/../spec_helper'

def create_agent(options={})
  @agent = mock_model(Agent)
  @agent.stub!(:ready_for_agreement?).and_return(false)
  @agent.stub!(:terms_agreed_to?).and_return(false)
end

def create_content_partner(options = {})
  create_agent
  content_partner=ContentPartner.create(options.merge(:agent_id => @agent.id))
  content_partner.agent = @agent
  return content_partner
end

describe ContentPartner do

  describe "step logic" do
    it "should log time if a step was seen for the first time" do
      @content_partner = create_content_partner()      
      @content_partner.partner_seen_step.should be_nil
      @content_partner.step = :partner
      @content_partner.reload
      @content_partner.partner_seen_step.should_not be_nil
    end
    
    it "should log time of a completed step" do
      @content_partner = create_content_partner(:ipr_accept => true)
      @content_partner.step = :licensing
      lambda { 
        @content_partner.log_completed_step!
      }.should change(@content_partner, :licensing_complete_step)
    end    
  end

  describe "in contacts step" do
    it "should require at least one contact" do
      @content_partner = create_content_partner(:last_completed_step => 'partner')
      @agent.should_receive(:agent_contacts).and_return([])
      @content_partner.step = :contacts
      @content_partner.should_not be_valid
      @content_partner.errors.full_messages.select { |e| e =~ /one contact/ }.any?.should == true
    end
  end
  
  describe "in licensing step" do
    before(:each) do
      @content_partner = create_content_partner(:last_completed_step => 'contacts')
      @content_partner.step = :licensing
      @content_partner.should be_valid
    end
    
    it "should not require acceptance of ipr_accept" do
      @content_partner.errors.full_messages.select { |e| e =~ /licensing/i }.any?.should == false
    end    
  end
  
  describe "in attribution step" do
    before(:each) do
      @content_partner = create_content_partner(:last_completed_step => 'licensing')
      @content_partner.step = :attribution
      @content_partner.should be_valid
    end

    it "should not require acceptance of attribution_accept" do
      @content_partner.errors.full_messages.select { |e| e =~ /guideline/i }.any?.should == false
    end
  end
  
  describe "in roles step" do
    before(:each) do
      @content_partner = create_content_partner(:last_completed_step => 'attribution')
      @content_partner.step = :roles
      @content_partner.should be_valid
    end

    it "should not require acceptance of roles_accept" do
      @content_partner.errors.full_messages.select { |e| e =~ /guideline/i }.any?.should == false
    end    
  
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: content_partners
#
#  id                                  :integer(4)      not null, primary key
#  agent_id                            :integer(4)      not null
#  attribution_accept                  :integer(1)      not null, default(0)
#  attribution_complete_step           :timestamp
#  attribution_seen_step               :timestamp
#  auto_publish                        :boolean(1)      not null
#  contacts_complete_step              :timestamp
#  contacts_seen_step                  :timestamp
#  description                         :text            not null
#  description_of_data                 :text
#  eol_notified_of_acceptance          :datetime
#  ipr_accept                          :integer(1)      not null, default(0)
#  last_completed_step                 :string(40)
#  licensing_complete_step             :timestamp
#  licensing_seen_step                 :timestamp
#  notes                               :text            not null
#  partner_complete_step               :timestamp
#  partner_seen_step                   :timestamp
#  roles_accept                        :integer(1)      not null, default(0)
#  roles_complete_step                 :timestamp
#  roles_seen_step                     :timestamp
#  show_on_partner_page                :boolean(1)      not null
#  specialist_formatting_complete_step :timestamp
#  specialist_formatting_seen_step     :timestamp
#  specialist_overview_complete_step   :timestamp
#  specialist_overview_seen_step       :timestamp
#  transfer_overview_complete_step     :timestamp
#  transfer_overview_seen_step         :timestamp
#  transfer_schema_accept              :integer(1)      not null, default(0)
#  transfer_upload_complete_step       :timestamp
#  transfer_upload_seen_step           :timestamp
#  vetted                              :integer(1)      not null, default(0)
#  created_at                          :timestamp       not null
#  updated_at                          :timestamp       not null

