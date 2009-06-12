class ActionsHistory < ActiveRecord::Base

  belongs_to :user
  belongs_to :changeable_object_types
  belongs_to :action_with_object
  
  validates_presence_of :user_id, :changeable_object_type_id, :action_with_object_id, :created_at 

  #why method_from_user doesn't work?
  def act_user                                                                                                               
    User.find(user_id)                                                                                         
  end    
  
  def action_w_object
    ActionWithObject.find(action_with_object_id)
  end           
         
  def taxon_name
    case changeable_object_type_id  
      when 1: 
      #data_object
        taxon_name = data_object.taxa_names_taxon_concept_ids[0][:taxon_name]
      when 2: 
      #comment
        if comment_parent.user.nil?
          taxon_name = comment_parent.taxa_names_taxon_concept_ids[0][:taxon_name]
        else
          taxon_name = comment_parent.taxon_concept_for_users_text.name
        end
      when 4:
        taxon_name = udo_taxon_concept.name
      end
    return taxon_name   
  end
      
  def taxon_id
    case changeable_object_type_id  
      when 1: 
      #data_object
        taxon_id = data_object.taxon_ids[0]
      when 2: 
      #comment
        if comment_parent.user.nil?
          taxon_id = comment_object.taxon_concept_id
        else
          taxon_id = comment_parent.taxon_concept_for_users_text.id
        end 
      when 4:
      #users_data_object
        taxon_id = udo_taxon_concept.id
    end
    return taxon_id
  end
  
  def long_string(l_string)
    n = 7 #chop too long text
    if l_string.size > n
      if l_string[n-1] == 32 #space " "
        n -= 1 
      end
      l_string[0, n].to_s+"..."
    else
      l_string
    end
  end
  #truncate("Once upon a time in a world far far away", :length => 14)
       
  #-------- data_object ---------
         
  def data_object 
    DataObject.find(object_id)
  end
    
  def data_object_type
    data_object.data_type.label
  end
                   
  def toc_label
    data_object.toc_items[0].label 
  end  

  #-------- comment ---------
  
  def comment_object
    Comment.find(object_id)
  end         
  
  def comment_parent
     DataObject.find(comment_object.parent_id)
  end

  #-------- users_data_object ---------

  def users_data_object
    UsersDataObject.find(object_id)
  end
  
  def udo_parent_text
    DataObject.find(users_data_object.data_object_id)
  end
     
  def udo_taxon_concept
    TaxonConcept.find(users_data_object.taxon_concept_id)
  end
    
end

# == Schema Info
# Schema version: 20090609183650_create_actions_histories
#
# Table name: actions_histories
#
# id                        :integer(11)  not null, primary key
# user_id                   :integer(11)  
# changeable_object_type_id :integer(11)  
# action_with_object_id     :integer(11)  
# created_at                :timestamp                   
# updated_at                :timestamp
