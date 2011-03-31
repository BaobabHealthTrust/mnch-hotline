Feature: HV Staging
  As a clinician
  I want to be able to evaluate an ART patient using the system
  So that I can record their ART reason for eligibility and staging criteria

  @javascript
  Scenario: View the HIV Staging encounter
    Given I am signed in at the clinician station
    And the patient is "Child"
    When I start the task "Hiv staging"
    Then I should see "Stage 1 Conditions (adults and children)"                                    
    
  @javascript
  Scenario: Staging a child with a stage 1 condition
    Given I am signed in at the clinician station
    And the patient is "Child"
    When I start the task "Art Clinician Visit"
    Then I should see "Stage 1 Conditions (adults and children)"                                        
    When I press "Next"
    Then I should see "Stage 1 Conditions (children only)"
    When I select an option
    And I press "Next" until I see "New CD4 percent available?"
    And I select the option "No"
    And I press "Next"
    Then I should see "New Lymphocyte count available?"
    When I select the option "No"
    And I press "Next"    
    Then I should see "Summary"
    And the summary should include "WHO Stage: WHO STAGE I PEDS"
    And the summary should include "Reason for ART Eligibility: UNKNOWN"

  @javascript
  Scenario: Staging an adult with a stage 1 condition
    Given I am signed in at the clinician station
    And the patient is "Woman"
    When I start the task "Hiv staging"
    Then I should see "Is patient pregnant?"                                        
    And I select the option "No"
    And I press "Next"
    Then I should see "Stage 1 Conditions (adults and children)"                                        
    When I press "Next"
    Then I should see "Stage 1 Conditions (adults only)"
    When I select an option
    And I press "Next" until I see "Stage 4 Conditions (adults only)"
    And I select an option
    And I press "Next"
    Then I should see "New CD4 count available?"
    When I select the option "No"
    And I press "Next"
    Then I should see "Summary"
    And the summary should include "WHO Stage: WHO STAGE IV ADULT"
    And the summary should include "Reason for ART Eligibility: WHO STAGE IV ADULT"
