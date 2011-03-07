class Task < ActiveRecord::Base
  belongs_to :task_name
  belongs_to :task_state
  belongs_to :target, :polymorphic => true
  belongs_to :created_by_user, :class_name => 'User'
  belongs_to :owner_user, :class_name => 'User'

  after_create :update_task_name_frequency

private

  def update_task_name_frequency
    task_name.update_frequency
  end

end
