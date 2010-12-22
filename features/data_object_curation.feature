Feature: Describe curation of an object
  As a curator
  I should be able to open data object curation interface
  And change its curation status
  
  @javascript
  Scenario: I should be able to untrust an object, and select reasons why the object is untrusted
    Given I am logged in as a curator
    When I go to Honey bee page
    Then I should see a image curation icon
    When I press the image curation icon within main image icons area
    Then I should see the data object curation menu
    # When I press the untrusted radio button
    # Then I should see untrusted reasons within data object curation menu
