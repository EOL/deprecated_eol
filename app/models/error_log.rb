class ErrorLog < ActiveRecord::Base
  
  def display_backtrace
    if backtrace
      backtrace.gsub(/(\n|\", \")/,"<br />")
    else
      "There is no backtrace for this error"
    end
  end

end
