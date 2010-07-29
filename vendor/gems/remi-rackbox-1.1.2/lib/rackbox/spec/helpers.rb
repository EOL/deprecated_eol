class RackBox

  # Helper methods to include in specs that want to use blackbox testing
  #
  # TODO For backwards compatibility, I would like to keep a SpecHelpers
  #      module, but this needs to be renamed because this isn't spec 
  #      specific at all!  it needs to be easy to RackBox::App.new(rack_app).request
  #      or something like that (something generic)
  #
  # This module has the RackBox::SpecHelpers#request method, which is 
  # the main method used by RackBox blackbox tests
  #
  module SpecHelpers

    # moved logic into RackBox#request, where it can easily be re-used
    def req url, options = {}
      RackBox.request @rackbox_request, url, options
    end

    alias request req unless defined? request

  end
end
