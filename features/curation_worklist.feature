Feature: Describe behavior of a curation worklist
  As a curator
  I should be able to browse images by their curation status
  And curate them

  @javascript
  Scenario: I should be able to trust an image
    Given I am logged in as a curator
    When I go to Honey bee page
    And I follow the curate content of this clade link
    Then I should be on the curation worklist page
    When I choose "Trusted" within "first image box"
    
