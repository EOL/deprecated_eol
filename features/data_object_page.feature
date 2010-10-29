Feature: Describe Data Object page
  As a visitor 
  I should be able to see details of data objects
  By visiting data object page

  Scenario: Opening image data object page
    When I go to /data_objects/5887524
    Then I should see "Image permalink" within "#page-title"
    And I should see "trusted" within "#data_object_status"
    And I should see the data object image
    And I should see "Attribution" within "#data_object_attribution"
    And I should see "Comments" within "#data_object_comments"

  Scenario: Opening text data object page
    When I go to /data_objects/466657
    Then I should see "Text permalink" within "#page-title"
    And I should see "Content" within "#data_object_content"
    And I should see "Brief Summary" within "#text_object_title"
    And I should see "Introduction" within "#text_object_title"

  Scenario: Opening YouTube data object page
    When I go to /data_objects/475483
    Then I should see "Video permalink" within "#page-title"
