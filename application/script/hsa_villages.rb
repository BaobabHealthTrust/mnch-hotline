districts = ["Balaka","Ntcheu"]

districts.each do |district|
    district_id = District.find_by_name(district).id
    ta = TraditionalAuthority.find_by_name_and_district_id("Hotline Pilot",district_id)
    if ta.blank?
        hotline_ta = TraditionalAuthority.new
        hotline_ta.district_id = district_id
        hotline_ta.name = "Hotline Pilot"
        hotline_ta.date_created = Date.today();
        hotline_ta.creator = 1
        hotline_ta.save
        puts "created Hotline Pilot TA for: #{district}"
    else
       puts "Hotline Pilot TA for #{district} already exists"
    end
end


t_as = ["Matsatsa", "Ganya", "Kalembo", "Simbota", "Sawali", "Makwangwala", "Chamthunya"]

health_centers = ["Kasinje","Kankao", "Mbera", "Nsiyaludzu", "Phalula", "Sharpvalley"]



hsas = {"John D. Mwanza" => { 
                              :district => districts[1],
                              :health_center => health_centers[0],
                              :phone_numbers => ["0995141996","0881822805   "],
                              :villages => ["Thunga 1","Kalasa","Kampheko 1","Kampheko 2"]
                            
                            },
                          
        "Lonjezo Mikaya" => { 
                              :district => districts[1],
                              :ta => t_as[0],
                              :health_center => health_centers[0],
                              :phone_numbers => ["0995704171"], 
                              :villages => ["Masese 2","Joswa"]
                            }, 

        "Amos N. Mbewe" => {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0999287343"],
                            :villages => ["Gwaza"]      
                           },

        "Collins Kathyole" => {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0999384177"],
                            :villages => ["Fala"]
                           
                            },

        "Charity Kalekeni" =>  {
                            :district => districts[1],
                            :ta => t_as[0],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0995325765"],
                            :villages => ["Matsatsa"]
                           
                            },
                            
        "Carvette Mthandi" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0993173065","0884105908"],
                            :villages => ["Manjanja"]
                           
                            },

        "William Masina" =>  {
                            :district => districts[1],
                            :ta => t_as[0],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0991251046"],
                            :villages => ["Mfuti","Mbululu"]
                           
                            },

        "Byson Chapotela" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0998746312"],
                            :villages => ["Kachinjika","Mbonela"]
                           
                            },

        "Stella Goma" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0993005645"],
                            :villages => ["Thunga 2","Mzalimbo", "Kambaule", "Kamowa", "Kachilomo", "Chindikano", "Thunga 3"]
                           
                            },

        "Kenneth Mbekwani" => {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0999145341"],
                            :villages => ["Mtambalika 1", "Mtambalika 2", "Mtambalika 3"]
                           
                            },

        "Christopher Gunde" => {
                            :district => districts[1],
                            :ta => t_as[0],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0999161053"],
                            :villages => ["Chauluka"]
                           
                            },

        "Stella Lukiyo" =>  {
                            :district => districts[1],
                            :ta => t_as[0],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0995801315"],
                            :villages => ["Jeza", "Nandaya", "Kamtandiro"]
                           
                            },

        "Takondwa Nanthowa" =>  {
                            :district => districts[1],
                            :ta => t_as[0],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0999486378"],
                            :villages => ["Mchocho", "Makanga", "Bwalo"]
                           
                            },
                            
        "Janet Samaria" =>  {
                            :district => districts[1],
                            :ta => t_as[0],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0994426442"],
                            :villages => ["Chinkhumba", "Kapenga", "Chiwembu", "Gwetsa"]
                           
                            },

        "Lucy Bamusi" =>  {
                            :district => districts[1],
                            :ta => t_as[0],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0995140196"],
                            :villages => ["Foso", "Chipula", "Kalumbu", "Thondoya", "Sononjala"]
                           
                            },

        "Rose Dulani" =>  {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0996551872"],
                            :villages => ["Kamlangila", "Ganya", "Mgomba", "Cheuka 2", "Donyo"]
                           
                            },

        "James Chimombo" =>  {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0999499058","0888195525"],
                            :villages => ["Chifwiri"]
                           
                            },

        "Taona Bonya" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Kamwetsa"]
                           
                            },

        "Everton A. Sesani" =>  {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0996037049"],
                            :villages => ["Mafuwa", "Lumwira", "Kalimbika", "Ndalamila"]
                           
                            },

        "Lenson Chilaya" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0997349239"],
                            :villages => ["Kasinje 2"]
                           
                            },

        "Naomi Pendame" =>  {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0995671212"],
                            :villages => ["Kosamu"]
                           
                            },

        "Harry Edson" =>  {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0999698227"],
                            :villages => ["Kambewa"]
                           
                            },

        "Bertha Piphireya" =>  {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0994539574"],
                            :villages => ["Chipinga"]
                           
                            },

        "Madalitso Saiwa" =>  {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0995675384"],
                            :villages => ["Chikuli"]
                           
                            },

        "Agness L. Wazili" => {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0993700174"],
                            :villages => ["Cheuka 1"]
                           
                            },

        "Memory Mawaya" =>  {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0993757058"],
                            :villages => ["kamgomo"]
                           
                            },
                            
        "Willard Malikita" => {
                            :district => districts[1],
                            :ta => t_as[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0999607718"],
                            :villages => ["Kasinje 1"]
                           
                            },

        "Tadala Kabanga" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0999692621"],
                            :villages => ["Nasala"]
                           
                            },

        "McCharity Nyamambale" => {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => ["0881691835"],
                            :villages => ["Khwiya", "Folotiya"]
                           
                            },
                            
        "Jennifer Wanje" => {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0884015195"],
                            :villages => ["Solomon Kuyenda", "Kafantipite"]
                           
                            },

        "Mwandida Mbutoyasulo" => {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0882868150"	,"0994178848"],
                            :villages => ["Gomeya", "Ntcheza"]
                           
                           },

        "Mary Yotamu" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0994867949"],
                            :villages => ["Ngwangwa","Goveya", "Mpakiza 1", "Mpakiza 2"]
                           
                         },
    
        "Lucy Mpaso" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0999119121"],
                            :villages => ["Kauwa"]
                           
                          },

        "Rose Kachinjika" =>  {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0992535827"],
                            :villages => ["Gumbi 1", "Gumbi 2"]
                           
                          },

        "Cecelia Dzampita" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0999050322"],
                            :villages => ["Sabwera 1","Elia" ,"Balaka 1"]
                           
                          },

        "Patwel Chiufa" =>  {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0884532766"],
                            :villages => ["Sotchaya", "Adam", "Chidaya"]
                           
                          },

        "Hambeck Bendulo" => {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0995227390"],
                            :villages => ["Chokazinga","Gomeya 2","Chimkutika"]
                           
                          },

        "Nelia Kamadyaapa" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0993807671"],
                            :villages => ["Siliya", "Gunde", "Muyenga"]
                           
                          },

        "Dyna Mwabumba" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0888169139"],
                            :villages => ["Gwaza 1", "Masasa"]
                           
                          },

        "Wezzie Nkhata" =>  {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0881115397"],
                            :villages => ["Alasala 2", "Sabwera 2"]
                           
                          },

        "Boston Msamanyada" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0992953069"],
                            :villages => ["Makokola","Dinala","Tseka"]
                           
                          },

        "Saidi Machila" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0992536867"],
                            :villages => ["James Mazunga","Chimutu"]
                           
                          },

        "Fenita Cham'bwinja" =>  {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0888353789"],
                            :villages => ["Makokola","Dinala", "Tseka"]
                           
                          },

        "Shadreck Mapulanga" =>  {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0993258410"],
                            :villages => ["Nsiyaludzu 1", "Nsiyaludzu 2"]
                           
                          },

        "Chrissy Lukiyo" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0884358499"],
                            :villages => ["Mberengwa", "Alasala 1", "James Ipu"]
                           
                          },

        "Elias Longwe" =>  {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0999376270"],
                            :villages => ["Chinzakadzi", "Balaka 2"]
                           
                          },
                          
        "Bettie Wasimbwa" => {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0999176270"],
                            :villages => ["Kabwazi","Bubuwa"]
                           
                          },

        "Richard Samanja" =>  {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Hellani", "Ntentha", "Mtila"]
                           
                          },

        "Vyda Wengawenga" =>  {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0999176270"],
                            :villages => ["K. Malele", "Chauluka 1"]
                           
                          },

        "Godknows Kamdendere" =>  {
                            :district => districts[1],
                            :ta => t_as[5],
                            :health_center => health_centers[3],
                            :phone_numbers => ["0991146137"],
                            :villages => ["Chauluka 2", "Gwaza 2"]
                           
                          },

        "Lonia Kasimu" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Saiwala", "Amin" , "Makuta", "Likwakwala"]
                           
                           },

        "Rose Chikopa" => {
                            :district => districts[0],
                            :ta => t_as[3],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0888180160"],
                            :villages => ["Kanyanga","Wadi - Simbota","Masulamanja", "Kafisi"]
                           
                           },

        "Sem Chiotcha" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0881030317","0991448104"],
                            :villages => ["Chilimani","Chiganga"]
                           
                           },

        "Wallace Midwa" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0888760452"],
                            :villages => ["Gerald", "Karonga" ,"Dula" ,"Mwalabu", "Amanu","Awachisa","Salimu"]
                           
                           },

        "Angella Kamgwemgwe" =>{
                            :district => districts[0],
                            :ta => t_as[4],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0999447254"],
                            :villages => ["Misomali", "Katuma"]
                           
                           },

        "Tennyson W Kaponya" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0884710783"],
                            :villages => ["Chipote", "Harry", "Pongolani", "Mpambe", "Kusauchi"]
                           
                           },

        "Beatrice James" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0999166494"],
                            :villages => ["Masese", "Duncan", "Nsanja"]
                           
                           },

        "Gabriel Banda" => {
                            :district => districts[0],
                            :ta => t_as[4],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0997958476","0881706875"],
                            :villages => ["Chipwere", "Mthumba"]
                           
                           },

        "M. Munama" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0881749416", "0998444996"],
                            :villages => ["Kaisi", "Wadi-Pyoli", "Chipatala", "Chiphwanya"]
                           
                           },

        "Chancy Makawa" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0997958511"],
                            :villages => ["Mpalasa","Misozi","Kuchambe","Thunga","Palira","Augustine","Ndanga","Silika","Makupe",
                                          "Ngwangwa","Chimoto","Sambani","Moleni","Mfundenji","Jere","Kamwendo","Kaduya","Sitima",
                                          "Umali","Matiki","Magwira","Chapweteka","Fala"]
                           
                           },

        "Alexious Matemba" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0881824766"],
                            :villages => ["Mpinganjila","Mbaza","Nkagamba","Ntila","Kanyinduli","Kwaweleza","Nyalugwe","Misikizi",
                                           "Makwana"]
                           
                           },

        "Merenia Matemba" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0999057223"],
                            :villages => ["Mdera", "Elephasi","Jonathan","Kasani","Sailesi","Nyanyika"]
                           
                           },

        "Shadreck Chinseu" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0997958517"],
                            :villages => ["Chaima","Chipole","Muli", "Chiwalo"]
                           
                           },

        "Alex D. Nyambi" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0888050974"],
                            :villages => ["Chikamana", "Kachenga","Nkalawire","Kimu","Mkwatula","Mwachande"]
                           
                           },

        "Eunice Chilango" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0999053618"],
                            :villages => ["Muotcha","Mgambo","Mnanala","Sinklea","Kamowa"]
                           
                           },

        "Duncan Amini" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0999171514", "0882575216"],
                            :villages => ["Chamba","Chimkwita","Botomani","Mlanga","Thawale"]
                           
                           },

        "Stanford Chinsewu" =>{
                            :district => districts[0],
                            :ta => t_as[4],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0888100955"],
                            :villages => ["Mpoto","Chikalogwe"]
                           
                           },

        "Nelson Kalombe" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0991950916"],
                            :villages => ["Hambahamba","Zalengela","Daudi","Samvera","Kutsamba","Adam","Malaza"]
                           
                           },

        "Mike Sadya Tembo" =>{
                            :district => districts[0],
                            :ta => t_as[4],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0991570139", "0882335199"],
                            :villages => ["Mgwira", "Chisasiko","Changwa","Nduwa","Kambaule","Juma","Mchelewatha", "Mchambo "]
                           
                           },

        "Josophine Kazule" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0881073271"],
                            :villages => ["Mizinga","Makande","Matembera","Minama","Mawecha","Maluchila"]
                           
                           },

        "M. Kalembela" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0882171618"],
                            :villages => ["Abudu", "Chulu","Mtota","James","Henderson"]
                           
                           },

        "Yona Nasambo" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Pyoli","Chirombo","Sikero","Kumpinda","Kachepa","Nambazo"]
                           
                           },

        "Alex Khamba" => {
                            :district => districts[0],
                            :ta => t_as[4],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0999794774","0884344550"],
                            :villages => ["Matemba","Anderson""Chongolera","Maliko","Kukada"]
                           
                           },

        "Evalisto Milanzi" =>{
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0884228383"],
                            :villages => ["Mbera","Saidison","Mkwera","Sikawandeu","Kado"]
                           
                           },

        "Mabvuto Chiputula" =>{
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0888365641"],
                            :villages => ["Chipojola","Kalambo","Alichapola","Chikumba","Sanudi","Mbalu"]
                           
                           },

        "Michael Tennet" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0882280113"],
                            :villages => ["Mpamasi","Machemba","Kamoto","Saidi"]
                           
                           },

        "Chisomo S. Mmodzi" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0999057222"],
                            :villages => ["Lemu","Moyo","Maperera","Chilobwe","Assani"]
                           
                           },

        "Hawa Sadi" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0881531994"],
                            :villages => ["Jumbe","Jenya","Sanza","Chagomelana"]
                           
                           },

        "Lloyd Fodya" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0888978250"],
                            :villages => ["Mtumbwe","Malindima","Nsigalira"]
                           
                           },
                           
        "Ali Makwinja" => {
                            :district => districts[0],
                            :ta => t_as[2],
                            :health_center => health_centers[2],
                            :phone_numbers => ["0884466100"],
                            :villages => ["Herbert","Chiwanda","Kabota","Milepa","Chimtengo","Siyaya"]
                           
                           },

        "George Laisi" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0991960091"],
                            :villages => ["Lakalaka","Chimbalanga","Nkhundira","Mkweya","Magoti"]
                           
                           },

        "Veronica Magugu" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0999457733"],
                            :villages => ["Madyelatu","Malakamu","Chimphonda","Chizunguchino","kankao","Kambadya 1","Kambadya 2"]
                           
                           },

        "James Barnet" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0991799043"],
                            :villages => ["Mitochi","Kalimbuka","James","Mitchaya","Nambazo","Chitala"]
                           
                           },

        "Yokonia Wilson Chisale" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0999632943","0881559793"],
                            :villages => ["Msakanena","Namikombe","Ngwalu 2","Phasule","Kuntenjera","Chibwana","Tembani","Kunjawa"]
                           
                           },

        "Mathews Kapalamula" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => ["Mponda","Chimpakati","Mataya","Gamwero","Ndawa","Chitati"]
                           
        },

        "Nelson Chithagala" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0884864176"],
                            :villages => ["Chiyembekezo","Mzito","Manyikula","Mlero","Selemani","Chiganga"]
                           
                           },

        "Prisca Mpuzeni" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0998080432"],
                            :villages => ["Siliya","Nsaka","Grey","Kapoloma","Kamyata","Gobede","Chin'gamba","Pilato","Zangaphee"]
                           
                           },

        "Fasco Lungu" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0881265402"],
                            :villages => ["Namayesa","Sopera","Mmora","Chimimba","Kapuku","Kachingwe","Zimveka","Chikhwaya","Chitsulo"]
                           
                           },

        "Fatima Renso" =>{
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0999607751","0888609353"],
                            :villages => ["Manjanja","Chaola","Jambawe","Muoza","Kwalakwata","Chaweka","Same"]
                           
                           },

        "Lucy Sagawa" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0884329352"],
                            :villages => ["Zandeya","Njilayagoma","Chida","Kantande","Mombo","Kachomba"]
                           
                           },
                           
        "Aaron Chikanga" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0991950941"],
                            :villages => ["Tsanyaoyela","Mulunguzi","Thindili","Majia"]
                           
                           },
        "John Matumbo" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0888883597","0999716293"],
                            :villages => ["Namitumbo","Mphenzi","Mfulanjovu","M'mangeni","Mulanda"]
                           
                           },
                           
        "Mike Kachale" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0999090840","0888607561"],
                            :villages => ["Uyele","Mbonani","Nantchengwa","Manyombe","Ngoleka","Linzie"]
                           
                           },

        "Lawrence Muhamah" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0888335399","0999120075"],
                            :villages => ["Khoswe","Chiputula","Pakamwa","Kanongwa","Sakaiko","Makalaudi","Zammimba","Kodo"]
                           
                           },
                           
        "Paul Nyambalo" =>{
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0999330020","0888419960"],
                            :villages => ["Fulaye","Thom","Nakapa","John","Chizinga","Changadeya"]
                           
                           },

        "Magret Nyambalo" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0993222084","0882104389"],
                            :villages => ["Rabson","Chingagwe","Joshua","Otala","Langwani","Kathumba","Chiondo"]
                           
                           },

        "McDonald Mang'anda" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0881132164","0998003134"],
                            :villages => ["Ntondokera","Ngongomwa","Bwemba"]
                           
                           },
        "Manfred Malenga" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => ["0882062881","0998298254"],
                            :villages => ["Mzamani","Mdelezina","Mgoza","Masenjele"]
                           
                           },

        "Monica Mtekama" => {
                            :district => districts[0],
                            :ta => t_as[6],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0999373853"],
                            :villages => ["Mazenga","Kathambo"]
                           
                            },

        "Lloyd Chilewani" => {
                            :district => districts[0],
                            :ta => t_as[6],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0991950991"],
                            :villages => ["Nyanyala 1","Sikenala","Nyanya 2","Thamangira 1","Yolomoni","Thamangira 2","Kamvetsa",
                                           "Kankuwe","Beni"]
                           
                            },
                            
        "Chrissy Ntchafu" => {
                            :district => districts[0],
                            :ta => t_as[6],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0888949469"	,"0999193542"],
                            :villages => ["Phombeya", "Mpandasoni/Tchodola","Yonamu"]
                           
                            },

        "Lizzie Ngozo" => {
                            :district => districts[0],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0884294970"],
                            :villages => ["Kameza","Mpambira","Chikwiri","Chikaoneka","Sungani","Mkaluluka"]
                           
                            },

        "Grace Mwale" => {
                            :district => districts[0],
                            :ta => t_as[6],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0884265072"],
                            :villages => ["Ayanjaawo","Chiwengana","Chizungu 1"]
                           
                            },

        "Alfred Kaponya" => {
                            :district => districts[0],
                            :ta => t_as[6],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0999177162","0884872296"],
                            :villages => ["Kainga", "Nkhande", "Kunyalani"]
                           
                            },

        "Grace Samanyika" => {
                            :district => districts[0],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0884161588"],
                            :villages => ["Govati","Chaima","Chingodzi","Kumkwawa"]
                           
                            },

        "Zaria Babu" => {
                            :district => districts[0],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0995133060"],
                            :villages => ["Kavala 1","Kavala 2","Chikondi","Vuvuta","Chiyembekezo","Kusheto","Mwaligula"]
                           
                            },

        "Annie Banda" => {
                            :district => districts[0],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0999430778"],
                            :villages => ["Chigonamdowe Pofela","Tchona Yebele","Ndungunde","Khazibeti","Yambani"]
                           
                            },

        "Vincent Namaombe" => {
                            :district => districts[0],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0992623006"],
                            :villages => ["Mthengomwacha 1","Mthengomwacha 2","Mateyu","Kachingwe","Makokola"]
                           
                            },

        "Selemani Malope" => {
                            :district => districts[0],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0884456122"],
                            :villages => ["Phalula","Bengo","Senjere"]
                           
                            },
                            
        "Maggie Munde" => {
                            :district => districts[0],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0888617531"],
                            :villages => ["Ntundu","Limbani","Mundila","Chizungu","Mpitanjala"]
                           
                            },

        "Lyson Wasusa" => {
                            :district => districts[0],
                            :ta => t_as[6],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0995496050"],
                            :villages => ["Bamusi","Tererakaso","Ipendo","Kasamiza","Sanudi","Chikamera"]
                           
                            },

        "Steven Misodi Phiri" => {
                            :district => districts[0],
                            :ta => t_as[6],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0991950943"],
                            :villages => ["Tsite","Chitimbe","Zacharia","Moses"]
                           
                            },

        "C.D. Maulana" => {
                            :district => districts[0],
                            :ta => t_as[6],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0881036044"],
                            :villages => ["Chitala"]
                           
                            },

        "Esther Nsona " => {
                            :district => districts[0],
                            :ta => t_as[6],
                            :health_center => health_centers[4],
                            :phone_numbers => ["0881533642"],
                            :villages => ["Chandikola", "Massa"]
                           
                            },
 
}  


