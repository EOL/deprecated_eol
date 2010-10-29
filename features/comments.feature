Feature: Describe Commenting
  As an anonymous visitor
  I should be able to view comments for data objects and taxon pages
  As an authenticated visitor
  I should be able to view, add and edit comments for data objects and taxon pages

  Scenario: I should be able to see comment links on taxon page
    When I go to Honey bee page
    Then I should see a comments tab
    And I should see a comment button for the main image
    And I should see a comment button for text objects
  
  @javascript
  Scenario: I should be able to see taxon page comments
    When I go to Honey bee page
    And I follow a comments tab
    Then I should see a comments section
    And I should see a comment button for text objects

#  @javascript
#  Scenario: I should be able to see the main image comments
#    When I go to Honey bee page
#    And I follow a comment button for the main image
#    Then I should see comments section
#    
#    And 
