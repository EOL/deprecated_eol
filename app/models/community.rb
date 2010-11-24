class Community < ActiveRecord::Base

  has_many :members

  cattr_reader :per_page
  @@per_page = 30

  validates_presence_of :name, :message => "cannot be empty."[]
  validates_length_of :name, :maximum => 127, :message => "must be less than 128 characters long."[]
  validates_uniqueness_of :name, :message => "has already been taken."[]

  def add_member(user)
    members << Member.create!(:user_id => user.id, :community_id => id)
  end

  def remove_member(user)
    member = Member.find_by_user_id_and_community_id(user.id, id)
    raise "Couldn't find a member for this user"[:could_not_find_user] unless member
    member.destroy
    self.reload
  end

  def has_member?(user)
    members.map {|m| m.user_id}.include?(user.id)
  end

end
