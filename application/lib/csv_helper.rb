
module CSVHelper
  require 'faster_csv'

  private

  def export_to_csv(report_name, report_headers, report_data, patient_type)
    config = YAML.load_file("config/report.yml")
    @export_path = config["config"]["export_path"]

    output_file = report_name.downcase + "_#{rand(1000000)}" + ".csv"
    output_file = @export_path + "/" + output_file

    case report_name
    when 'patient_demographics_report'
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
           csv << ["beginning : #{data[:start_date]} ending : #{data[:end_date]}","",""]
           csv << ["New Registrations","","","#{data[:new_registrations]}"]
           data[:catchment].map do | catchment |
             csv << ["","#{catchment.first}","#{catchment.last}",""]
           end
             csv << ["","","",""]
           if patient_type.downcase == 'children'
              data[:gender].map do | gender |
                csv << ["#{gender.first.humanize}","","#{gender.last}",""]
              end
           elsif patient_type.downcase == 'women'
              data[:pregnancy_status].map do | pregnancy_status |
                csv << ["#{pregnancy_status.first.humanize}","","#{pregnancy_status.last}",""]
              end
           elsif patient_type.downcase == 'all'
              data[:patient_type].map do | patient |
                csv << ["#{patient.first.humanize}","","#{patient.last}",""]
              end
           end
           csv << ["","","",""]
         end
      end
      
    when 'patient_health_issues_report'

    when 'patient_age_distribution_report'

    when 'patient_activity_report'

    when 'patient_referral_report'

    when 'call_time_of_day'

    when 'call_day_distribution'

    when 'call_lengths'

    when 'tips_activity'

    when 'current_enrollment_totals'

    when 'individual_current_enrollments'

    end
  end
end
