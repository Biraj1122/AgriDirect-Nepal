Feature: Category Display Order
  As a customer
  I want to see Vegetables and Fruits first in the category list
  So that I can easily find common fresh produce

  Scenario: Categories are listed in priority order
    Given the app has categories "Dairy", "Fruits", "Vegetables", "Grains"
    When I view the categories section
    Then I should see "Vegetables" as the first category after "All"
    And I should see "Fruits" as the second category after "All"
    And other categories should follow in alphabetical order
