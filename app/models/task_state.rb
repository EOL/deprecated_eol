# TODO - i18n, using the new DB system for it.
class TaskState < ActiveRecord::Base

  has_many :tasks

  def self.create_default
    TaskState.create(:name => 'complete')
    TaskState.create(:name => 'taken')
    TaskState.create(:name => 'waiting')
  end

  def self.complete
    cached_find(:name, 'complete') # TODO - i18n
  end

  def self.taken
    cached_find(:name, 'taken') # TODO - i18n
  end

  def self.waiting
    cached_find(:name, 'waiting') # TODO - i18n
  end

end
