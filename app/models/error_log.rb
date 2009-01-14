class ErrorLog < ActiveRecord::Base

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: error_logs
#
#  id             :integer(4)      not null, primary key
#  user_id        :integer(4)
#  backtrace      :text
#  exception_name :string(250)
#  ip_address     :string(255)
#  url            :string(250)
#  user_agent     :string(100)
#  created_at     :datetime
#  updated_at     :datetime

