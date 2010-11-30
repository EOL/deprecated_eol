module UserHelpers

  def get_user(user_type_or_name)
    case user_type_or_name
    when 'member'
      username = 'cucumber_member'
    when 'curator'
      username = 'cucumber_curator'
    else
      username = user_type_or_name
    end

    user = User.find_by_username(username)
    user.entered_password = username
    user
  end

end

World(UserHelpers)
