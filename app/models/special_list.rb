class SpecialList < ActiveRecord::Base

  has_many :lists

  def self.create_all
    self.create(:name => 'Task')
    self.create(:name => 'Like')
    self.create(:name => 'Taxa')
  end

  def self.task
    cached_find(:name, 'Task')
  end

  def self.like
    cached_find(:name, 'Like')
  end

  def self.taxa # This is a community's taxa list.
    cached_find(:name, 'Taxa')
  end

end
