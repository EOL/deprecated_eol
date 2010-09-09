module CuratorsHelper

  def active_if_action_is(action)
    controller.action_name == action ? 'active' : ''
  end

end
