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
    Then the add text panel should be shown
    And I should see a login link within the add text panel
    And I should see a close button within the add text panel
    But I should not see an add text form within the add text panel
    When I follow the close button within the add text panel
    And I wait 1 second
    Then the add text panel should be hidden
    When I follow the add new content link within the table of contents
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
    When I go to the Honey bee page
    And I follow the add text button within the text object header
    And I wait 1 second
    Then I should see an add text form within the add text panel
    And I should see an add text category field within the add text form
    And I should see an add text title field within the add text form
    And I should see an add text description field within the add text form
    And I should see an add text language field within the add text form
    And I should see an add text license field within the add text form
    And I should see an add text references field within the add text form
    When I press "Preview" within the add text form
    Then the missing text error message should be shown
    When I press "Confirm" within the add text form
    Then the missing text error message should be shown
    When I fill in "Text" with "My new text item." within the add text form
    And I press "Preview" within the add text form
    Then I should see "My new text item." within the text object content
    And I should see the member's name within the text object content
    When I press "Confirm" within the add text form
    Then I should see "My new text item." within the text object content
    And I should see the member's name within the text object content
    And I should see an edit text link within the text object content
    Then I logout
