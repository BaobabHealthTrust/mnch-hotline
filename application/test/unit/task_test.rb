require File.dirname(__FILE__) + '/../test_helper'

class TaskTest < ActiveSupport::TestCase 
  fixtures :patient

  context "Tasks" do
    setup do
      @patient = patient(:evan)
      @task = Factory(:task)
      @default = @task.url.gsub(/\{patient\}/, '1')
      GlobalProperty.create(:property => 'current_health_center_id', :property_value => location(:neno_district_hospital).id)
    end
  
    should "be able to create a task" do
      assert_not_nil @task
    end  
    
    should "find the next task" do
      assert_equal @default, Task.next_task(Location.current_location, @patient).url
    end
    
    should "skip the relationship task if the patient does not have the specified relationship type" do
      @relationship = Factory(:task, :url => '/relationship', :has_relationship_type_id => 1, :sort_weight => 0)
      assert_equal @default, Task.next_task(Location.current_location, @patient).url
    end
        
    should "not skip the relationship task if the patient does have the specified relationship type" do
      Relationship.create(
        :person_a => @patient.patient_id,
        :person_b => @patient.patient_id,
        :relationship => 1)      
      @relationship = Factory(:task, :url => '/relationship', :has_relationship_type_id => 1, :sort_weight => 0)
      assert_equal @relationship.url, Task.next_task(Location.current_location, @patient).url
    end

    should "skip the program task if the patient does not have the specified program type and state at this location" do
      @program = Factory(:task, :url => '/program', :has_program_id => 1, :has_program_workflow_state_id => 1, :sort_weight => 0)
      assert_equal @default, Task.next_task(Location.current_location, @patient).url
    end
    
    should "not skip the program task if the patient does have the specified program type and state at this location" do
      @patient_program = @patient.patient_programs.build(
        :program_id => 1,
        :date_enrolled => Time.now,
        :location_id => Location.current_health_center.location_id)      
      @patient_state = @patient_program.patient_states.build(
        :state => 1,
        :start_date => Time.now) 
      @patient_program.save!
      @patient_state.save!
      @program = Factory(:task, :url => '/program', :has_program_id => 1, :has_program_workflow_state_id => 1, :sort_weight => 0)
      assert_equal @program.url, Task.next_task(Location.current_location, @patient).url
    end
    
    should "skip the identifier task if the patient does not have the specified identifier type" do
      @ident = Factory(:task, :url => '/ident', :has_identifier_type_id => 1, :sort_weight => 0)
      assert_equal @default, Task.next_task(Location.current_location, @patient).url
    end
    
    should "not skip the identifier task if the patient does have the specified identifier type" do
      @patient.patient_identifiers.create(:identifier => 'Boss', :identifier_type => 1, :location_id => Location.current_health_center.location_id)
      @ident = Factory(:task, :url => '/ident', :has_identifier_type_id => 1, :sort_weight => 0)
      assert_equal @ident.url, Task.next_task(Location.current_location, @patient).url
    end
        
    should "skip the order task if the patient does not have the specified order type" do
      @order = Factory(:task, :url => '/order', :has_order_type_id => 1, :sort_weight => 0)
      assert_equal @default, Task.next_task(Location.current_location, @patient).url
    end
    
    should "not skip the order task if the patient does have the specified order type" do
      Order.create(
        :order_type_id => 1, 
        :concept_id => 1, 
        :orderer => User.current_user.user_id, 
        :patient_id => @patient.id,
        :start_date => Date.today,
        :auto_expire_date => Time.now+3.days)        
      @order = Factory(:task, :url => '/order', :has_order_type_id => 1, :sort_weight => 0)
      assert_equal @order.url, Task.next_task(Location.current_location, @patient).url
    end

    should "skip the obs task if the patient does not have the specified obs with the specified value" do
      @obs = Factory(:task, :url => '/obs', :has_obs_concept_id => 1, :has_obs_value_text => 'GIDDYUP', :sort_weight => 0)
      assert_equal @default, Task.next_task(Location.current_location, @patient).url
    end
    
    should "not skip the obs task if the patient does have the specified obs with the specified value" do
      encounter = Encounter.make(:encounter_type => 1, :patient_id => @patient.id, :encounter_datetime => Time.now)
      encounter.observations.create(
        :concept_id => 1, 
        :value_text => 'GIDDYUP',
        :person_id => 1,
        :obs_datetime => Time.now)        
      @obs = Factory(:task, :url => '/obs', :has_obs_concept_id => 1, :has_obs_value_text => 'GIDDYUP', :sort_weight => 0)
      assert_equal @obs.url, Task.next_task(Location.current_location, @patient).url
    end

    context "which skip if the patient has the specified value" do

      should "not skip the relationship task if the patient has the specified relationship type" do
        @relationship = Factory(:task, :url => '/relationship', :has_relationship_type_id => 1, :sort_weight => 0, :skip_if_has => 1)
        assert_equal @relationship.url, Task.next_task(Location.current_location, @patient).url
      end
          
      should "skip the relationship task if the patient does have the specified relationship type" do
        Relationship.create(
          :person_a => @patient.patient_id,
          :person_b => @patient.patient_id,
          :relationship => 1)      
        @relationship = Factory(:task, :url => '/relationship', :has_relationship_type_id => 1, :sort_weight => 0, :skip_if_has => 1)
        assert_equal @default, Task.next_task(Location.current_location, @patient).url
      end

      should "not skip the program task if the patient does not have the specified program type and state at this location" do
        @program = Factory(:task, :url => '/program', :has_program_id => 1, :has_program_workflow_state_id => 1, :sort_weight => 0, :skip_if_has => 1)
        assert_equal @program.url, Task.next_task(Location.current_location, @patient).url
      end
      
      should "skip the program task if the patient does have the specified program type and state at this location" do
        @patient_program = @patient.patient_programs.build(
          :program_id => 1,
          :date_enrolled => Time.now,
          :location_id => Location.current_health_center.location_id)      
        @patient_state = @patient_program.patient_states.build(
          :state => 1,
          :start_date => Time.now) 
        @patient_program.save!
        @patient_state.save!
        @program = Factory(:task, :url => '/program', :has_program_id => 1, :has_program_workflow_state_id => 1, :sort_weight => 0, :skip_if_has => 1)
        assert_equal @default, Task.next_task(Location.current_location, @patient).url
      end
    
      should "not skip the identifier task if the patient does not have the specified identifier type" do
        @ident = Factory(:task, :url => '/ident', :has_identifier_type_id => 1, :sort_weight => 0, :skip_if_has => 1)
        assert_equal @ident.url, Task.next_task(Location.current_location, @patient).url
      end
      
      should "skip the identifier task if the patient does have the specified identifier type" do
        @patient.patient_identifiers.create(:identifier => 'Boss', :identifier_type => 1, :location_id => Location.current_health_center.location_id)
        @ident = Factory(:task, :url => '/ident', :has_identifier_type_id => 1, :sort_weight => 0, :skip_if_has => 1)
        assert_equal @default, Task.next_task(Location.current_location, @patient).url
      end

      should "not skip the order task if the patient does not have the specified order type" do
        @order = Factory(:task, :url => '/order', :has_order_type_id => 1, :sort_weight => 0, :skip_if_has => 1)
        assert_equal @order.url, Task.next_task(Location.current_location, @patient).url
      end
      
      should "skip the order task if the patient does have the specified order type" do
        Order.create(
          :order_type_id => 1, 
          :concept_id => 1, 
          :orderer => User.current_user.user_id, 
          :patient_id => @patient.id,
          :start_date => Date.today,
          :auto_expire_date => Time.now+3.days)        
        @order = Factory(:task, :url => '/order', :has_order_type_id => 1, :sort_weight => 0, :skip_if_has => 1)
        assert_equal @default, Task.next_task(Location.current_location, @patient).url
      end
  
      should "not skip the obs task if the patient does not have the specified obs with the specified value" do
        @obs = Factory(:task, :url => '/obs', :has_obs_concept_id => 1, :has_obs_value_text => 'GIDDYUP', :sort_weight => 0, :skip_if_has => 1)
        assert_equal @obs.url, Task.next_task(Location.current_location, @patient).url
      end
      
      should "skip the obs task if the patient does have the specified obs with the specified value" do
        encounter = Encounter.make(:encounter_type => 1, :patient_id => @patient.id, :encounter_datetime => Time.now)
        encounter.observations.create(
          :concept_id => 1, 
          :value_text => 'GIDDYUP',
          :person_id => 1,
          :obs_datetime => Time.now)        
        @obs = Factory(:task, :url => '/obs', :has_obs_concept_id => 1, :has_obs_value_text => 'GIDDYUP', :sort_weight => 0, :skip_if_has => 1)
        assert_equal @default, Task.next_task(Location.current_location, @patient).url
      end

    end

  
  end  
end
