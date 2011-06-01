# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def link_to_onmousedown(name, options = {}, html_options = nil, *parameters_for_method_reference)
    html_options = Hash.new if html_options.nil?
    html_options["onMouseDown"]="this.style.backgroundColor='lightblue';document.location=this.href"
    html_options["onClick"]="return false" #if we don't do this we get double clicks
    link = link_to(name, options, html_options, *parameters_for_method_reference)
  end

  def img_button_submit_to(url, image, options = {}, params = {})
    form_id       = (options[:form_id]) ? ("#{options[:form_id]}") : "frm_general"
    container_id  = (options[:container_id]) ? ("#{options[:container_id]}") : ""
    confirmation_message = ""
    confirmation_message = "onclick = \"return confirmRecordDeletion('#{options[:confirm]}', '#{form_id}', '#{container_id}')\"" if options[:confirm]

    content = ""
    content << "<form id='#{form_id}' method='post' action='#{url}'>"
    content << "<input type='image' src='#{image}' #{confirmation_message}/>"

    params.each {|n,v| content << "<input type='hidden' name='#{n}' value='#{v}'/>" }
    content << "</form>"
    content
  end
  
  def fancy_or_high_contrast_touch
    fancy = GlobalProperty.find_by_property("interface").property_value == "fancy" rescue false
    fancy ? "touch-fancy.css" : "touch-basic.css"
  end
  
  def show_intro_text
    GlobalProperty.find_by_property("show_intro_text").property_value == "yes" rescue false
  end
  
  def ask_home_village
    GlobalProperty.find_by_property("demographics.home_village").property_value == "yes" rescue false
  end

  def ask_group_village_head
    GlobalProperty.find_by_property("demographics.group_village_head").property_value == "yes" rescue false
  end
  
  def ask_mothers_surname
    GlobalProperty.find_by_property("demographics.mothers_surname").property_value == "yes" rescue false
  end
  
  def ask_blood_pressure
    GlobalProperty.find_by_property("vitals.blood_pressure").property_value == "yes" rescue false
  end
  
  def ask_temperature
    GlobalProperty.find_by_property("vitals.temperature").property_value == "yes" rescue false
  end  

  def ask_standard_art_side_effects
    GlobalProperty.find_by_property("art_visit.standard_art_side_effects").property_value == "yes" rescue false
  end

 def ask_multiple_phone_numbers
   GlobalProperty.find_by_property("ask_multiple_phone_numbers").property_value rescue false
 end

  def month_name_options
    i=0
    options_array = [[]] +Date::ABBR_MONTHNAMES[1..-1].collect{|month|[month,i+=1]} + [["Unknown","Unknown"]]
    options_for_select(options_array)  
  end
  
  def age_limit
    Time.now.year - 1890
  end

  def version
    #"Bart Version: #{BART_VERSION}#{' ' + BART_SETTINGS['installation'] if BART_SETTINGS}, #{File.ctime(File.join(RAILS_ROOT, 'config', 'environment.rb')).strftime('%d-%b-%Y')}"
    #make sure that all changes in this action  are also made to the 'Twin' version_without_date. Am sure you know what it means.
    style = "style='background-color:red;'" unless session[:datetime].blank?
    "Hotline System - <span #{style}>#{(session[:datetime].to_date rescue Date.today).strftime('%A, %d-%b-%Y')}</span>"
  end
  def version_without_date
    #Added this to ensure that the we are not returning the when needing the version
    "Hotline"
  end
  def system_date
    return (session[:datetime].to_date rescue Date.today).strftime('%d-%b-%Y')
  end
  def welcome_message
    "Muli bwanji, enter your user information or scan your id card. <span style='font-size:0.6em;float:right'>(#{version})</span>"  
  end
  
  def show_identifiers(location_id, patient)
    content = ""
    idents = GlobalProperty.find_by_property("dashboard.identifiers").property_value
    json = JSON.parse(idents)
    names = json[location_id.to_s] rescue []
    names.each do |name|
      ident_type = PatientIdentifierType.find_by_name(name)
      next if ident_type.blank?
      ident = patient.patient_identifiers.find_by_identifier_type(ident_type.id)
      next if ident.blank?
      content << "<span class='title'>#{name}:</span> #{ident.identifier}"       
    end
    content
  end
  
  def patient_image(patient) 
    @patient.person.gender == 'M' ? "<img src='/images/male.gif' alt='Male' height='30px' style='margin-bottom:-4px;'>" : "<img src='/images/female.gif' alt='Female' height='30px' style='margin-bottom:-4px;'>"
  end
  
  def relationship_options(patient)
    rels = @patient.relationships.all
    # filter out voided relationship target
    options_array = []
    rels.each do |rel|
      options_array << [rel.relation.name + " (#{rel.type.b_is_to_a})", rel.relation.name] unless rel.relation.blank?
    end
   # options_array = rels.map{|rel| next if rel.relation.blank? [rel.relation.name + " (#{rel.type.b_is_to_a})", rel.relation.name]}
    options_for_select(options_array)  
  end
  
  def program_enrollment_options(patient, filter_program_name=nil)
    progs = @patient.patient_programs.all
    progs.reject!{|prog| prog.program.name != filter_program_name} unless filter_program_name.blank?
    options_array = progs.map{|prog| [prog.program.name + " (started #{prog.date_enrolled.strftime('%d/%b/%Y')} at #{prog.location.name})", prog.id]}
    options_for_select(options_array)  
  end
  
  def concept_set_options(concept_name)
    concept_id = ConceptName.find(:first,:joins =>"INNER JOIN concept USING (concept_id)",
                                  :conditions =>["retired = 0 AND name = ?",concept_name]).concept_id
    set = ConceptSet.find_all_by_concept_set(concept_id, :order => 'sort_weight')
    options = set.map{|item|next if item.concept.blank? ; [item.concept.fullname, item.concept.fullname] }
    options_for_select(options)
  end
  
  def development_environment?
    ENV['RAILS_ENV'] == 'development'
  end

  def to_jsarray(values)
    str = "["
    values.each do |val|
      if val.class == String
        str += "\"" + val + "\","
      elsif val.class == Array
        str += to_jsarray(val)+ ","
      else
        str += val + ","
      end
    end
    str.chop!
    str += "]"
  end

  def extra_submit_button(url, label, button_class = nil, options = {}, params = {})
    content         = ""
    confirm_method  = ""

    form_id   = options[:form_id]   || "form_id"
    button_id = options[:button_id] || "button_id"

    confirm_message = options[:confirm] || nil
    container_id  = (options[:container_id]) ? ("#{options[:container_id]}") : ""
    confirm_method  = "onClick=\"return confirmRecordDeletion('#{confirm_message}', '#{form_id}', '#{container_id}')\"" if confirm_message
    button_class = "green" if button_class.nil?

    content << "<form id='#{form_id}' method='post' action='#{url}'>"
    content << "<button id='#{button_id}' class='#{button_class}' #{confirm_method}><span>#{label}</span></button>"

    unless params.nil?
      params.each do |name, value|
        content << "<input type='hidden' name='#{name}' value='#{value}'/>"
      end
    end

    content << "</form>"
    content
  end
end
