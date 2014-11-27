class HarvestProcessLog < ActiveRecord::Base
  
  scope :harvesting, -> { where(process_name: "Harvesting").order(:id) }
  
  def complete?
    ! completed_at.nil?
  end
  
end
