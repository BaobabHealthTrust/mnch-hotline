require File.dirname(__FILE__) + '/../test_helper'

class PatientIdentifierTypeTest < ActiveSupport::TestCase
  fixtures :patient_identifier_type, :patient

  context "Patient identifier types" do 
    should "be valid" do
      patient_identifier_type = PatientIdentifierType.make
      assert patient_identifier_type.valid?
    end

    should "not be able to produce the next national identifier without a patient" do
      patient_identifier_type = PatientIdentifierType.make
      patient_identifier_type.name = "National id"
      ident = patient_identifier_type.next_identifier
      assert_nil ident
    end

    
    should "be able to produce the next national identifier" do
      patient_identifier_type = PatientIdentifierType.make
      patient_identifier_type.name = "National id"
      ident = patient_identifier_type.next_identifier(:patient => patient(:evan))
      assert_not_nil ident.identifier
    end
  end  
end