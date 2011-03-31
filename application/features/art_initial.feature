Feature: Clinician Visit
  As a clinician
  I want to be able to initiate an ART patient using the system
  So that I can record their ART initiation answers

  @javascript
  Scenario: View the ART initiation encounter
    Given I am signed in at the clinician station
    And the patient is "Child"
    When I start the task "Art Initial"
    Then I should see "Ever received ART?"                                    
    
  @javascript
  Scenario: Initiating a child that has never had ART before
    Given I am signed in at the clinician station
    And the patient is "Child"
    When I start the task "Art Initial"
    Then I should see "Ever received ART?"                                    
    When I select the option "No"
    And I press "Next"
    Then I should see "Agrees to followup?"
    When I select an option
    And I press "Next"
    Then I should see "Type of first positive HIV test"
    When I select an option
    And I press "Next"
    Then I should see "Location of first positive HIV test"
    When I select an option
    And I press "Next"
    Then I should see "Date of first positive HIV test"
    When I press "Unknown"    
    And I press "Next" 
    Then I should see "ART number at current location"
    When I type "NNO"
    And I press "0-9"
    And I type "1234"    
    And I press "nextButton" 
    Then the patient should have an "Art initial" encounter
  
  @javascript
  Scenario: Initiating a woman that is transfering in
    Given I am signed in at the clinician station
    And the patient is "Woman"
    When I start the task "Art Initial"
    Then I should see "Ever received ART?"                                    
    When I select the option "Yes"
    And I press "Next"
    Then I should see "Has transfer letter?"                                    
    When I select the option "Yes"
    And I press "Next"
    Then I should see "ART number at previous location"
    When I type "KCH"
    And I press "0-9"
    And I type "1234"    
    And I press "Next"
    Then I should see "Taken ART in the last two weeks?"                                    
    When I select the option "Yes"
    And I press "Next"
    Then I should see "Agrees to followup?"
    When I select an option
    And I press "Next"
    Then I should see "Type of first positive HIV test"
    When I select an option
    And I press "Next"
    Then I should see "Location of first positive HIV test"
    When I select an option
    And I press "Next"
    Then I should see "Date of first positive HIV test"
    When I press "Unknown"    
    And I press "Next" 
    Then I should see "ART number at current location"
    When I type "NNO"
    And I press "0-9"
    And I type "1234"    
    And I press "Next"
    Then I should see "Referred by PMTCT?"
    When I select an option
    And I press "nextButton" 
    Then the patient should have an "Art initial" encounter

  @javascript
  Scenario: Initiating a child that has already been initiated at this location
    Given I am signed in at the clinician station
    And the patient is "Child"
    And I initiated this patient yesterday
    When I start the task "Art Initial"
    Then I should not see "Ever received ART?"                                    
    And I should see "This patient has already been initiated in the HIV program at this location"
    When I press "cancelButton" 
    Then the patient should not have an "Art initial" encounter
    