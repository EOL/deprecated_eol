#It's all about tracking of users activity (create/delete comment, create/delete_tag, curate = {trusted, untrusted, show, hide, inappropriate}, ...)
# to use in data_object, comment and data_object_tags
# TODO: move here "curator_activity_flag" from these models

module UserActions
  
  def new_actions_histories(user, object, changeable_object_type, action)
    #e.g. changeable_object_type = "comment", action = "create"    
    
    action_with_object_id     = ActionWithObject.find_by_action_code(action).id
    changeable_object_type_id =
          ChangeableObjectType.find_by_ch_object_type(changeable_object_type).id
        
    ActionsHistory.create(:user_id                   => user.id, 
                          :object_id                 => object.id,
                          :changeable_object_type_id => changeable_object_type_id,
                          :action_with_object_id     => action_with_object_id,
                          :created_at                => Time.now,
                          :updated_at                => Time.now
                         )
    
  end
    
end

