class ActionsHistory < ActiveRecord::Base

  belongs_to :user
  belongs_to :changeable_object_types
  belongs_to :action_with_object
  
  validates_presence_of :user_id, :changeable_object_type_id, :action_with_object_id, :created_at 
    
  def taxon_concept_name
    case changeable_object_type_id  
      when ChangeableObjectType.data_object.id: 
        taxon_concept_name = data_object.taxa_names_taxon_concept_ids[0][:taxon_name]
      when ChangeableObjectType.comment.id: 
        if comment_object.parent_type == 'TaxonConcept'
          taxon_concept_name = comment_parent.scientific_name
        elsif comment_object.parent_type == 'DataObject'
          if comment_parent.user.nil?
            taxon_concept_name = comment_parent.taxa_names_taxon_concept_ids[0][:taxon_name]
          else
            taxon_concept_name = comment_parent.taxon_concept_for_users_text.name
          end
        end
      when ChangeableObjectType.tag.id:    
        # We don't count these right now, but we don't want to raise an exception.
      when ChangeableObjectType.users_submitted_text.id:
        taxon_concept_name = udo_taxon_concept.name
      else 
        raise "Don't know how to get taxon name from a changeable object type of id #{changeable_object_type_id}"
      end
    return taxon_concept_name   
  end
      
  def taxon_concept_id
    case changeable_object_type_id  
      when ChangeableObjectType.data_object.id: 
      #data_object
        taxon_concept_id = data_object.taxa_names_taxon_concept_ids[0][:taxon_concept_id]
      when ChangeableObjectType.comment.id: 
      #comment
        if comment_object.parent_type == 'TaxonConcept'
          taxon_concept_id = comment_parent.id
        else
          if comment_parent.user.nil?
            taxon_concept_id = comment_object.taxon_concept_id
          else
            taxon_concept_id = comment_parent.taxon_concept_for_users_text.id
          end 
        end
      when 4:
      #users_data_object
        taxon_concept_id = udo_taxon_concept.id
      else
        raise "Don't know how to get the taxon id from a changeable object type of id #{changeable_object_type_id}"
    end
    return taxon_concept_id
  end
           
  #-------- data_object ---------
         
  def data_object 
    DataObject.find(self['object_id'])
  end
    
  def data_object_type
    data_object.data_type.label
  end
                   
  def toc_label
    data_object.toc_items[0].label 
  end  

  #-------- comment ---------
  
  def comment_object
    Comment.find(self['object_id'])
  end        
  
  def comment_parent
    return_comment_parent = case comment_object.parent_type
     when 'TaxonConcept' then TaxonConcept.find(comment_object.parent_id)
     when 'DataObject'   then DataObject.find(comment_object.parent_id)
     else raise "Cannot comment on #{comment_object.parent_type.to_s.pluralize}"
    end
    return return_comment_parent    
  end 
  
  #-------- users_data_object ---------

  def users_data_object
    UsersDataObject.find(self['object_id'])
  end
  
  def udo_parent_text
    DataObject.find(users_data_object.data_object_id)
  end
     
  def udo_taxon_concept
    TaxonConcept.find(users_data_object.taxon_concept_id)
  end
end
