Feature: Describe curation of an object
  As a curator
  I should be able to open data object curation interface
  And change its curation status
  
  @javascript
  Scenario: I should be able to untrust an object, and select reasons why the object is untrusted
    Given I am logged in as a curator
    When I go to Honey bee page
    Then I should see a image curation icon
    Then I should see the trusted main image
    When I press the image curation icon within main image icons area
    Then I should see the data object curation menu
    When I press the untrusted radio button
    Then I should see untrusted reasons within data object curation menu
    When I press the misidentified untrust reason checkbox
    And I press the other untrust reason checkbox
    And I press "Save" button within data object curation menu
    And wait for 4 seconds
    Then I should see the untrusted main image
    And I it should have a new comment with "Misidentified" and "Other" for the main picture
