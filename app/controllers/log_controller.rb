# Implements browser object logging requests. This code is inteded to create +DataObjectLog+ objects based on parameters reported by the browser. 
#
# Author: Preston Lee <preston.lee@openrain.com>
class LogController < ApplicationController

  layout 'main'

  def index
    # Redirect to the homepage.
    redirect_to :controller => 'content'
  end
  
  def data_object 
    raise 'Not yet implemented!'
    ids = params.keys
    if ids.size > 0
      params.each do |k,v|
        # TODO Implement client-requested logging.
      end
    else
      # Nothing to do
    end
  end

end
