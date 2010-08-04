class AddUserPrimaryRoles < ActiveRecord::Migration
  def self.up
    roles = [
      "Student (Elementary and High School)",
      "Student (Undergraduate)",
      "Student (Graduate and Post-Graduate)",
      "Educator (Elementary and High School)",
      "Educator (Undergraduate)",
      "Educator (Other)",
      "Citizen Scientist (e.g., a mushroom observer)",
      "Nature Lover (e.g., a birdwatcher)",
      "Professional Scientist (may need to segment)",
      "Professional Scientist and Curator",
      "Institutional Member - Museum",
      "Institutional Member - Nature Center",
      "Institutional Member ",
      "Data Provider",
      "Government",
      "GovernmentPrivate Industry",
      "No specific affiliation"
    ] # Note that there should also be an "Other (please complete)", but I thought that would work best on the form.
    roles.each do |role|
      UserPrimaryRole.create(:name => role)
    end
  end

  def self.down
    UserPrimaryRole.delete_all # A little scary, but...  :|
  end
end
