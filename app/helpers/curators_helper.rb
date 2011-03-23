module CuratorsHelper

  def active_if_action_is(action, id = nil)
    if id.nil?
      controller.action_name == action ? 'active' : ''
    else
      (controller.action_name == action) && (id == controller.params[:id]) ? 'active' : ''
    end
  end

end
