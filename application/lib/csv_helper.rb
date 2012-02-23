
module CSVHelper
  require 'faster_csv'

  private

  def export_to_csv(report_name, report_headers, report_data)
    config = YAML.load_file("config/report.yml")
    @export_path = config["config"]["export_path"]

    output_file = report_name.downcase + ".csv"
    output_file = @export_path + "/" + output_file

    case report_name
    when 'patient_demographics_report'
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
        10.times do
          csv << ["precious","bondwe"]
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
