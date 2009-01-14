class AddNewRolesAndRightsForCuratorAdmin < ActiveRecord::Migration
  def self.up
 #   Right.create(:title=>'Curator Administrator',:controller=>'curator')    
 #   Role.find_by_title('Administrator - Web Users').rights << Right.find_by_title('Curator Administrator')
#    Right.create(:title=>'Tag Suggestion Administrator',:controller=>'tag_suggestion')    
  #  Role.find_by_title('Administrator - Site CMS').rights << Right.find_by_title('Tag Suggestion Administrator')
  end

  def self.down
  #  right=Right.find_by_title('Curator Administrator')
  #  Role.find_by_title('Administrator - Web Users').rights.delete(right)
  #  Right.destroy(right.id)
  #  right=Right.find_by_title('Tag Suggestion Administrator')
  #  Role.find_by_title('Administrator - Site CMS').rights.delete(right)
  #  Right.destroy(right.id)
  end
end
