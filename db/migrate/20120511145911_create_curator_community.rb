class CreateCuratorCommunity < ActiveRecord::Migration
  def self.up
    Visibility.create_enumerated
    community = CuratorCommunity.build
    # I know this sucks, but... it's a requirement on the production EOL, so.....
    # Make Katja the owner of the community:
    katja = User.find(35200) rescue nil
    if katja
      katja.member_of(community).update_column(:manager, true)
    end
  end

  def self.down
    comm = CuratorCommunity.find rescue nil
    if comm
      comm.members.each { |m| m.destroy }
      comm.destroy
    end
  end
end
