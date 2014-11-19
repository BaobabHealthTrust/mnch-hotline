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


health_centers = ["Kasinje","Kankao", "Mbera", "Nsiyaludzu", "Phalula", "Sharpvalley"]


hsas = {"John D. Mwanza" => { 
                              :district => districts[1],
                              :health_center => health_centers[0],
                              :phone_numbers => ["0995141996","0881822805"],
                              :villages => ["Thunga 1","Kalasa","Kampheko 1","Kampheko 2"]
                            
                            },
                          
        "Lonjezo Mikaya" => { 
                              :district => districts[1],
                              :health_center => health_centers[0],
                              :phone_numbers => ["0995704171"], 
                              :villages => ["Masese 2","Joswa"]
                            }, 

        "Amos N. Mbewe" => {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Gwaza"]      
                           },

        "Collins Kathyole" => {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Fala"]
                           
                            },

        "Charity Kalekeni" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Matsatsa"]
                           
                            },
                            
        "Carvette Mthandi" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Manjanja"]
                           
                            },

        "William Masina" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Mfuti","Mbululu"]
                           
                            },

        "Byson Chapotela" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Kachinjika","Mbonela"]
                           
                            },

        "Stella Goma" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Thunga 2","Mzalimbo", "Kambaule", "Kamowa", "Kachilomo", "Chindikano", "Thunga 3"]
                           
                            },

        "Kenneth Mbekwani" = {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Mtambalika 1", "Mtambalika 2", "Mtambalika 3"]
                           
                            },

        "Chrostopher Gunde" => {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Chauluka"]
                           
                            },

        "Stella Lukiyo" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Jeza", "Nandaya", "Kamtandiro"]
                           
                            },

        "Takondwa Nanthowa" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Mchocho", "Makanga", "Bwalo"]
                           
                            },
                            
        "Janet Samaria" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Chinkhumba", "Kapenga", "Chiwembu", "Gwetsa"]
                           
                            },

        "Lucy Bamusi" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Foso", "Chipula", "Kalumbu", "Thondoya", "Sononjala"]
                           
                            },

        "Rose Dulani" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Kamlangila", "Ganya", "Mgomba", "Cheuka 2", "Donyo"]
                           
                            },

        "James Chimombo" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
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
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Mafuwa", "Lumwira", "Kalimbika", "Ndalamila"]
                           
                            },

        "Lenson Chilaya" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Kasinje 2"]
                           
                            },

        "Naomi Pendame" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Kosamu"]
                           
                            },

        "Harry Edson" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Kambewa"]
                           
                            },

        "Bertha Piphireya" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Chipinga"]
                           
                            },

        "Madalitso Saiwa" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Chikuli"]
                           
                            },

        "Agness L. Wazili" => {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Cheuka 1"]
                           
                            },

        "Memory Mawaya" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["kamgomo"]
                           
                            },
                            
        "Willard Malikita" => {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Kasinje 1"]
                           
                            },

        "Tadala Kabanga" =>  {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Nasala"]
                           
                            },

        "McCharity Nyamambale" {
                            :district => districts[1],
                            :health_center => health_centers[0],
                            :phone_numbers => [],
                            :villages => ["Khwiya", "Folotiya"]
                           
                            },
                            
        "Jennifer Wanje" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Solomon Kuyenda", "Kafantipite"]
                           
                            },

        "Mwandida Mbutoyasulo" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Gomeya", "Ntcheza"]
                           
                           },

        "Mary Yotamu" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Ngwangwa","Goveya", "Mpakiza 1", "Mpakiza 2"]
                           
                         },
    
        "Lucy Mpaso" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Kauwa"]
                           
                          },

        "Rose Kachinjika" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Gumbi 1", "Gumbi 2"]
                           
                          },

        "Cecelia Dzampita" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Sabwera 1","Elia" ,"Balaka 1"]
                           
                          },

        "Patwel Chiufa" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Sotchaya", "Adam", "Chidaya"]
                           
                          },

        "Hambeck Bendulo" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Chokazinga","Gomeya 2","Chimkutika"]
                           
                          },

        "Nelia Kamadyaapa" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Siliya", "Gunde", "Muyenga"]
                           
                          },

        "Dyna Mwabumba" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Gwaza 1", "Masasa"]
                           
                          },

        "Wezzie Nkhata" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Alasala 2", "Sabwera 2"]
                           
                          },

        "Boston Msamanyada" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => [""]
                           
                          },

        "Saidi Machila" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => [""]
                           
                          },

        "Fenita Cham'bwinja" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Makokola","Dinala", "Tseka"]
                           
                          },

        "Shadreck Mapulanga" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Nsiyaludzu 1", "Nsiyaludzu 2"]
                           
                          },

        "Chrissy Lukiyo" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Mberengwa", "Alasala 1", "James Ipu"]
                           
                          },

        "Elias Longwe" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Chinzakadzi", "Balaka 2"]
                           
                          },
                          
        "Bettie Wasimbwa" => {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Kabwazi","Bubuwa"]
                           
                          },

        "Richard Samanja" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Hellani", "Ntentha", "Mtila"]
                           
                          },

        "Vyda Wengawenga" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["K. Malele", "Chauluka 1"]
                           
                          },

        "Godknows Kamdendere" =>  {
                            :district => districts[1],
                            :health_center => health_centers[3],
                            :phone_numbers => [],
                            :villages => ["Chauluka 2", "Gwaza 2"]
                           
                          },

        "Lonia Kasimu" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Saiwala", "Amin" , "Makuta", "Likwakwala"]
                           
                           },

        "Rose Chikopa" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Kanyanga","Wadi - Simbota","Masulamanja", "Kafisi"]
                           
                           },

        "Sem Chiotcha" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Chilimani","Chiganga"]
                           
                           },

        "Wallace Midwa" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Gerald", "Karonga" ,"Dula" ,"Mwalabu", "Amanu","Awachisa","Salimu"]
                           
                           },

        "Angella Kamgwemgwe" =>{
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Misomali", "Katuma"]
                           
                           },

        "Tennyson W Kaponya" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Chipote", "Harry", "Pongolani", "Mpambe", "Kusauchi"]
                           
                           },

        "Beatrice James" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Masese", "Duncan", "Nsanja"]
                           
                           },

        "Gabriel Banda" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Chipwere", "Mthumba"]
                           
                           },

        "M. Munama" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Kaisi", "Wadi-Pyoli", "Chipatala", "Chiphwanya"]
                           
                           },

        "Chancy Makawa" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Mpalasa","Misozi","Kuchambe","Thunga","Palira","Augustine","Ndanga","Silika","Makupe",
                                          "Ngwangwa","Chimoto","Sambani","Moleni","Mfundenji","Jere","Kamwendo","Kaduya","Sitima",
                                          "Umali","Matiki","Magwira","Chapweteka","Fala"]
                           
                           },

        "Alexius Matemba" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Mpinganjila","Mbaza","Nkagamba","Ntila","Kanyinduli","Kwaweleza","Nyalugwe","Misikizi",
                                           "Makwana"]
                           
                           },

        "Merenia Matemba" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Mdera", "Elephasi","Jonathan","Kasani","Sailesi","Nyanyika"]
                           
                           },

        "Shadreck Chinseu" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Chaima","Chipole","Muli", "Chiwalo"]
                           
                           },

        "Alex D. Nyambi" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Chikamana", "Kachenga","Nkalawire","Kimu","Mkwatula","Mwachande"]
                           
                           },

        "Eunice Chilango" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Muotcha","Mgambo","Mnanala","Sinklea","Kamowa"]
                           
                           },

        "Duncan Amini" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Chamba","Chimkwita","Botomani","Mlanga","Thawale"]
                           
                           },

        "Stanford Chinsewu" =>{
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Mpoto","Chikalogwe"]
                           
                           },

        "Nelson Kalombe" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Hambahamba","Zalengela","Daudi","Samvera","Kutsamba","Adam","Malaza"]
                           
                           },

        "Mike Sadya Tembo" =>{
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Mgwira", "Chisasiko","Changwa","Nduwa","Kambaule","Juma","Mchelewatha", "Mchambo "]
                           
                           },

        "Josophine Kazule" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Mizinga","Makande","Matembera","Minama","Mawecha","Maluchila"]
                           
                           },

        "M. Kalembela" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
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
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Matemba","Anderson""Chongolera","Maliko","Kukada"]
                           
                           },

        "Evalisto Milanzi" =>{
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Mbera","Saidison","Mkwera","Sikawandeu","Kado"]
                           
                           },

        "Mabvuto Chiputula" =>{
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Chipojola","Kalambo","Alichapola","Chikumba","Sanudi","Mbalu"]
                           
                           },

        "Michael Tennet" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Mpamasi","Machemba","Kamoto","Saidi"]
                           
                           },

        "Chisomo S. Mmodzi" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Lemu","Moyo","Maperera","Chilobwe","Assani"]
                           
                           },

        "Hawa Sadi" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Jumbe","Jenya","Sanza","Chagomelana"]
                           
                           },

        "Lloyd Fodya" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Mtumbwe","Malindima","Nsigalira"]
                           
                           },
                           
        "Ali Makwinja" => {
                            :district => districts[0],
                            :health_center => health_centers[2],
                            :phone_numbers => [""],
                            :villages => ["Herbert","Chiwanda","Kabota","Milepa","Chimtengo","Siyaya"]
                           
                           },

        "George Laisi" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => ["Lakalaka","Chimbalanga","Nkhundira","Mkweya","Magoti"]
                           
                           },

        "Veronica Magugu" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => ["Madyelatu","Malakamu","Chimphonda","Chizunguchino","kankao","Kambadya 1","Kambadya 2"]
                           
                           },

        "James Barnet" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => ["Mitochi","Kalimbuka","James","Mitchaya","Nambazo","Chitala"]
                           
                           },

        "Yokonia Wilson Chisale" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
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
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },

        "Prisca Mpuzeni" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },

        "Fasco Lungu" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },

        "Fatima Renso" =>{
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },

        "Lucy Sagawa" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },
                           
        "Aaron Chikanga" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },
        "John Matumbo" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },
                           
        "Mike Kachale" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },

        "Lawrence Muhamah" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },
                           
        "Paul Nyambalo" =>{
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },

        "Magret Nyambalo" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },

        "McDonald Mang'anda" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },
        "Manfred Malenga" => {
                            :district => districts[0],
                            :health_center => health_centers[1],
                            :phone_numbers => [""],
                            :villages => [""]
                           
                           },

        "Monica Mtekama" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Lloyd Chilewani" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Chrissy Ntchafu" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Lizzie Ngozo" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Grace Mwale" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Alfred Kaponya" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Grace Samanyika" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Zaria Babu" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Annie Banda" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Vincent Namaombe" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Selemani Malope" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Maggie Munde" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Lyson Wasusa" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Steven Misodi Phiri" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "C.D. Maulana" => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        },

        "Esther Nsona " => {
                            :district => districts[],
                            :health_center => health_centers[],
                            :phone_numbers => [],
                            :villages => []
                           
        }
 
}  


creator = 1
hsas.each do |key,value|
      #raise key.split(" ").join.gsub(".","").downcase.inspect
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
      user = User.find_by_username(username).id rescue nil
       if user.blank?
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
       else    
          user_role = UserRole.find_by_user_id_and_role(user.user_id,"HSA") rescue nil
          if user_role.blank?
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
           end 
       end
   
   
      
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
