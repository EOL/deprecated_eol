Feature: Ping Host Url
  In order to alert partners that their resources have been visited
  I want to ping partner's URLs when I view their resources

  Scenario: Ping for image
    Given a Taxon Concept 123
    And Taxon Concept 123 has an image with key "ABC" harvested from FishBase with a ping_host_url of "http://some.url/%ID%"
    When I go to the page for Taxon Concept 123
    Then I should see an "img" tag with a "src" attribute of "http://some.url/ABC"
