
module CSVHelper
  require 'faster_csv'

  private

  def export_to_csv(report_name, report_headers, report_data, patient_type,grouping)
    config = YAML.load_file("config/report.yml")
    @export_path = config["config"]["export_path"]

    output_file = report_name.downcase + ".csv"
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
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
           csv << ["#{grouping} beginning : #{data[:date_range].first} ending : #{data[:date_range].last}"] 

           data[:patient_info].each do |info|
             csv << ["#{info[:name]}","#{info[:number][:cell_phone_number]}", 
                      "#{info[:visit_summary].gsub(/[<B><\/B>]/,"")}" 
             ]
           end
           csv << ["","",""]
         end
      end
    when 'call_time_of_day'
      total_calls = 0
      total_morning = 0
      total_midday = 0
      total_afternoon = 0
      total_evening = 0

      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
          total_calls += data[:total]
          total_morning += data[:morning]
          total_midday += data[:midday]
          total_afternoon += data[:afternoon]
          total_evening += data[:evening]
           
          csv << ["#{grouping} beginning : #{data[:start_date]} ending : #{data[:end_date]}", 
                  "#{data[:total] rescue 0}", "#{data[:morning] rescue 0}", 
                  "#{data[:morning_pct] rescue 0}", "#{data[:midday] rescue 0}", 
                  "#{data[:midday_pct] rescue 0}", "#{data[:afternoon] rescue 0}", 
                  "#{data[:afternoon_pct] rescue 0}", "#{data[:evening] rescue 0}", 
                  "#{data[:evening_pct] rescue 0}"] 

         end
         csv << ["Total","#{total_calls}", "#{total_morning}", 
                 "#{(total_morning.to_f / total_calls.to_f * 100).round(1)}", 
                 "#{total_midday}", "#{(total_midday.to_f / total_calls.to_f * 100).round(1)}", 
                 "#{total_afternoon}", "#{(total_afternoon.to_f / total_calls.to_f * 100).round(1)}", 
                 "#{total_evening}", "#{(total_evening.to_f / total_calls.to_f * 100).round(1)}" 
                ]
      end
    when 'call_day_distribution'
      total_calls = 0
      total_monday = 0
      total_tuesday = 0
      total_wednesday = 0
      total_thursday = 0
      total_friday = 0
      total_saturday = 0
      total_sunday = 0

      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
          total_calls += data[:total]
          total_monday += data[:monday]
          total_tuesday += data[:tuesday]
          total_wednesday += data[:wednesday]
          total_thursday += data[:thursday]
          total_friday += data[:friday]
          total_saturday += data[:saturday]
          total_sunday += data[:sunday]

          csv << ["#{grouping} beginning : #{data[:start_date]} ending : #{data[:end_date]}", 
                  "#{data[:total] rescue 0}", "#{data[:monday] rescue 0}", 
                  "#{data[:monday_pct] rescue 0}", "#{data[:tuesday] rescue 0}", 
                  "#{data[:tuesday_pct] rescue 0}", "#{data[:wednesday] rescue 0}", 
                  "#{data[:wednesday_pct] rescue 0}", "#{data[:thursday] rescue 0}", 
                  "#{data[:thursday_pct] rescue 0}",  "#{data[:friday] rescue 0}", 
                  "#{data[:friday_pct] rescue 0}",  "#{data[:saturday] rescue 0}", 
                  "#{data[:saturday_pct] rescue 0}",  "#{data[:sunday] rescue 0}", 
                  "#{data[:sunday_pct] rescue 0}" 
                  ]

         end
         csv << ["Total","#{total_calls}", "#{total_monday}", 
                 "#{(total_monday.to_f / total_calls.to_f * 100).round(1)}", 
                 "#{total_tuesday}", "#{(total_tuesday.to_f / total_calls.to_f * 100).round(1)}", 
                 "#{total_wednesday}", "#{(total_wednesday.to_f / total_calls.to_f * 100).round(1)}", 
                 "#{total_thursday}", "#{(total_thursday.to_f / total_calls.to_f * 100).round(1)}", 
                 "#{total_friday}", "#{(total_friday.to_f / total_calls.to_f * 100).round(1)}", 
                 "#{total_saturday}", "#{(total_saturday.to_f / total_calls.to_f * 100).round(1)}", 
                 "#{total_sunday}", "#{(total_sunday.to_f / total_calls.to_f * 100).round(1)}" 
                ]
      end

    when 'call_lengths'

      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|

          csv << ["#{grouping} beginning : #{data[:start_date]} ending : #{data[:end_date]}", 
                  "#{data[:total] rescue 0}", 
                  "#{data[:morning] rescue 0}", "#{data[:m_avg] rescue 0}", "#{data[:m_min] rescue 0}", "#{data[:m_sdev] rescue 0}", 
                  "#{data[:midday] rescue 0}", "#{data[:mid_avg] rescue 0}", "#{data[:mid_min] rescue 0}", "#{data[:mid_sdev] rescue 0}", 
                  "#{data[:afternoon] rescue 0}", "#{data[:a_avg] rescue 0}", "#{data[:a_min] rescue 0}", "#{data[:a_sdev] rescue 0}", 
                  "#{data[:evening] rescue 0}",  "#{data[:e_avg] rescue 0}", "#{data[:e_min] rescue 0}", "#{data[:e_sdev] rescue 0}"   
                  ]
         end

      end
    when 'tips_activity'
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|

          csv << ["#{grouping} beginning : #{data[:start_date]} ending : #{data[:end_date]}", 
                  "#{data[:total] rescue 0}", 
                  "#{data[:pregnancy] rescue 0}", "#{data[:pregnancy_pct] rescue 0}", "#{data[:child] rescue 0}", "#{data[:child_pct] rescue 0}", 
                  "#{data[:yao] rescue 0}", "#{data[:yao_pct] rescue 0}", "#{data[:chewa] rescue 0}", "#{data[:chewa_pct] rescue 0}", 
                  "#{data[:sms] rescue 0}", "#{data[:sms_pct] rescue 0}", "#{data[:voice] rescue 0}", "#{data[:voice_pct] rescue 0}" 
                  ]
         end
      end
    when 'current_enrollment_totals'
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
           added = false
           data.each do |period_data|
             if !added
                csv << ["#{grouping} beginning : #{period_data[:start_date]} ending : #{period_data[:end_date]}"] 
                added = true
             end
             csv << ["#{period_data[:catchment].to_s.capitalize}", 
                  "#{period_data[:total] rescue 0}", 
                  "#{period_data[:pregnancy] rescue 0}", "#{period_data[:pregnancy_pct] rescue 0}", "#{period_data[:child] rescue 0}", "#{period_data[:child_pct] rescue 0}",
                  "#{period_data[:wcba] rescue 0}", "#{period_data[:wcba_pct] rescue 0}",
                  "#{period_data[:yao] rescue 0}", "#{period_data[:yao_pct] rescue 0}", "#{period_data[:chewa] rescue 0}", "#{period_data[:chewa_pct] rescue 0}", 
                  "#{period_data[:sms] rescue 0}", "#{period_data[:sms_pct] rescue 0}", "#{period_data[:voice] rescue 0}", "#{period_data[:voice_pct] rescue 0}" 
                  ]
           end
           csv << [""]
         end
      end
    when 'individual_current_enrollments'
      FasterCSV.open(output_file, 'w',:headers => report_headers) do |csv|
      csv << report_headers
         report_data.reverse.map do |data|
           added = false
           data.each do |period_data|
             if !added
                csv << ["#{grouping} beginning : #{period_data[:start_date]} ending : #{period_data[:end_date]}"] 
                added = true
             end
             csv << ["#{period_data[:person_name].to_s.capitalize}", 
                    "#{period_data[:on_tips].to_s.capitalize rescue ' '}", 
                    "#{period_data[:phone_type].to_s.capitalize rescue ' '}", 
                    "#{period_data[:phone_number] rescue ' '}", 
                    "#{period_data[:language].to_s.capitalize rescue ' '}", 
                    "#{period_data[:message_type].to_s.capitalize rescue ' '}", 
                    "#{period_data[:content].to_s.capitalize rescue ' '}", 
                    "#{period_data[:relevant_date].to_s.capitalize rescue ' '}" 
                    ]
           end
           csv << [""]
         end
      end
    end
  end
end
