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
    if params[:person].blank? || params[:person] == '0'
      redirect_to :action => :new, :gender => params[:gender], :given_name => params[:given_name], :family_name => params[:family_name],
    :family_name2 => params[:family_name2], :address2 => params[:address2], :identifier => params[:identifier], :relation => params[:relation],
    :update_information => 'false'
    else
      if ! Person.find(params[:person]).birthdate.nil?
        redirect_to search_complete_url(params[:person], params[:relation]) and return unless params[:person].blank? || params[:person] == '0'
      else
        redirect_to :action => :new, :gender => params[:gender], :given_name => params[:given_name], :family_name => params[:family_name],
        :family_name2 => params[:family_name2], :address2 => params[:address2], :identifier => params[:identifier], :relation => params[:relation],
        :update_information => 'true',:update_id => params[:person]
      end
    end    
  end
 
  def create 
    Person.session_datetime = session[:datetime].to_date rescue Date.today
    params[:person][:relation] = params[:relation]
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
  
  def traditional_authority
    district_id = District.find_by_name("#{session[:district]}").id
    traditional_authority_conditions = ["name LIKE (?) AND district_id = ?", "%#{params[:search_string]}%", district_id]

    traditional_authorities = TraditionalAuthority.find(:all,:conditions => traditional_authority_conditions, :order => 'name')
    traditional_authorities = traditional_authorities.map do |t_a|
      "<li value='#{t_a.name}'>#{t_a.name}</li>"
    end
    render :text => traditional_authorities.join('') + "<li value='Other'>Other</li>" and return
  end
  
  def village
    traditional_authority_id = TraditionalAuthority.find_by_name("#{params[:filter_value]}").id
    village_conditions = ["name LIKE (?) AND traditional_authority_id = ?", "%#{params[:search_string]}%", traditional_authority_id]

    villages = Village.find(:all,:conditions => village_conditions, :order => 'name')
    villages = villages.map do |v|
      '<li value=' + v.name + '>' + v.name + '</li>'
    end
    render :text => villages.join('') + "<li value='Other'>Other</li>" and return
  end
  def healthcenter
    district_id = District.find_by_name("#{session[:district]}").id
    hc_conditions = ["name LIKE (?) AND district = ?", "%#{params[:search_string]}%", district_id]

    health_centers = HealthCenter.find(:all,:conditions => hc_conditions, :order => 'name')
    health_centers = health_centers.map do |h_c|
      "<li value='#{h_c.name.humanize}'>#{h_c.name.humanize}</li>"
    end
 
    render :text => health_centers.join('') + "<li value='Other'>Other</li>" and return
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
 
