Feature: Workflow
  As a user
  I want to be able to detect what the patient needs to do next
  So that I can start the next task automatically

  @javascript
  Scenario: Registration
    Given I am signed in
    And the patient is "Child"
    When I find the patient
    Then the patient should have a "Registration" encounter

  @javascript
  Scenario: Hiv clinician and ART initiation
    Given I am signed in at the clinician station
    And the patient is "Child"
    When I find the patient
    Then I should see "Ever received ART?"
    And the patient should have a "Registration" encounter

  @javascript
  Scenario: Hiv Clinician station and vitals for already initiated patients
    Given I am signed in at the clinician station
    And the patient is "Child"
    And I initiated this patient yesterday
    When I find the patient
    Then I should see "Guardian Present"
    And the patient should have a "Registration" encounter
