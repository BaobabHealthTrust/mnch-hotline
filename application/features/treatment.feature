Feature: Treatment
  As a clinician
  I want to be able to prescribe treatments for a patient
  So that I can record their prescriptions and dispense their drugs

  @selenium
  Scenario: View the treatment encounter
    Given I am signed in at the clinician station
    And the patient is "Child"
    And I am on the treatment dashboard
    When I press "Prescribe"    
    Then I should see "Generic Drug"                                    
    
  @selenium
  Scenario: Prescribing a variable dose 
    Given I am signed in at the clinician station
    And the patient is "Child"
    When I start a new prescription
    Then I should see "Generic Drug"
    When I type "PARACETAMOL"
    And I press "Next"
    Then I should see "Formulation"
    And the options should be:
      | Paracetamol (120mg/5mL susp) |
      | Paracetamol (500mg tablet)   |
    When I select the option "Paracetamol (500mg tablet)"
    And I press "Next"
    Then I should see "Type of Prescription"
    When I select the option "Variable Dose"
    And I press "Next"
    Then I should see "Morning Dose Strength in mg"
    When I type "500.0"
    And I press "Next"
    Then I should see "Afternoon Dose Strength in mg"
    When I press "Unknown"
    And I press "Next"
    Then I should see "Evening Dose Strength in mg"
    When I press "Unknown"
    And I press "Next"
    Then I should see "Night Dose Strength in mg"
    When I type "500.0"
    And I press "Next"
    Then I should see "Duration (days)"
    When I type "3.0"
    And I press "Next"
    Then I should see "Take as needed (PRN)?"
    When I select the option "No"
    And I press "Finish"
    Then I should be on the treatment dashboard
    And I should see "Paracetamol (500mg tablet): IN THE MORNING (QAM):500.0 mg ONCE A DAY AT NIGHT (QHS):500.0 mg for 3 days"