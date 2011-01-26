class SpecialList < ActiveRecord::Base

  has_many :lists

  def self.create_all
    # There should be regional-specific scripts to rename the 'name' attribute on these; the sym stays the same, regadless of
    # language.
    self.create(:name => 'Task', :sym => 'task')
    self.create(:name => 'Like', :sym => 'like')
    self.create(:name => 'Taxa', :sym => 'taxa')
  end

  def self.task
    cached_find(:sym, 'task')
  end

  def self.like
    cached_find(:sym, 'like')
  end

  def self.taxa # This is a community's taxa list.
    cached_find(:sym, 'taxa')
  end

end
