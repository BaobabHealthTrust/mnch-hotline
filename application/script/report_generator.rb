require 'rest_client'

@url = "http://localhost:3000" # path to the hotline system
@start_date = '2011-07-18' # the report start date
@end_date = '2012-05-25' # the report end date

# the report names that we want to generate
# these can be obtained from the urls when you run the reports to screen i.e 
# http://localhost:3000/report/patient_age_distribution_report?   destination=screen&end_date=2012-05-25&grouping=month&patient_type=All&query=ages_distribution&report_type=patient_analysis&start_date=2011-07-18
# report name will be 'patient_age_distribution_report', then the rest will be parameters which you can add to the @report_parameters as advised below

@reports = ['individual_current_enrollments',
            'patient_age_distribution_report']
            
#report => parameter map
=begin
  :destination == should always be csv
  :source => should always be script
  
  * all other parameters, can be obtained by running the reports to screen, 
    and getting the parameters that are sent when generating the reports

  * format @report_parameters = {report_name, {parameters}}
  
  *some variations
  - patient_type : These can be child, women, or All
=end

@report_parameters = {
    'individual_current_enrollments' => {:destination => 'csv', :end_date => '', :query => 'individual_current_enrollments', 
                                          :report_type => 'tips', :start_date => '', :source => 'script'},
    'patient_age_distribution_report' => { :destination => 'csv', :end_date => "#{@end_date}", :grouping => 'month',
                                           :patient_type => 'All', :query => 'ages_distribution', 
                                           :report_type => 'patient_analysis', :start_date => "#{@start_date}", :source => 'script'}
  }
  
@reports.each do |report|
  response = RestClient.post("#{@url}/report/#{report}", @report_parameters[report])
  puts "\n#{report} -- #{response}"
end

puts "Done generating reports ....."

