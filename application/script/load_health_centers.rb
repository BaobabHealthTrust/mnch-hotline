require "fastercsv"
require 'yaml'

LOG_FILE = RAILS_ROOT + '/log/health_centers.log'


def read_config
  @hc_file_location = RAILS_ROOT + '/script'
end

def initialize_variables

  print_time("initialization started")
  
  read_config

  print_time("Initialization ended")
end

def log(msg)
  system("echo \"#{msg}\" >> #{LOG_FILE}")
end

def print_time(message)
  @time = Time.now
  log "H/C insert-----#{message} at - #{@time} -----"
end

def insert_health_centers

	begin
		FasterCSV.foreach(@hc_file_location + '/malawi_health_facilities.csv', :headers => true,:col_sep =>';') do |row|
			@district = District.find(:first, :conditions => ['name = ?',row['district_name']]).district_id rescue nil
			
			if @district.nil		
				log("#{row['district_name'].humanize} District not found! Please check")
			else
				@hcenter = HealthCenter.find(:first, :conditions => ['name = ? and district = ?', 
								row['facility_name'], @district]) rescue nil
				if @hcenter.nil?
					hc = HealthCenter.new
					hc.name = row['facility_name']
					hc.district = @district
					hc.save
					log("Added new Health Center: #{row['facility_name'].humanize} for: #{row['district_name'].humanize}")
				else
				  	log("Health Center already exist: #{row['facility_name'].humanize} for: #{row['district_name'].humanize}")
				end
			end
		end	
	rescue
		log "No such file : #{@hc_file_location}/malawi_health_facilities.csv"
	end
end

initialize_variables
insert_health_centers
