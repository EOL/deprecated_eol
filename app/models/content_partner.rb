# This is a special kind of Agent (the relationship is mandatory; q.v.).  A ContentPartner is akin to a User, in that they can log
# in (see ContentPartnerController).  Of course, content partners are those people or organizations who add data to our database.
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
  
  def self.find_by_full_name(full_name)
    content_partners = ContentPartner.find_by_sql([%Q{
        SELECT cp.*
        FROM agents a
        JOIN content_partners cp ON (a.id=cp.agent_id)
        WHERE a.full_name=? }, full_name])
    
    return nil if content_partners.nil?
    content_partners[0]
  end
  
  def self.find_harvested_by_full_name(full_name)
    content_partners = ContentPartner.find_by_sql([%Q{
        SELECT cp.*
        FROM agents a
        JOIN content_partners cp ON (a.id=cp.agent_id)
        JOIN agents_resources ar ON (a.id=ar.agent_id)
        JOIN resources r ON (ar.resource_id=r.id)
        JOIN harvest_events he ON (r.id=he.resource_id)
        WHERE a.full_name=? }, full_name])
    
    return nil if content_partners.nil?
    content_partners[0]
  end
  
  def concepts_for_gallery(page, per_page)
    page = page - 1
    partner_resources = Resource.find_by_sql(%Q{
        SELECT
        r.*
        FROM agents_resources ar
        JOIN resources r ON (ar.resource_id=r.id)
        WHERE ar.agent_id=#{agent_id}
        AND ar.resource_agent_role_id=#{ResourceAgentRole.content_partner_upload_role.id}})
    
    return nil if partner_resources.nil?
    harvest_event_ids = partner_resources.collect{|r| r.latest_published_harvest_event.id || nil }
    return nil if harvest_event_ids.empty?
    
    count_result = SpeciesSchemaModel.connection.execute(%Q{
        SELECT count(distinct t.hierarchy_entry_id) count
        FROM harvest_events_taxa het
        JOIN taxa t ON (het.taxon_id=t.id)
        LEFT JOIN resources_taxa rt ON (t.id=rt.taxon_id)
        WHERE het.harvest_event_id IN (#{harvest_event_ids.join(',')})}).all_hashes
    total_taxa_count = count_result[0]['count'].to_i
    
    sorted_hierarchy_entries = SpeciesSchemaModel.connection.execute(%Q{
        SELECT t.hierarchy_entry_id, rt.source_url
        FROM harvest_events_taxa het
        JOIN taxa t ON (het.taxon_id=t.id)
        LEFT JOIN resources_taxa rt ON (t.id=rt.taxon_id)
        WHERE het.harvest_event_id IN (#{harvest_event_ids.join(',')})
        GROUP BY t.hierarchy_entry_id
        ORDER BY t.scientific_name LIMIT #{page*per_page}, #{per_page} }).all_hashes
    
    start_index = page * per_page
    end_index = start_index + per_page
    
    all_concepts = []
    for i in 0...total_taxa_count
      all_concepts[i] = {}
      if i >= start_index && i < end_index 
        
        entry = sorted_hierarchy_entries[i-start_index]
        name_and_image = SpeciesSchemaModel.connection.execute("SELECT he.taxon_concept_id, n.string, do.object_cache_url
          FROM hierarchy_entries he
          JOIN names n ON (he.name_id=n.id)
          LEFT JOIN (
            top_images ti
            JOIN data_objects do ON (ti.data_object_id=do.id AND ti.view_order=1)
          ) ON (he.id=ti.hierarchy_entry_id)
          WHERE he.id=#{entry['hierarchy_entry_id']} LIMIT 1").all_hashes
        
        all_concepts[i]['id'] = name_and_image[0]['taxon_concept_id']
        all_concepts[i]['name_string'] = name_and_image[0]['string']
        all_concepts[i]['partner_source_url'] = entry['source_url']
        if name_and_image[0] && !name_and_image[0]['object_cache_url'].nil?
          all_concepts[i]['image_src'] = DataObject.image_cache_path(name_and_image[0]['object_cache_url'], :medium)
        else
          all_concepts[i]['image_src'] = '/images/eol_logo_gray.gif'
        end
      end
    end
    
    all_concepts
  end
  
  # has this agent submitted data_objects which are currently published
  def has_published_resources?
    has_resources = SpeciesSchemaModel.connection.execute(%Q{
        SELECT 1
        FROM agents a
        JOIN agents_resources ar ON (a.id=ar.agent_id)
        JOIN harvest_events he ON (ar.resource_id=he.resource_id)
        WHERE ar.agent_id=#{agent_id} AND he.published_at IS NOT NULL LIMIT 1}).all_hashes
    return !has_resources.empty?
  end
  
  def data_objects_actions_history
    
    latest_published_harvest_event_ids = []
    agent.resources.each do |r|
      if he = r.latest_published_harvest_event
        latest_published_harvest_event_ids << he.id
      end
    end
    return [] if latest_published_harvest_event_ids.empty?
    
    objects_history = ActionsHistory.find_by_sql(%Q{
      SELECT ah.*, do.data_type_id, dt.label data_object_type_label, 'data_object' history_type
      FROM #{DataObjectsHarvestEvent.full_table_name} dohe
      JOIN #{DataObject.full_table_name} do ON (dohe.data_object_id=do.id)
      JOIN #{DataType.full_table_name} dt ON (do.data_type_id=dt.id)
      JOIN #{ActionsHistory.full_table_name} ah ON (do.id=ah.object_id)
      WHERE dohe.harvest_event_id IN (#{latest_published_harvest_event_ids.join(',')})
      AND ah.changeable_object_type_id=#{ChangeableObjectType.find_by_ch_object_type('data_object').id}
    }).uniq
    
    objects_history.sort! do |a,b|
      b.created_at <=> a.created_at
    end
  end
  
  def comments_actions_history
    
    latest_published_harvest_event_ids = []
    agent.resources.each do |r|
      if he = r.latest_published_harvest_event
        latest_published_harvest_event_ids << he.id
      end
    end
    return [] if latest_published_harvest_event_ids.empty?
    
    comments_history = ActionsHistory.find_by_sql(%Q{
      SELECT ah.*, do.data_type_id, dt.label data_object_type_label, c.body comment_body, 'comment' history_type
      FROM #{DataObjectsHarvestEvent.full_table_name} dohe
      JOIN #{DataObject.full_table_name} do ON (dohe.data_object_id=do.id)
      JOIN #{DataType.full_table_name} dt ON (do.data_type_id=dt.id)
      JOIN #{Comment.full_table_name} c ON (do.id=c.parent_id)
      JOIN #{ActionsHistory.full_table_name} ah ON (c.id=ah.object_id)
      WHERE dohe.harvest_event_id IN (#{latest_published_harvest_event_ids.join(',')})
      AND ah.changeable_object_type_id=#{ChangeableObjectType.find_by_ch_object_type('comment').id}
    }).uniq
    
    comments_history.sort! do |a,b|
      b.created_at <=> a.created_at
    end
  end
  
  # the date of the last action taken (the last time a contact was updated, or a step was viewed, or a resource was added/edited/published)
  def last_action
    dates_to_compare=[self.partner_seen_step,self.partner_complete_step,self.contacts_seen_step,self.contacts_complete_step,self.licensing_seen_step,self.licensing_complete_step,self.attribution_seen_step,self.attribution_complete_step,self.roles_seen_step,self.roles_complete_step,self.transfer_overview_seen_step,self.transfer_overview_complete_step,self.transfer_upload_seen_step,self.transfer_upload_complete_step]
    resources=self.agent.resources.compact!
    if resources
      dates_to_compare << resources.sort_by{ |m| m.created_at }[0].created_at 
    end
    dates_to_compare.compact!
    if dates_to_compare
      dates_to_compare.sort[0]
    else
      nil
    end
  end
  
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

