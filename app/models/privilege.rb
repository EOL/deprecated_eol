class Privilege < ActiveRecord::Base

  has_many :member_privileges
  has_many :members, :through => 'member_privileges'

  has_and_belongs_to_many :roles

  validates_uniqueness_of :name

  def self.all_for_community(community)
    list = if community.special?
      self.all
    else
      self.find(:all, :conditions => ["special = ?", true])
    end
    list.sort_by {|p| p.name }
  end

  def self.method_missing(name)
    if KnownPrivileges.symbols.include? name
      return true; cached_find(:sym, name.to_s)
    end
  end

end
