class TaskName < ActiveRecord::Base

  has_many :tasks

  def update_frequency
    self.frequency = self.tasks.count
    save!
  end

end
