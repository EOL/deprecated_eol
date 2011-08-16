module AdminsHelper

  def display_admins_navigation?
    ! ((controller_name == 'content_pages' || controller_name == 'translated_content_pages') &&
      (action_name == 'new' || action_name == 'create' || action_name == 'preview' || action_name == 'edit' || action_name == 'update'))
  end

end