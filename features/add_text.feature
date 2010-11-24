Feature: Describe adding text
  As an anonymous visitor
  I should be able to see and select the add text buttons and links on a taxon page but not be able to add text
  As an authenticated visitor
  I should be able to see and select the add text buttons and links on a taxon page, enter text, preview text and submit text

  Scenario: I should be able to see add text buttons and links on a taxon page
    When I go to the Honey bee page
    Then I should see an add text button within the text object header
    And I should see an add new content button within the table of contents
    And I should see an add new content link within the table of contents

  @javascript
  Scenario: As an anonymous user I should not be able to add text
    When I go to the Honey bee page
    And I follow the add text button within the text object header
    And I wait 1 second
    Then the add text panel should be shown
    And I should see a login link within the add text panel
    And I should see a close button within the add text panel
    But I should not see an add text form within the add text panel
    When I follow the close button within the add text panel
    And I wait 1 second
    Then the add text panel should be hidden
    When I follow the add new content button within the table of contents
    And I wait 1 second
    Then the add text panel should be shown
    And I should see a login link within the add text panel
    And I should see a close button within the add text panel
    But I should not see an add text form within the add text panel
    When I follow the close button within the add text panel
    And I wait 1 second
    Then the add text panel should be hidden
    When I follow the add new content link within the table of contents
    And I wait 1 second
    Then the add text panel should be shown
    And I should see a login link within the add text panel
    And I should see a close button within the add text panel
    But I should not see an add text form within the add text panel
    When I follow the close button within the add text panel
    And I wait 1 second
    Then the add text panel should be hidden

  @javascript
  Scenario: As an authenticated user I should be able to add text
    Given I am logged in as a member
    Then I logout