creator = 1
HsaVillage.delete_all
hsas.each do |key,value|
      hsa_name = key.split(" ")
         
      person = Person.new
      person.creator = creator
      person.date_created = Date.today()
      person.save
      
      puts "Create HSA Person : #{key}"
      
      person_name = PersonName.new
      person_name.person_id = person.id
      person_name.given_name = hsa_name.first
      person_name.family_name = hsa_name.last
      person_name.middle_name = hsa_name.second if hsa_name.length == 3 
      person_name.creator = creator
      person_name.date_created = Date.today() 
      person_name.save
      
      puts "Created HSA Person :  #{key} "
      
      value[:phone_numbers].each_with_index do |phone_number,i|
          phone_number_type = i > 0 ? "Office Phone Number" : "Cell Phone Number"
          attribute_type_id  = PersonAttributeType.find_by_name(phone_number_type).person_attribute_type_id
          person_attribute = PersonAttribute.new()
          person_attribute.value = phone_number
          person_attribute.person_attribute_type_id = attribute_type_id
          person_attribute.creator = creator
          person_attribute.person_id = person.id
          person_attribute.date_created = Date.today()
          person_attribute.save
          puts "Created HSA #{phone_number_type.split("_").join} : #{phone_number} "
       end
      
         username = key.split(" ").join.gsub(".","").downcase
      
         user = User.new
         user.id = person.id
         user.creator = creator
         user.username = key.split(" ").join.gsub(".","").downcase
         user.password = user.username
         user.date_created = Date.today
         user.save
         puts "Created HSA User :  #{user.username} "
         
         user_role = UserRole.new
         user_role.role = Role.find_by_role("HSA")
         user_role.user_id = user.user_id
         user_role.save
      
         puts "Created HSA User Role :  #{user.username}" 
             
     value[:villages].each do |village|
       village_id = Village.find_by_name(village).id rescue nil
       if village_id.blank?
        ta = TraditionalAuthority.find_by_name_and_district_id("Hotline Pilot",District.find_by_name(value[:district]))
        new_village = Village.new
        new_village.name = village
        new_village.traditional_authority_id = ta.id
        new_village.creator = creator
        new_village.date_created = Date.today()
        new_village.save
        village_id = new_village.village_id 
        puts "Created Village : #{new_village.name} for #{value[:district]}"
       end
       
       district_id = District.find_by_name(value[:district]).id
       health_center_id = HealthCenter.find_by_name(value[:healthcenter]).id rescue nil
       if health_center_id.blank?
        new_health_center = HealthCenter.new
        new_health_center.name = value[:health_center]
        new_health_center.district = district_id
        new_health_center.save
        health_center_id = new_health_center.health_center_id
       end
       
       hsa_village = HsaVillage.create({:hsa_id => user.user_id,
                                       :village_id => village_id, 
                                       :health_center_id => health_center_id , 
                                       :district_id => district_id })
                                       
       puts "Created HSA village"                                  
     
     end     
end
