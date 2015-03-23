# This is a class used by Tramea.
# This is a join table, as you may have guessed.
class CommonNamesSummary < ActiveRecord::Base
  belongs_to :common_name
  belongs_to :summary
end
