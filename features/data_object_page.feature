Feature: Describe Data Object page
  As a visitor 
  I should be able to see details of data objects
  By visiting data object page

  Scenario: Opening image data object page
    When I go to /data_objects/5887524
    Then I should see "Image permalink" within page title
    And I should see "trusted" within data object status
    And I should see the data object image
    And I should see "Attribution" within data object attribution
    And I should see "Comments" within data object comments

  Scenario: Opening text data object page
    When I go to /data_objects/466657
    Then I should see "Text permalink" within page title
    And I should see "Content" within data object content
    And I should see "Brief Summary" within text data object title
    And I should see "Introduction" within text data object title

  Scenario: Opening YouTube data object page
    When I go to /data_objects/475483
    Then I should see "Video permalink" within page title

  Scenario: Opening Wikipedia data object page
    When I go to /data_objects/6744733
    Then I should see "Text permalink" within page title
    And I should see "Wikipedia" within text data object title

  Scenario: Opening data object page without a taxon concept id
    When I go to dato page without taxon concept id
    Then I should see "( stands alone )" within page title
    And I should see a permalink for the data object
    
