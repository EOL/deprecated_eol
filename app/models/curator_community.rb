class CuratorCommunity < Community

  before_save :reset_name

  # Note this overrides Community#create... which is good.  There can be only one.
  def self.build
    community = Community.find_or_create_by_description_and_name($CURATOR_COMMUNITY_DESC, $CURATOR_COMMUNITY_NAME)
    # This is slow, but it is only really ever run once, so I'm going for the clearest option:
    User.curators.each do |curator|
      curator.join_community(community)
    end
    CuratorCommunity.get
  end
  
  def self.get
    cached_find(:name, $CURATOR_COMMUNITY_NAME)
  end

  def reset_name
    self.name = $CURATOR_COMMUNITY_NAME
  end

end
