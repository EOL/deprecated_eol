class SurveyResponse < ActiveRecord::Base

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: survey_responses
#
#  id            :integer(4)      not null, primary key
#  taxon_id      :string(255)
#  user_id       :integer(4)
#  ip_address    :string(255)
#  user_agent    :string(100)
#  user_response :string(255)
#  created_at    :datetime
#  updated_at    :datetime

