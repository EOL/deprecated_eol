class Privilege < ActiveRecord::Base

  has_and_belongs_to_many :roles
  has_and_belongs_to_many :members

  validates_uniqueness_of :name

  def self.all_for_community(community)
    list = if community.special?
      self.all
    else
      self.find(:all, :conditions => ["special = ?", true])
    end
    list.sort_by {|p| p.name }
  end

end
