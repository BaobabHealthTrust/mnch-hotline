class HsaManagementController < ApplicationController

  def login
    if request.get?
      session[:user_id]=nil
    else
      @user=User.new(params[:user])
      logged_in_user=@user.try_to_login
      if logged_in_user
        reset_session
        session[:user_id] = logged_in_user.user_id
        session[:ip_address] = request.env['REMOTE_ADDR']         
        location = Location.find(params[:location]) rescue nil        
        location = Location.find_by_name(params[:location_name]) rescue nil unless params[:location_name].blank?
        flash[:error] = "Invalid Workstation Location" and return unless location
        #flash[:error] = "Location is not part of this health center" and return unless location.name.match(/Neno District Hospital/)
        session[:location_id] = nil
        session[:location_id] = location.id if location
        Location.current_location = location if location

        show_activites_property = GlobalProperty.find_by_property("show_activities_after_login").property_value rescue "false"
        if show_activites_property == "true"
          redirect_to(:action => "activities") 
        else                   
          redirect_to("/")
        end
      else
        flash[:error] = "Invalid username or password"
      end      
    end
  end          
 
 def role
  roles = Role.find(:all,:conditions => ["role LIKE (?)","%#{params[:value]}%"])
  roles = roles.map{| r | "<li value='#{r.role}'>#{r.role.gsub('_',' ').capitalize}</li>" }
  render :text => roles.join('') and return
 end
  
 def list_hsa_names
  hsa_names =  HsaName.find_by_sql("select hsa_id, hsa_full_name from list_hsa_names where family_name like '%#{params[:hsa_name]}%'")
  hsas = hsa_names.map{| hsa | "<li value='#{hsa.hsa_id}'>#{hsa.hsa_full_name}</li>" } 
  render :text => hsas.join('') and return
 end
  
 def health_centres
     redirect_to(:controller => "patient", :action => "menu")
     @health_centres = Location.find(:all,  :order => "name").map{|r|[r.name, r.location_id]}
 end 
 
 def list_clinicians
 	@clinician_role = Role.find_by_role("clinician").id
 	@clinicians = UserRole.find_all_by_role_id(@clinician_role)
 end
  
  def logout
   #if time is 4 o'oclock then send report on logout. 
    reset_session
    redirect_to(:action => "login")
  end

  def signup
    render :text => "Please sign up"
  end

  def remind_password
  end

  def index
    @user=User.find(session[:user_id])
    @firstname=@user.first_name
    @secondName=@user.last_name
       
    list
    return render(:action => 'list')
  end
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  # :redirect_to => { :action => :list }
        
  def voided_list
      session[:voided_list] = false 
    @hsa_pages, @users = paginate(:users, :per_page => 50,:conditions =>["voided=1"])
      render :view => 'list'
  end
  
  def list
    session[:voided_list] = true
    @hsa_pages, @users = paginate(:users, :per_page => 50,:conditions =>["voided=0"])
 end

  def hsa_person(hsa_person_id)
   person = Person.find_by_person_id(hsa_person_id)

  end

  def show
    unless params[:id].blank?
     @user = User.find(params[:id])
     @person = Person.find(@user.user_id)
    else
     @user = User.find(:first, :order => 'date_created DESC')
     @person = Person.find(@user.user_id)     
    end
    
    @phone_ids = []
    
    @phone_ids = PersonAttributeType.find_by_sql("SELECT * 
                                     FROM person_attribute_type
                                     WHERE name IN ('HOME PHONE NUMBER', 'CELL PHONE NUMBER', 'OFFICE PHONE NUMBER')").map(&:person_attribute_type_id)
 
    @phone_numbers = []
    @phone_numbers = PersonAttribute.find(:all, 
                      :conditions => ["person_attribute_type_id IN (?) AND person_id = ? AND value NOT IN ('Unknown','N/A')",@phone_ids, @person.person_id]).map(&:value)
   
    render :layout => 'menu'
  end

  def self.hsa_details(hsa_id)
    
  end

  def new
    @districts = [""] + District.find(:all, :conditions => ['region_id <> 4']).collect{|district| 
                                        district.name}.join(",").split(",") rescue []

    @all_districts = {}
    District.find(:all, :conditions => ['region_id <> 4']).each do |dis|
        @all_districts[dis.name] = dis.district_id
    end
   
    @trad_auths =  TraditionalAuthority.find(:all) rescue []
    
    @villages = Village.find(:all, :conditions => ['region_id <> 4']) rescue []
    
    @user = User.new
  end

  def create
    session[:user_edit] = nil
    existing_user = User.find(:first, :conditions => {:username => params[:user][:username]}) rescue nil
    @districts = [""] + District.find(:all, :conditions => ['region_id <> 4']).collect{|district| 
                                        district.name}.join(",").split(",") rescue []
    if existing_user
      flash[:notice] = 'Username already in use'
      redirect_to :action => 'new'
      return
    end
    
    @hsa_first_name = params[:person_name][:given_name]
    @hsa_middle_name = params[:person_name][:middle_name]
    @hsa_last_name = params[:person_name][:family_name]
    @hsa_name = @hsa_first_name + @hsa_last_name
    
    cellphone_number = params[:hsa].delete(:cell_phone_number) if  params[:hsa][:cell_phone_number].present?
    home_phone_number = params[:hsa].delete(:home_phone_number) if  params[:hsa][:home_phone_number].present?
    office_phone_number = params[:hsa].delete(:office_phone_number) if  params[:hsa][:office_phone_number].present?

    person = Person.create()
    person.names.create(params[:person_name])
    
    unless cellphone_number.blank?
      attribute_type_id  = PersonAttributeType.find_by_name("Cell Phone Number").person_attribute_type_id
      person.person_attributes.create(:person_attribute_type_id => attribute_type_id, :value => cellphone_number)
    end
    
    unless home_phone_number.blank?
      attribute_type_id  = PersonAttributeType.find_by_name("Home Phone Number").person_attribute_type_id
      person.person_attributes.create(:person_attribute_type_id => attribute_type_id, :value => home_phone_number)
    end
    
    unless office_phone_number.blank?
      attribute_type_id  = PersonAttributeType.find_by_name("Office Phone Number").person_attribute_type_id
      person.person_attributes.create(:person_attribute_type_id => attribute_type_id, :value => office_phone_number)
    end
    
    @person = Person.find_by_person_id(person.id)
    
    #create hsa_user
    hsa_name = @hsa_name
    hsa_user = User.new
    hsa_user.id = person.id
    hsa_user.creator = User.current_user.id
    hsa_user.username = hsa_name.downcase
    hsa_user.password = hsa_user.username
    hsa_user.date_created = Date.today
    hsa_user.save
     
    hsa_user_role = UserRole.new
    hsa_user_role.role = Role.find_by_role("HSA")
    hsa_user_role.user_id = hsa_user.user_id
    hsa_user_role.save
   
    #create hsa_name
    hsa_names = AllHsaName.new()
    hsa_names.hsa_id = person.id
    hsa_names.given_name = @hsa_first_name
    hsa_names.family_name = @hsa_last_name
    hsa_names.save

    #create hsa_ta, hsa_villages and hsa_health_center
    if params[:person][:addresses][:state_province]

      district_id = District.find_by_name("#{params[:person][:addresses][:state_province]}").id #rescue nil

      ta_id = TraditionalAuthority.find(:first, 
       :conditions => ['district_id = ? AND name = ?', 
                       district_id, params[:person][:addresses][:county_district]]).traditional_authority_id #rescue nil

      village_id =  Village.find(:first, 
       :conditions => ['traditional_authority_id = ? and name = ?', 
                     ta_id,params[:person][:addresses][:city_village]]).village_id #rescue nil
      
      if ta_id.blank?
        new_ta = TraditionalAuthority.new
	      new_ta.name = person[addresses][county_district]
        new_ta.district_id = district_id
        new_ta.creator = User.current_user.id
        new_ta.date_created = Date.today()
        new_ta.save
        ta_id = new_ta.traditional_authority_id

        if village_id.blank?
          new_village = Village.new
          new_village.name = village
          new_village.traditional_authority_id = ta_id
          new_village.creator = User.current_user.id
          new_village.date_created = Date.today()
          new_village.save
          village_id = new_village.village_id 
        end
      end

      if params[:hsa][:health_center]
        if params[:hsa][:health_center] != 'Other'
          @health_center_id = HealthCenter.find(:first, 
                                :conditions => ['district = ? AND name = ?', district_id, params[:hsa][:health_center]]).health_center_id

          if @health_center_id.blank?
            new_health_center = HealthCenter.new
            new_health_center.name = params[:hsa][:health_center]
            new_health_center.district = district_id
            new_health_center.save
            @health_center_id = new_health_center.health_center_id  
          end
        end    
      end

      if @health_center_id
        #create hsa_village
        hsa_village = HsaVillage.new()
        hsa_village.hsa_id = person.id
        hsa_village.village_id = village_id
        hsa_village.health_center_id = @health_center_id
        hsa_village.district_id = district_id
        hsa_village.save
      end
    end

    redirect_to :action => 'show'
  end

  def edit
    @hsa = Person.find(params[:id]) rescue nil

    @hsa_details = {}
    #@hsa = Person.find(params[:id]) 
    
    @hsa_details[:name] = @hsa.name
    @hsa_details[:cell_phone] = PersonAttribute.find(:last, :conditions => ["person_attribute_type_id = 12 AND person_id = #{@hsa.id}"]).value rescue 'Unknown'
    @hsa_details[:office_phone] = PersonAttribute.find(:last, :conditions => ["person_attribute_type_id = 15 AND person_id = #{@hsa.id}"]).value rescue 'Unknown'
    @hsa_details[:district] = District.find(HsaVillage.find(:last, :conditions => ["hsa_id = #{@hsa.id}"]).district_id).name

    health_centres = []
    health_centres = HsaVillage.find(:all, :conditions => ["hsa_id = #{@hsa.id}"]).collect{|hc| hc.health_center_id}
    
    joined_array_a = health_centres.join(',')
    
    hcenter_names = HealthCenter.find(:all, :conditions => ["health_center_id IN (#{joined_array_a})"], :group => [:health_center_id]).collect{|hc| hc.name}
    
    @hsa_details[:health_centre] = hcenter_names

    villages = []
    villages = HsaVillage.find(:all, :conditions => ["hsa_id = #{@hsa.id}"]).collect{|vil| vil.village_id}
    vil_names = []
		
    joined_array = villages.join(',')
    Village.find(:all, :conditions => ["village_id IN (#{joined_array})"], :group => [:village_id]).map do |v| 
    vil_names << v.name
    end

    @hsa_details[:villages] = vil_names

  end

  def edit_demographics
    @hsa = Person.find(params[:id]) rescue nil
    @field = params[:field]
    render :partial => "edit_demographics", :field =>@field, :layout => true and return
  end

  def update_demographics
    #find_by_person_id(params[:id])
    @hsa = Person.find(params[:person_id])
    @user = User.find(params[:person_id])

    case params[:field]
      when "name"
        @hsa_first_name = params[:person][:names][:given_name]
        @hsa_middle_name = params[:person][:names][:middle_name]
        @hsa_last_name = params[:person][:names][:family_name]
        @hsa_name = @hsa_first_name + @hsa_last_name
        
        names_params =  {"given_name" => params[:person][:names][:given_name].to_s,"family_name" => params[:person][:names][:family_name].to_s, "middle_name" => params[:person][:names][:middle_name]}
        @hsa.names.first.update_attributes(names_params) if names_params
        
        #update the username
        @user.update_attributes(:username => "#{@hsa_name.downcase}")
        
        #update the hsa_name
        update_hsa = AllHsaName.find_by_sql("UPDATE all_hsa_name SET given_name = #{params[:person][:names][:given_name]}, family_name = #{params[:person][:names][:family_name]} WHERE hsa_id = #{@hsa.id}")

      when "primary_phone"

        attribute_type = PersonAttributeType.find_by_name("Cell Phone Number").id
        person_attribute = @hsa.person_attributes.find_by_person_attribute_type_id(attribute_type)
        if person_attribute.blank?
          attribute = {'value' => params[:person][:attributes][:cell_phone_number],
                       'person_attribute_type_id' => attribute_type,
                       'person_id' => @hsa.id}
          PersonAttribute.create(attribute)
        else
          person_attribute.update_attributes({'value' => params[:person][:attributes][:cell_phone_number]})
        end

      when "secondary_phone"
        attribute_type = PersonAttributeType.find_by_name("Office Phone Number").id
        person_attribute = @hsa.person_attributes.find_by_person_attribute_type_id(attribute_type)
        if person_attribute.blank?
          attribute = {'value' => params[:person][:attributes][:home_phone_number],
                       'person_attribute_type_id' => attribute_type,
                       'person_id' => @hsa.id}
          PersonAttribute.create(attribute)
        else
          person_attribute.update_attributes({'value' => params[:person][:attributes][:home_phone_number]})
        end

      when "current_district"
        #raise params.to_yaml        
    end

      redirect_to :action => 'edit', :id => @hsa.id and return
  end

  def destroy
   unless request.get?
   @user = User.find(params[:id])
    if @user.update_attributes(:voided => 1, :void_reason => params[:user][:void_reason],:voided_by => session[:user_id],:date_voided => Time.now.to_s)
      flash[:notice]='User has successfully been removed.'
      redirect_to :action => 'voided_list'
    else
      flash[:notice]='User was not successfully removed'
      redirect_to :action => 'destroy'
    end    
   end
  end
  
  def add_role
     @user = User.find(params[:id])
     unless request.get?
        user_role=UserRole.new
        user_role.role = Role.find_by_role(params[:user_role][:role_id])
        user_role.user_id=@user.user_id
        user_role.save
        flash[:notice] = "You have successfuly added the role of #{params[:user_role][:role_id]}"
        redirect_to :action => "show"
      else
      user_roles = UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role.role}
      all_roles = Role.find(:all).collect{|r|r.role}
      @roles = (all_roles - user_roles)
      @show_super_user = true if UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role.role != "superuser" }
   end
  end
  
  def delete_role
    @user = User.find(params[:id])
    unless request.post?
      @roles = UserRole.find_all_by_user_id(@user.user_id).collect{|ur|ur.role.role}
    else
      role = Role.find_by_role(params[:user_role][:role_id]).role
      user_role =  UserRole.find_by_role_and_user_id(role,@user.user_id)  
      user_role.destroy
      flash[:notice] = "You have successfuly removed the role of #{params[:user_role][:role_id]}"
      redirect_to :action =>"show"
    end
  end

  def user_menu
    render(:layout => "layouts/menu")
  end
 
  def search_user
   unless request.get?
     @hsa = HsaName.find(params[:hsa_name])
     redirect_to :action =>"show", :id => @hsa.id
   end
  end
  
  def change_password
    @user = User.find(params[:id])
   
    unless request.get? 
      if (params[:user][:password] != params[:user_confirm][:password])
        flash[:notice] = 'Password Mismatch'
        redirect_to :action => 'new'
        return
      else
        if @user.update_attributes(params[:user])
          flash[:notice] = "Password successfully changed"
          redirect_to :action => "show",:id => @user.id
          return
        else
          flash[:notice] = "Password change failed"  
        end
      end
    end

  end

  def activities
    # Don't show tasks that have been disabled
    @privileges = User.current_user.privileges.reject{|priv| GlobalProperty.find_by_property("disable_tasks").property_value.split(",").include?(priv.privilege)}
    @activities = User.current_user.activities.reject{|activity| GlobalProperty.find_by_property("disable_tasks").property_value.split(",").include?(activity)}
  end
  
  def change_activities
    User.current_user.activities = params[:user][:activities]
    redirect_to(:controller => 'patient', :action => "menu")
  end

end
