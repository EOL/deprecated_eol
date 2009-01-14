# See notes in "Agent" model.
class ContentPartner < SpeciesSchemaModel
    
  belongs_to :agent
    
  unless defined? STEPS
    STEPS = [:partner, :contacts, :licensing, :attribution, :roles, :transfer_overview, :transfer_upload, :specialist_overview, :specialist_formatting] 
    STEPS.each { |s| define_method("#{s}_step?") { self.step.to_s == s.to_s }}
  end

  attr_reader :step

  # Alias some partner fields so we can use validation helpers
  alias_attribute :project_description, :description
  
  validate :validate_atleast_one_contact, :if => :contacts_step?
  # REMOVE VALIDATION FOR THESE STEPS TO ALLOW PEOPLE TO 'UNACCEPT', Peter Mangiafico, Sep 12, 2008
  #validate :validate_ipr_acceptance, :if => :licensing_step?  
  #validate :validate_attribution_acceptance, :if => :attribution_step?
  #validate :validate_roles_acceptance, :if => :roles_step?

  # Callbacks
  before_save :blank_not_null_fields
  
  def step=(new_step)
    @step = new_step.to_sym
    
    # Store when the user has first 'seen' this step
    seen_method = "#{step}_seen_step"
    if !self.send("#{seen_method}?") && !new_record?
      update_attribute(seen_method, Time.now.utc)
    end
  end
    
  # This was in a callback but just caused too many issues.
  def log_completed_step!
    step_method = "#{@step}_complete_step"
    if self.respond_to?(step_method)
      #self.send("#{step_method}=", Time.now.utc)
      self.update_attribute(step_method.to_sym, Time.now.utc)
    end
    if self.agent.ready_for_agreement? && eol_notified_of_acceptance.nil?
       Notifier::deliver_agent_is_ready_for_agreement(self.agent, $CONTENT_PARTNER_REGISTRY_EMAIL_ADDRESS)
       self.update_attribute(:eol_notified_of_acceptance,Time.now.utc)
    end  
  end
  
    # Called when contact_step? is true
    def validate_atleast_one_contact
      errors.add_to_base('You must have at least one contact') unless self.agent.agent_contacts.any?
    end

    # Called when licensing_step? is true
    def validate_ipr_acceptance
     errors.add_to_base('You must accept the EOL Licensing Policy') unless self.ipr_accept.to_i == 1
    end
    
    # Called when attribution_step? is true
    def validate_attribution_acceptance
      errors.add_to_base('You must accept the EOL Attribution Guidelines') unless self.attribution_accept.to_i == 1      
    end
    
    # Called when roles_step? is true
    def validate_roles_acceptance
      errors.add_to_base('You must accept the EOL Roles Guidelines') unless self.roles_accept.to_i == 1      
    end
    
    def roles_accept?
      EOLConvert.to_boolean(roles_accept)
    end
    
    def ipr_accept?
      EOLConvert.to_boolean(ipr_accept)
    end
    
    def attribution_accept?
      EOLConvert.to_boolean(attribution_accept)
    end
    
    def transfer_schema_accept?
      EOLConvert.to_boolean(transfer_schema_accept)
    end

    # vet or unvet entire content partner (0 = unknown, 1 = vet)
    def set_vetted_status(vetted) 
      set_to_state = EOLConvert.to_boolean(vetted) ? Vetted.trusted.id : Vetted.unknown.id
      SpeciesSchemaModel.connection.execute("update data_objects d, data_objects_harvest_events dh, harvest_events h, agents_resources ar set d.vetted_id = #{set_to_state} where d.curated = 0 and  d.id = dh.data_object_id and dh.harvest_event_id = h.id and h.resource_id =  ar.resource_id and ar.agent_id=#{self.agent.id}")
      self.vetted=vetted
    end
    
    # Set these fields to blank because insistence on having NOT NULL columns on things that aren't populated
    # until certain steps.
    def blank_not_null_fields
      self.notes ||= ""
      self.description_of_data ||= ""
      self.description ||=""
    end
    
end# == Schema Info
# Schema version: 20080922224121
#
# Table name: content_partners
#
#  id                                  :integer(4)      not null, primary key
#  agent_id                            :integer(4)      not null
#  attribution_accept                  :integer(1)      not null, default(0)
#  attribution_complete_step           :timestamp
#  attribution_seen_step               :timestamp
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
#  partner_vetted                      :integer(1)      not null, default(0)
#  roles_accept                        :integer(1)      not null, default(0)
#  roles_complete_step                 :timestamp
#  roles_seen_step                     :timestamp
#  specialist_formatting_complete_step :timestamp
#  specialist_formatting_seen_step     :timestamp
#  specialist_overview_complete_step   :timestamp
#  specialist_overview_seen_step       :timestamp
#  transfer_overview_complete_step     :timestamp
#  transfer_overview_seen_step         :timestamp
#  transfer_schema_accept              :integer(1)      not null, default(0)
#  transfer_upload_complete_step       :timestamp
#  transfer_upload_seen_step           :timestamp
#  created_at                          :timestamp       not null
#  updated_at                          :timestamp       not null

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

