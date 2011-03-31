require File.dirname(__FILE__) + '/../test_helper'

class OpenmrsTest < ActiveSupport::TestCase
  fixtures :patient_identifier_type, :person, :patient, :patient_identifier

  context "OpenMRS modules" do    
    setup do
      now = Time.now
      Time.stubs(:now).returns(now)  
    end
=begin    
    should "set the changed by and date changed before saving" do 
      p = person(:evan)
      p.gender = "U"
      p.save!
      assert_equal p.changed_by, User.current_user.id
      assert_equal p.date_changed, Time.now
    end
    
    should "set the creator, date created and the location before creating" do 
      p = PatientIdentifier.create(:identifier => 'foo', :identifier_type => patient_identifier_type(:unknown_id))
      assert_equal p.location_id, Location.current_location.id
      assert_equal p.creator, User.current_user.id
      assert_equal p.date_created, Time.now
    end
    
    should "void the record with a reason" do
      reason = "Evan is out."
      p = person(:evan)
      assert !p.voided?
      p.void(reason)
      assert p.voided?
      assert_equal p.void_reason, reason
    end
    
    should "know whether or not it has been voided" do
      p = person(:evan)
      assert !p.voided? 
      p.void("Evan is out.")        
      assert p.voided?
    end
    
    should "not find voided records by default" do
      c = Person.all.length
      p = person(:evan)
      assert !p.voided?
      p.void
      assert_equal c-1, Person.all.length
    end

    should "not find voided records in associations by default" do
      p = patient(:evan)      
      c = p.patient_identifiers.all.length
      i = p.patient_identifiers.first 
      i.void
      p.reload
      assert_equal c-1, p.patient_identifiers.all.length
    end

    should "find voided records when using the inactive scope" do
      c = Person.all.length
      p = person(:evan)
      p.void
      assert_equal 1, Person.inactive.length
    end
=end

    should "find not find voided records when using include" do
      p = patient(:evan)      
      c = p.patient_identifiers.all.length
      i = p.patient_identifiers.first 
      i.void      
      assert_equal c-1, Patient.find(p.patient_id, :include => :patient_identifiers).patient_identifiers.length
    end
  end
end  