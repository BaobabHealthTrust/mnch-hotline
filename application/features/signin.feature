Feature: Signing in 
  In order to securely access the system's features
  Users should have to sign in with a user name and password

  @javascript
  Scenario: User who has not signed in cannot access secured pages
    Given I am not signed in
    When I go to the clinic dashboard
    Then I should be on the login page
    And I should see the question "Enter user name"

  @javascript
  Scenario: User has signed in can access secured pages
    Given I am signed in
    When I go to the clinic dashboard
    Then I should see "Scan a barcode"
