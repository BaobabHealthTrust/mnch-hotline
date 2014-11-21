hsas = {"John Mwanza" => { "health_center" => "Kasinje",
                           "phone_numbers" => ["0995141996","0881822805"],
                           "villages" => ["Thunga 1","Kalasa","Kampheko 1","Kampheko 2"]
                            
                          },
        "Lonjezo Mikaya" => { "health_center" => "Kasinje",
                               "phone_numbers" => ["0995704171"], 
                              "villages" => ["Masese 2","Joswa"]
                            } 
=begin
Amos N. Mbewe,
Collins Kathyole,
Charity Kalekeni,
Carvette Mthandi,
William Masina,
Byson Chapotela,
Stella Goma,
Kenneth Mbekwani,
Chrostopher Gunde,
Stella Lukiyo,
Takondwa Nanthowa,
Janet Samaria,
Lucy Bamusi,
Rose Dulani,
James Chimombo,
Taona Bonya,
Everton A. Sesani,
Lenson Chilaya,
Naomi Pendame,
Harry Edson,
Bertha Piphireya,
Madalitso Saiwa,
Agness L. Wazili,
Memory Mawaya,
Willard Malikita,
Tadala Kabanga,
McCharity Nyamambale,
Jennifer Wanje,
Mwandida Mbutoyasulo,
Mary Yotamu,
Lucy Mpaso,
Rose Kachinjika,
Cecelia Dzapita,
Patwel Chiufa,
Hambeck Bendulo,
Nelia Kamadyaapa,
Dyna Mwabumba,
Wezzie Nkhata,
Boston Msamanyada,
Saidi Machila,
Fenita Cham'bwinja,
Shadreck Mapulanga,
Chrissy Lukiyo,
Elias Longwe,
Bettie Wasimbwa,
Richard Samanja,
Vyda Wengawenga,
Godknows Kamdendere,
Lonia Kasimu,
Rose Chikopa,
Sem Chiotcha,
Wallace Midwa,
Angella Kamgwemgwe,
Tennyson W Kaponya,
Beatrice James,
Gabriel Banda,
M. Munama,
Chancy Makawa,
Alexius Matemba,
Merenia Matemba,
Shadreck Chinseu,
Alex D. Nyambi,
Eunice Chilango,
Duncan Amini,
Stanford Chinsewu,
Nelson Kalombe,
Mike Sadya Tembo,
Josophine Kazule,
M. Kalembela,
Yona Nasambo,
Alex Khamba,
Evalisto Milanzi,
Mabvuto Chiputula,
Michael Tennet,
Chisomo S. Mmodzi,
Hawa Sadi,
Lloyd Fodya,
Ali Makwinja,
George Laisi,
Veronica Magugu,
James Barnet,
Yokonia Wilson Chisale,
Mathews Kapalamula,
Nelson Chithagala,
Prisca Mpuzeni,
Fasco Lungu,
Fatima Renso,
Lucy Sagawa,
Aaron Chikanga,
John Matumbo,
Mike Kachale,
Lawrence Muhamah,
Paul Nyambalo,
Magret Nyambalo,
McDonald Mang'anda,
Manfred Malenga,
Monica Mtekama,
Lloyd Chilewani,
Chrissy Ntchafu,
Lizzie Ngozo,
Grace Mwale,
Alfred Kaponya,
Grace Samanyika,
Zaria Babu,
Annie Banda,
Vincent Namaombe,
Selemani Malope,
Maggie Munde,
Lyson Wasusa,
Steven Misodi Phiri,
C.D. Maulana,
Esther Nsona 
=end
}




hsas.each do |key,value|
  puts key.split(" ").inspect
end

=begin
session[:user_edit] = nil
    existing_user = User.find(:first, :conditions => {:username => params[:user][:username]}) rescue nil

    if existing_user
      flash[:notice] = 'Username already in use'
      redirect_to :action => 'new'
      return
    end
    
    if (params[:user][:password] != params[:user_confirm][:password])
      flash[:notice] = 'Password Mismatch'
      redirect_to :action => 'new'
      return
    #  flash[:notice] = nil
      @user_first_name = params[:person_name][:given_name]
#      @user_middle_name = params[:user][:middle_name]
      @user_last_name = params[:person_name][:family_name]
      @user_role = params[:user_role][:role_id]
      @user_admin_role = params[:user_role_admin][:role]
      @user_name = params[:user][:username]
    end
    cellphone_number = params[:user].delete(:cell_phone_number) if  params[:user][:cell_phone_number].present?
    person = Person.create()
    person.names.create(params[:person_name])
    params[:user][:user_id] = person.id
    @user = User.new(params[:user])
    @user.id = person.id
    
    unless cellphone_number.blank?
          attribute_type_id  = PersonAttributeType.find_by_name("Cell Phone Number").person_attribute_type_id
          person.person_attributes.create(:person_attribute_type_id => attribute_type_id, :value => cellphone_number)
    end
    
    if @user.save
     # if params[:user_role_admin][:role] == "Yes"  
      #  @roles = Array.new.push params[:user_role][:role_id] 
       # @roles << "superuser"
       # @roles.each{|role|
       # user_role=UserRole.new
       # user_role.role_id = Role.find_by_role(role).role_id
       # user_role.user_id=@user.user_id
       # user_role.save
      #}
      #else
        user_role=UserRole.new
        user_role.role = Role.find_by_role(params[:user_role][:role_id])
        user_role.user_id=@user.user_id
        user_role.save
     # end
      @user.update_attributes(params[:user])
=end      
