class CollectionEndorsement < ActiveRecord::Base

  belongs_to :collection
  belongs_to :community
  belongs_to :member # The member of the community who endorsed it.

  validates_presence_of :collection_id
  validates_presence_of :community_id
  validates_uniqueness_of :community_id, :scope => :collection_id

  def endorsed?
    member
  end

  def pending?
    member.nil?
  end

  def endorsed_by(mem)
    raise EOL::Exceptions::SecurityViolation.new("This member cannot endorse collections.") unless mem.manager?
    update_attribute(:member_id, mem.id)
  end

end
