#!/usr/bin/ruby
require 'rubygems'
require 'json'

def textit_integration
  path = "#{Rails.root}/script/"
  file_name = "#{path}AncConnectSync.example.json"
  json = File.read(file_name)
  data = JSON.parse(json)

  data.each do |key|
    anc_conn_id = key["anc_conn_id"]
    nickname = key["nickname"]
    lastname = key["lastname"]
    village = key["village"]
    health_facility = key["health_facility"]
    lmp = key["lmp"]
    edd = key["edd"]
    phone = key["phone"]
    hsa_name = key["hsa_name"]
    hsa_phone = key["hsa_phone"]
    registration_time = key["registration_time"]
    next_visit_date = key["next_visit_date"]

    key["anc_visits"].each do |anc_visit|

    end
    
    birth_plan_facility = key["birth_plan_facility"]
    delivery_date = key["delivery_date"]
    delivery_facility = key["delivery_facility"]


    ActiveRecord::Base.transaction do
      anc_identifier_type = PatientIdentifierType.find_by_name("ANC Connect ID") rescue nil
      attribute_value = PersonAttribute.find(:last,:conditions =>["voided = 0 AND person_attribute_type_id = ?
          AND value =?", anc_identifier_type.id, anc_conn_id])

      cell_phone_attribute_id = PersonAttributeType.find_by_name('CELL PHONE NUMBER').id
      
      if (attribute_value.blank?)
        person = Person.create({
            :birthdate => (Date.today - 20.years),
            :gender => "F",
            :birthdate_estimated => 1,
            :creator =>  1
        })
        patient = person.patient.create
        
        patient.patient_identifiers.create({
            :identifier_type => anc_identifier_type.id,
            :identifier => anc_conn_id,
            :creator =>  1
        })

        person.names.create({
          :family_name_prefix => nickname,
          :family_name => lastname,
           :creator =>  1
        })

        person.person_attributes.create({
          :person_attribute_type_id => cell_phone_attribute_id,
          :value => phone,
          :creator =>  1
        })

        person.addresses.create({
          :address2 => "",
          :city_village => "",
          :county_district => "",
          :subregion => "",
          :creator =>  1
        })
      
      else
        
      end
    end
    
  end
  
end
textit_integration
=begin
  [
	{
		"anc_conn_id": "4450",
		"nickname": "Jane",
		"lastname": "Doe",
		"village": "Thunga 2",
		"health_facility": "Mbera",
		"lmp": "2014-03-15T00:00+0200",
		"edd": "2014-12-15T00:00+0200",
		"phone": "265987654321",
		"hsa_name": "Stella Goma",
		"hsa_phone": "265987654322",
		"registration_time": "2014-03-21T08:31+0200",
		"next_visit_date": "2014-06-01T00:00+0200",
		"anc_visits": {
			"1": {
				"date": "2014-04-01T00:00+0200",
				"next_visit_date": "2014-05-01T00:00+0200"
			},
			"2": {
				"date": "2014-05-01T00:00+0200",
				"next_visit_date": "2014-06-01T00:00+0200"
			}
		},
		"birth_plan_facility": "Balaka Hospital",
		"delivery_date": "2014-12-18T00:00+0200",
		"delivery_facility": "enroute"
	}
]
=end