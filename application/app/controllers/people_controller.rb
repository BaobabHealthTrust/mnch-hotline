class PeopleController < ApplicationController
  def index
    redirect_to "/clinic"
  end
 
  def new
    @gender = {"" => "", "Male" => "M", "Female" => "F"}
    @health_facilities = [""] + ClinicSchedule.health_facilities_list
  end
  
  def identifiers
  end

  def demographics
    # Search by the demographics that were passed in and then return demographics
    people = Person.find_by_demographics(params)
    result = people.empty? ? {} : people.first.demographics
    render :text => result.to_json
  end
 
  def search
    found_person = nil
    if params[:identifier]
      local_results = Person.search_by_identifier(params[:identifier])
      if local_results.length > 1
        @people = Person.search(params)
      elsif local_results.length == 1
        found_person = local_results.first
      else
        # TODO - figure out how to write a test for this
        # This is sloppy - creating something as the result of a GET
        found_person_data = Person.find_remote_by_identifier(params[:identifier])
        found_person =  Person.create_from_form(found_person_data) unless found_person_data.nil?
      end
      if found_person
        redirect_to search_complete_url(found_person.id, params[:relation]) and return
      end
    end
    @people = Person.search(params)    
  end
 
  # This method is just to allow the select box to submit, we could probably do this better
  def select
    redirect_to search_complete_url(params[:person], params[:relation]) and return unless params[:person].blank? || params[:person] == '0'
    redirect_to :action => :new, :gender => params[:gender], :given_name => params[:given_name], :family_name => params[:family_name],
    :family_name2 => params[:family_name2], :address2 => params[:address2], :identifier => params[:identifier], :relation => params[:relation]
  end
 
  def create
    Person.session_datetime = session[:datetime].to_date rescue Date.today
    person = Person.create_from_form(params[:person])
    
    redirect_to search_complete_url(person.id, params[:relation]) and return
    #redirect_to :action => "index"
  end

  def set_datetime
    if request.post?
      unless params[:set_day]== "" or params[:set_month]== "" or params[:set_year]== ""
        # set for 1 second after midnight to designate it as a retrospective date
        date_of_encounter = Time.mktime(params[:set_year].to_i,
                                        params[:set_month].to_i,                                
                                        params[:set_day].to_i,0,0,1) 
        session[:datetime] = date_of_encounter if date_of_encounter.to_date != Date.today 
      end
      redirect_to :action => "index"
    end
  end

  def reset_datetime
    session[:datetime] = nil
    redirect_to :action => "index" and return
  end

  def find_by_arv_number
    if request.post?
      redirect_to :action => 'search' ,
        :identifier => "#{Location.current_arv_code} #{params[:arv_number]}" and return
    end
  end

  def find_by_national_id
    if request.post?
      redirect_to :action => 'search', :identifier => "#{params[:national_id]}" and return
    end
  end

private
  
  def search_complete_url(found_person_id, primary_person_id) 
    unless (primary_person_id.blank?)
      # Notice this swaps them!
      new_relationship_url(:patient_id => primary_person_id, :relation => found_person_id)
    else
      url_for(:controller => :encounters, :action => :new, :patient_id => found_person_id)
    end
  end
end
 
