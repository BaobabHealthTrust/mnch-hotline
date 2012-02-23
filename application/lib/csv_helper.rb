
module CSVHelper
  require 'faster_csv'

  private

  def export_to_csv(report_name, report_headers, report_data, patient_type,grouping)
    config = YAML.load_file("config/report.yml")
    @export_path = config["config"]["export_path"]

    output_file = report_name.downcase + "_#{rand(1000000)}" + ".csv"
    output_file = @export_path + "/" + output_file

    case report_name
    when 'patient_demographics_report'
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
           csv << ["#{grouping} beginning : #{data[:start_date]} ending : #{data[:end_date]}","",""]
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
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
           csv << ["#{grouping} beginning : #{data[:start_date]} ending : #{data[:end_date]}","",""]
           csv << ["Total Callers","","#{data[:total_calls]}","n/a"]
           csv << ["Total Callers with Symptoms","","#{data[:total_number_of_calls]}","n/a"]
           csv << ["Below are the #{report_headers[1]}","","",""]

           data[:health_issues].map do | health_issue|
             csv << ["","#{health_issue[:concept_name].titleize}",
             "#{health_issue[:call_count]}","#{health_issue[:call_percentage]}"]
           end
           csv << ["","","",""]
         end
      end

    when 'patient_age_distribution_report'
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
           csv << ["#{grouping} beginning : #{data[:patient_data][:start_date]} ending : #{data[:patient_data][:end_date]}","",""]

           if patient_type.downcase == 'children'
             csv << ["Gender","","","","","",""]

            data[:patient_data][:gender].map do | gender |
               row_data = []
               row_data << gender.first
               row_data << gender.last
               if gender.first.downcase == 'female'
                 row_data << data[:statistical_data][:female][:statistical_info][:percentage] rescue 0
                 row_data << data[:statistical_data][:female][:statistical_info][:min] rescue 0
                 row_data << data[:statistical_data][:female][:statistical_info][:max] rescue 0
                 row_data << data[:statistical_data][:female][:statistical_info][:average] rescue 0
                 row_data << data[:statistical_data][:female][:statistical_info][:sdev] rescue 0
               elsif gender.first.downcase == 'male'
                 row_data << data[:statistical_data][:male][:statistical_info][:percentage] rescue 0
                 row_data << data[:statistical_data][:male][:statistical_info][:min] rescue 0
                 row_data << data[:statistical_data][:male][:statistical_info][:max] rescue 0
                 row_data << data[:statistical_data][:male][:statistical_info][:average] rescue 0
                 row_data << data[:statistical_data][:male][:statistical_info][:sdev] rescue 0
               end
               csv << row_data
             end
           elsif patient_type.downcase == 'women'
             csv << ["Pregnacy Status","","","","","",""]

             data[:patient_data][:pregnancy_status].map do | pregnancy_status |
               row_data = []
               row_data << pregnancy_status.first
               row_data << pregnancy_status.last
               if pregnancy_status.first.downcase == 'pregnant'
                 row_data << data[:statistical_data][:pregnant][:statistical_info][:percentage] rescue 0
                 row_data << data[:statistical_data][:pregnant][:statistical_info][:min] rescue 0
                 row_data << data[:statistical_data][:pregnant][:statistical_info][:max] rescue 0
                 row_data << data[:statistical_data][:pregnant][:statistical_info][:average] rescue 0
                 row_data << data[:statistical_data][:pregnant][:statistical_info][:sdev] rescue 0
               elsif gender.first.downcase == 'non_pregnant'
                 row_data << data[:statistical_data][:nonpregnant][:statistical_info][:percentage] rescue 0
                 row_data << data[:statistical_data][:nonpregnant][:statistical_info][:min] rescue 0
                 row_data << data[:statistical_data][:nonpregnant][:statistical_info][:max] rescue 0
                 row_data << data[:statistical_data][:nonpregnant][:statistical_info][:average] rescue 0
                 row_data << data[:statistical_data][:nonpregnant][:statistical_info][:sdev] rescue 0
               elsif gender.first.downcase == 'delivered'
                 row_data << data[:statistical_data][:delivered][:statistical_info][:percentage] rescue 0
                 row_data << data[:statistical_data][:delivered][:statistical_info][:min] rescue 0
                 row_data << data[:statistical_data][:delivered][:statistical_info][:max] rescue 0
                 row_data << data[:statistical_data][:delivered][:statistical_info][:average] rescue 0
                 row_data << data[:statistical_data][:delivered][:statistical_info][:sdev] rescue 0
               end
               csv << row_data
             end
           elsif patient_type.downcase == 'all'
             csv << ["Patient Type","","","","","",""]

             data[:patient_data][:patient_type].map do | patient |
               row_data = []
               row_data << patient.first
               row_data << patient.last
               if patient.first.downcase == 'women'
                 row_data << data[:statistical_data][:women][:statistical_info][:percentage] rescue 0
                 row_data << data[:statistical_data][:women][:statistical_info][:min] rescue 0
                 row_data << data[:statistical_data][:women][:statistical_info][:max] rescue 0
                 row_data << data[:statistical_data][:women][:statistical_info][:average] rescue 0
                 row_data << data[:statistical_data][:women][:statistical_info][:sdev] rescue 0
               elsif patient.first.downcase == 'children'
                 row_data << data[:statistical_data][:child][:statistical_info][:percentage] rescue 0
                 row_data << data[:statistical_data][:child][:statistical_info][:min] rescue 0
                 row_data << data[:statistical_data][:child][:statistical_info][:max] rescue 0
                 row_data << data[:statistical_data][:child][:statistical_info][:average] rescue 0
                 row_data << data[:statistical_data][:child][:statistical_info][:sdev] rescue 0
               end
               csv << row_data
             end
           end

           csv << ["","","","","","",""]
         end
      end

    when 'patient_activity_report'
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
           csv << ["#{grouping} beginning : #{data[:start_date]} ending : #{data[:end_date]}",
            "#{data[:total] rescue 0}", "#{data[:symptoms] rescue 0}",
            "#{data[:symptoms_pct] rescue 0}", "#{data[:danger] rescue 0}",
            "#{data[:danger_pct] rescue 0}", "#{data[:info] rescue 0}",
            "#{data[:info_pct] rescue 0}"]
         end
      end

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
