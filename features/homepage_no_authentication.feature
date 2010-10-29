Feature: Describe home page
  As a visitor without login
  I should be able to look at the homepage
  So I can start using EOL
  
  Scenario: Visiting the home page
    When I go to the home page
    Then I should see "Encyclopedia of Life" within "title"
    And I should see "login" within "#personal-space"
    And I should see "create an account" within "#personal-space"
    And I should see "EOL Announcements" within "#sidebar-a h1"
    And I should see "What's New?" within "#sidebar-b h1"

  Scenario: Redirect from admin page
    When I go to the admin page
    Then I should be on the login page

  @javascript
  Scenario: Should change images
    When I go to the home page
    And look at images gallery
    And wait for 30 seconds
    And look at images gallery
    Then I see that some images are different

