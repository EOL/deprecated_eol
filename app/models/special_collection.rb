class SpecialCollection < ActiveRecord::Base

  has_many :lists

  def self.create_all
    self.create(:name => 'Task')
    self.create(:name => 'Like')
    self.create(:name => 'Focus')
  end

  def self.task
    cached_find(:name, 'Task')
  end

  def self.like
    cached_find(:name, 'Like')
  end

  def self.focus # This is a community's focus collection
    cached_find(:name, 'Focus')
  end

end
