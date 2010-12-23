require 'core_extensions' # Oddly, these aren't loaded in time for tests, and they are needed here for ACLs.
class Privilege < ActiveRecord::Base

  has_many :member_privileges
  has_many :members, :through => 'member_privileges'

  has_and_belongs_to_many :roles

  validates_uniqueness_of :name

  def self.all_for_community(community)
    list = if community.special?
      self.all
    else
      self.find(:all, :conditions => ["special = ?", false])
    end
    list.sort_by {|p| p.name }
  end

  def self.method_missing(name, *args, &block)
    if KnownPrivileges.symbols.include? name
      cached_find(:sym, name.to_s)
    else
      super(name, *args, &block)
    end
  end

end
