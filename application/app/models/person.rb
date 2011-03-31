class Person < ActiveRecord::Base
  set_table_name "person"
  set_primary_key "person_id"
  include Openmrs

  cattr_accessor :session_datetime

  has_one :patient, :foreign_key => :patient_id, :dependent => :destroy, :conditions => {:voided => 0}
  has_many :names, :class_name => 'PersonName', :foreign_key => :person_id, :dependent => :destroy, :order => 'person_name.preferred DESC', :conditions => {:voided => 0}
  has_many :addresses, :class_name => 'PersonAddress', :foreign_key => :person_id, :dependent => :destroy, :order => 'person_address.preferred DESC', :conditions => {:voided => 0}
  has_many :relationships, :class_name => 'Relationship', :foreign_key => :person_a, :conditions => {:voided => 0}
  has_many :person_attributes, :class_name => 'PersonAttribute', :foreign_key => :person_id, :conditions => {:voided => 0}
  has_many :observations, :class_name => 'Observation', :foreign_key => :person_id, :dependent => :destroy, :conditions => {:voided => 0} do
    def find_by_concept_name(name)
      concept_name = ConceptName.find_by_name(name)
      find(:all, :conditions => ['concept_id = ?', concept_name.concept_id]) rescue []
    end
  end

  def after_void(reason = nil)
    self.patient.void(reason) rescue nil
    self.names.each{|row| row.void(reason) }
    self.addresses.each{|row| row.void(reason) }
    self.relationships.each{|row| row.void(reason) }
    self.person_attributes.each{|row| row.void(reason) }
    # We are going to rely on patient => encounter => obs to void those
  end

  def name
    "#{self.names.first.given_name} #{self.names.first.family_name}".titleize rescue nil
  end  

  def address
    "#{self.addresses.first.city_village}" rescue nil
  end 

  def age(today = Date.today)
    return nil if self.birthdate.nil?

    # This code which better accounts for leap years
    patient_age = (today.year - self.birthdate.year) + ((today.month - self.birthdate.month) + ((today.day - self.birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)

    # If the birthdate was estimated this year, we round up the age, that way if
    # it is March and the patient says they are 25, they stay 25 (not become 24)
    birth_date=self.birthdate
    estimate=self.birthdate_estimated==1
    patient_age += (estimate && birth_date.month == 7 && birth_date.day == 1  && 
      today.month < birth_date.month && self.date_created.year == today.year) ? 1 : 0
  end

  def age_in_months(today = Date.today)
    years = (today.year - self.birthdate.year)
    months = (today.month - self.birthdate.month)
    (years * 12) + months
  end
    
  def birthdate_formatted
    if self.birthdate_estimated==1
      if self.birthdate.day == 1 and self.birthdate.month == 7
        self.birthdate.strftime("??/???/%Y")
      elsif self.birthdate.day == 15 
        self.birthdate.strftime("??/%b/%Y")
      end
    else
      self.birthdate.strftime("%d/%b/%Y")
    end
  end

  def set_birthdate(year = nil, month = nil, day = nil)   
    raise "No year passed for estimated birthdate" if year.nil?

    # Handle months by name or number (split this out to a date method)    
    month_i = (month || 0).to_i
    month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
    month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
    
    if month_i == 0 || month == "Unknown"
      self.birthdate = Date.new(year.to_i,7,1)
      self.birthdate_estimated = 1
    elsif day.blank? || day == "Unknown" || day == 0
      self.birthdate = Date.new(year.to_i,month_i,15)
      self.birthdate_estimated = 1
    else
      self.birthdate = Date.new(year.to_i,month_i,day.to_i)
      self.birthdate_estimated = 0
    end
  end

  def set_birthdate_by_age(age, today = Date.today)
    self.birthdate = Date.new(today.year - age.to_i, 7, 1)
    self.birthdate_estimated = 1
  end

  def demographics


    if self.birthdate_estimated==1
      birth_day = "Unknown"
      if self.birthdate.month == 7 and self.birthdate.day == 1
        birth_month = "Unknown"
      else
        birth_month = self.birthdate.month
      end
    else
      birth_month = self.birthdate.month
      birth_day = self.birthdate.day
    end

    demographics = {"person" => {
      "date_changed" => self.date_changed.to_s,
      "gender" => self.gender,
      "birth_year" => self.birthdate.year,
      "birth_month" => birth_month,
      "birth_day" => birth_day,
      "names" => {
        "given_name" => self.names[0].given_name,
        "family_name" => self.names[0].family_name,
        "family_name2" => ""
      },
      "addresses" => {
        "county_district" => "",
        "city_village" => self.addresses[0].city_village,
        "location" => self.addresses[0].address2
      },
    "occupation" => self.get_attribute('Occupation')}}
 
    if not self.patient.patient_identifiers.blank? 
      demographics["person"]["patient"] = {"identifiers" => {}}
      self.patient.patient_identifiers.each{|identifier|
        demographics["person"]["patient"]["identifiers"][identifier.type.name] = identifier.identifier
      }
    end

    return demographics
  end

  def self.search_by_identifier(identifier)
    PatientIdentifier.find_all_by_identifier(identifier).map{|id| id.patient.person} unless identifier.blank? rescue nil
  end

  def self.search(params)
    people = Person.search_by_identifier(params[:identifier])

    return people.first.id unless people.blank? || people.size > 1
    people = Person.find(:all, :include => [{:names => [:person_name_code]}, :patient], :conditions => [
    "gender = ? AND \
     (person_name.given_name LIKE ? OR person_name_code.given_name_code LIKE ?) AND \
     (person_name.family_name LIKE ? OR person_name_code.family_name_code LIKE ?)",
    params[:gender],
    params[:given_name],
    (params[:given_name] || '').soundex,
    params[:family_name],
    (params[:family_name] || '').soundex
    ]) if people.blank?

    return people
    
    # temp removed
    # AND (person_name.family_name2 LIKE ? OR person_name_code.family_name2_code LIKE ? OR person_name.family_name2 IS NULL )"    
    #  params[:family_name2],
    #  (params[:family_name2] || '').soundex,




# CODE below is TODO, untested and NOT IN USE
#    people = []
#    people = PatientIdentifier.find_all_by_identifier(params[:identifier]).map{|id| id.patient.person} unless params[:identifier].blank?
#    if people.size == 1
#      return people
#    elsif people.size >2
#      filtered_by_family_name_and_gender = []
#      filtered_by_family_name = []
#      filtered_by_gender = []
#      people.each{|person|
#        gender_match = person.gender == params[:gender] unless params[:gender].blank?
#        filtered_by_gender.push person if gender_match
#        family_name_match = person.first.names.collect{|name|name.family_name.soundex}.include? params[:family_name].soundex
#        filtered_by_family_name.push person if gender_match?
#        filtered_by_family_name_and_gender.push person if family_name_match? and gender_match?
#      }
#      return filtered_by_family_name_and_gender unless filtered_by_family_name_and_gender.empty?
#      return filtered_by_family_name unless filtered_by_family_name.empty?
#      return filtered_by_gender unless filtered_by_gender.empty?
#      return people
#    else
#    return people if people.size == 1
#    people = Person.find(:all, :include => [{:names => [:person_name_code]}, :patient], :conditions => [
#    "gender = ? AND \
#     (person_name.given_name LIKE ? OR person_name_code.given_name_code LIKE ?) AND \
#     (person_name.family_name LIKE ? OR person_name_code.family_name_code LIKE ?)",
#    params[:gender],
#    params[:given_name],
#    (params[:given_name] || '').soundex,
#    params[:family_name],
#    (params[:family_name] || '').soundex
#    ]) if people.blank?
#    
    # temp removed
    # AND (person_name.family_name2 LIKE ? OR person_name_code.family_name2_code LIKE ? OR person_name.family_name2 IS NULL )"    
    #  params[:family_name2],
    #  (params[:family_name2] || '').soundex,

  end

  def self.find_by_demographics(person_demographics)
    national_id = person_demographics["person"]["patient"]["identifiers"]["National id"] rescue nil
    results = Person.search_by_identifier(national_id) unless national_id.nil?
    return results unless results.blank?

    gender = person_demographics["person"]["gender"] rescue nil
    given_name = person_demographics["person"]["names"]["given_name"] rescue nil
    family_name = person_demographics["person"]["names"]["family_name"] rescue nil

    search_params = {:gender => gender, :given_name => given_name, :family_name => family_name }

    results = Person.search(search_params)

  end

  def self.create_from_form(params)
    address_params = params["addresses"]
    names_params = params["names"]
    patient_params = params["patient"]
    params_to_process = params.reject{|key,value| key.match(/addresses|patient|names|relation|cell_phone_number|home_phone_number|office_phone_number/) }
    birthday_params = params_to_process.reject{|key,value| key.match(/gender/) }
    person_params = params_to_process.reject{|key,value| key.match(/birth_|age_estimate|occupation/) }

    person = Person.create(person_params)

    if birthday_params["birth_year"] == "Unknown"
      person.set_birthdate_by_age(birthday_params["age_estimate"],self.session_datetime || Date.today)
    else
      person.set_birthdate(birthday_params["birth_year"], birthday_params["birth_month"], birthday_params["birth_day"])
    end
    person.save
    person.names.create(names_params)
    person.addresses.create(address_params)

    person.person_attributes.create(
      :person_attribute_type_id => PersonAttributeType.find_by_name("Occupation").person_attribute_type_id,
      :value => params["occupation"])
 
    person.person_attributes.create(
      :person_attribute_type_id => PersonAttributeType.find_by_name("Cell Phone Number").person_attribute_type_id,
      :value => params["cell_phone_number"])
 
    person.person_attributes.create(
      :person_attribute_type_id => PersonAttributeType.find_by_name("Office Phone Number").person_attribute_type_id,
      :value => params["office_phone_number"]) unless params["office_phone_number"].blank?
 
    person.person_attributes.create(
      :person_attribute_type_id => PersonAttributeType.find_by_name("Home Phone Number").person_attribute_type_id,
      :value => params["home_phone_number"]) unless params["home_phone_number"].blank?
 
# TODO handle the birthplace attribute
 
    if (!patient_params.nil?)
      patient = person.create_patient

      patient_params["identifiers"].each{|identifier_type_name, identifier|
        identifier_type = PatientIdentifierType.find_by_name(identifier_type_name) || PatientIdentifierType.find_by_name("Unknown id")
        patient.patient_identifiers.create("identifier" => identifier, "identifier_type" => identifier_type.patient_identifier_type_id)
      } if patient_params["identifiers"]
  
      # This might actually be a national id, but currently we wouldn't know
      #patient.patient_identifiers.create("identifier" => patient_params["identifier"], "identifier_type" => PatientIdentifierType.find_by_name("Unknown id")) unless params["identifier"].blank?
    end
    return person
  end

  def self.find_remote_by_identifier(identifier)
    known_demographics = {:person => {:patient => { :identifiers => {"National id" => identifier }}}}
    Person.find_remote(known_demographics)
  end

  def self.find_remote(known_demographics)
    servers = GlobalProperty.find(:first, :conditions => {:property => "remote_demographics_servers"}).property_value.split(/,/) rescue nil
    return nil if servers.blank?

    wget_base_command = "wget --quiet --load-cookies=cookie.txt --quiet --cookies=on --keep-session-cookies --save-cookies=cookie.txt"
    # use ssh to establish a secure connection then query the localhost
    # use wget to login (using cookies and sessions) and set the location
    # then pull down the demographics
    # TODO fix login/pass and location with something better

    login = "mikmck"
    password = "mike"
    location = 8

    post_data = known_demographics
    post_data["_method"]="put"

    local_demographic_lookup_steps = [ 
      "#{wget_base_command} -O /dev/null --post-data=\"login=#{login}&password=#{password}\" \"http://localhost/session\"",
      "#{wget_base_command} -O /dev/null --post-data=\"_method=put&location=#{location}\" \"http://localhost/session\"",
      "#{wget_base_command} -O - --post-data=\"#{post_data.to_param}\" \"http://localhost/people/demographics\""
    ]
    results = []
    servers.each{|server|
      command = "ssh #{server} '#{local_demographic_lookup_steps.join(";\n")}'"
      output = `#{command}`
      results.push output if output and output.match /person/
    }
    # TODO need better logic here to select the best result or merge them
    # Currently returning the longest result - assuming that it has the most information
    # Can't return multiple results because there will be redundant data from sites
    result = results.sort{|a,b|b.length <=> a.length}.first

    result ? JSON.parse(result) : nil

  end

  def get_attribute(attribute)
    PersonAttribute.find(:first,:conditions =>["voided = 0 AND person_attribute_type_id = ? AND person_id = ?",
        PersonAttributeType.find_by_name(attribute).id,self.id]).value rescue nil
  end

  def phone_numbers
    PersonAttribute.phone_numbers(self.person_id)
  end

  def sex
    if self.gender == "M"
      return "Male"
    elsif self.gender == "F"
      return "Female"
    else
      return nil
    end
  end

end
