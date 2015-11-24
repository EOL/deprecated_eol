# Some rows have been archived. See the Jira ticket
# https://jira.eol.org/browse/DEVOPS-76 for more information. What remains is
# what is needed for daily use such as harvesting and showing the content
# partner web pages. All other rows are in archived tables.
class DataObjectsHarvestEvent < ActiveRecord::Base
  self.primary_keys = :data_object_id, :harvest_event_id

  belongs_to :harvest_event
  belongs_to :data_object
  belongs_to :status
end
