class CohortToolController < ApplicationController

  def select
    @cohort_quarters  = [""]
    @report_type      = params[:report_type]
    @header 	        = params[:report_type] rescue ""
    @page_destination = ("/" + params[:dashboard].gsub("_", "/")) rescue ""

    if @report_type == "in_arv_number_range"
      @arv_number_start = params[:arv_number_start]
      @arv_number_end   = params[:arv_number_end]
    end

  start_date  = Encounter.initial_encounter.encounter_datetime
  end_date    = Date.today

  @cohort_quarters  += Report.generate_cohort_quarters(start_date, end_date)
  end

  def reports
    session[:list_of_patients] = nil
    if params[:report]
      case  params[:report_type]
        when "visits_by_day"
          redirect_to :action   => "visits_by_day",
                      :name     => params[:report],
                      :pat_name => "Visits by day",
                      :quarter  => params[:report].gsub("_"," ")
        return

        when "non_eligible_patients_in_cohort"
          date = Report.generate_cohort_date_range(params[:quarter])

          redirect_to :action       => "cohort_debugger",
                      :controller   => "reports",
                      :start_date   => date.first.to_s,
                      :end_date     => date.last.to_s,
                      :id           => "start_reason_other",
                      :report_type  => "non_eligible patients in: #{params[:report]}"
        return

        when "out_of_range_arv_number"
          redirect_to :action           => "out_of_range_arv_number",
                      :arv_end_number   => params[:arv_end_number],
                      :arv_start_number => params[:arv_start_number],
                      :quarter          => params[:report].gsub("_"," "),
                      :report_type      => params[:report_type]
        return

        when "data_consistency_check"
          redirect_to :action       => "data_consistency_check",
                      :quarter      => params[:report],
                      :report_type  => params[:report_type]
        return

        when "summary_of_records_that_were_updated"
          redirect_to :action   => "records_that_were_updated",
                      :quarter  => params[:report].gsub("_"," ")
        return

        when "adherence_histogram_for_all_patients_in_the_quarter"
          redirect_to :action   => "adherence",
                      :quarter  => params[:report].gsub("_"," ")
        return

        when "patients_with_adherence_greater_than_hundred"
          redirect_to :action  => "patients_with_adherence_greater_than_hundred",
                      :quater => params[:report].gsub("_"," ")
        return

        when "patients_with_multiple_start_reasons"
          redirect_to :action       => "patients_with_multiple_start_reasons",
                      :quarter      => params[:report],
                      :report_type  => params[:report_type]
        return

        when "dispensations_without_prescriptions"
          redirect_to :action       => "dispensations_without_prescriptions",
                      :quarter      => params[:report],
                      :report_type  => params[:report_type]
        return

        when "prescriptions_without_dispensations"
          redirect_to :action       => "prescriptions_without_dispensations",
                      :quarter      => params[:report],
                      :report_type  => params[:report_type]
        return

        when "drug_stock_report"
          start_date  = "#{params[:start_year]}-#{params[:start_month]}-#{params[:start_day]}"
          end_date    = "#{params[:end_year]}-#{params[:end_month]}-#{params[:end_day]}"

          if end_date.to_date < start_date.to_date
            redirect_to :controller   => "cohort_tool",
                        :action       => "select",
                        :report_type  =>"drug_stock_report" and return
          end rescue nil

          redirect_to :controller => "drug",
                      :action     => "report",
                      :start_date => start_date,
                      :end_date   => end_date,
                      :quarter    => params[:report].gsub("_"," ")
        return
      end
    end
  end

  def records_that_were_updated
    @quarter    = params[:quarter]

    date_range  = Report.generate_cohort_date_range(@quarter)
    @start_date = date_range.first
    @end_date   = date_range.last

    @encounters = CohortTool.records_that_were_updated(@quarter)

    render :layout => false
  end

  def visits_by_day
    @quarter    = params[:quarter]

    date_range          = Report.generate_cohort_date_range(@quarter)
    @start_date         = date_range.first
    @end_date           = date_range.last
    visits              = Encounter.visits_by_day(@start_date.beginning_of_day, @end_date.end_of_day)
    @patients           = CohortTool.visiting_patients_by_day(visits)
    @visits_by_day      = CohortTool.visits_by_week(visits)
    @visits_by_week_day = CohortTool.visits_by_week_day(visits)

    render :layout => false
  end

  def prescriptions_without_dispensations
      include_url_params_for_back_button

      date_range  = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
      @report     = Order.prescriptions_without_dispensations_data(start_date , end_date)

      render :layout => 'report'
  end
  
  def  dispensations_without_prescriptions
       include_url_params_for_back_button

      date_range  = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
      @report     = Order.dispensations_without_prescriptions_data(start_date , end_date)

       render :layout => 'report'
  end
  
  def  patients_with_multiple_start_reasons
       include_url_params_for_back_button

      date_range  = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
      @report     = Observation.patients_with_multiple_start_reasons(start_date , end_date)

      render :layout => 'report'
  end
  
  def out_of_range_arv_number

      include_url_params_for_back_button

      date_range        = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")
      arv_number_range  = [params[:arv_start_number].to_i, params[:arv_end_number].to_i]

      @report = PatientIdentifier.out_of_range_arv_numbers(arv_number_range, start_date, end_date)

      render :layout => 'report'
  end
  
  def data_consistency_check
      include_url_params_for_back_button
      date_range  = Report.generate_cohort_date_range(params[:quarter])
      start_date  = date_range.first.beginning_of_day.strftime("%Y-%m-%d %H:%M:%S")
      end_date    = date_range.last.end_of_day.strftime("%Y-%m-%d %H:%M:%S")

      @dead_patients_with_visits       = Patient.dead_with_visits(start_date, end_date)
      @males_allegedly_pregnant        = Patient.males_allegedly_pregnant(start_date, end_date)
      @patients_with_wrong_start_dates = Patient.with_drug_start_dates_less_than_program_enrollment_dates(start_date, end_date)
      session[:data_consistency_check] = { :dead_patients_with_visits => @dead_patients_with_visits,
                                           :males_allegedly_pregnant  => @males_allegedly_pregnant,
                                           :patients_with_wrong_start_dates => @patients_with_wrong_start_dates
                                         }
      @checks = [['Dead patients with Visits', @dead_patients_with_visits.length],
                 ['Male patients with a pregnant observation', @males_allegedly_pregnant.length],
                 ['Patients who moved from 2nd to 1st line drugs', 0],
                 ['patients with start dates > first receive drug dates', @patients_with_wrong_start_dates.length]]
      render :layout => 'report'
  end
  
  def list
    @report = []
    include_url_params_for_back_button

    case params[:check_type]
       when 'Dead patients with Visits' then
            @report  =  session[:data_consistency_check][:dead_patients_with_visits]
       when 'Patients who moved from 2nd to 1st line drugs'then

       when 'Male patients with a pregnant observation' then
             @report =  session[:data_consistency_check][:males_allegedly_pregnant]
       when 'patients with start dates > first receive drug dates' then
             @report =  session[:data_consistency_check][:patients_with_wrong_start_dates]
       else

    end

    render :layout => 'report'
  end

  def include_url_params_for_back_button
       @report_quarter = params[:quarter]
       @report_type = params[:report_type]
  end
  
  def cohort
    @quater = params[:quater]
    start_date,end_date = Report.generate_cohort_date_range(@quater)
    cohort = Cohort.new(start_date,end_date)
    @cohort = cohort.report
    @survival_analysis = SurvivalAnalysis.report(cohort)
    render :layout => 'cohort'
  end

  def cohort_menu
  end

def adherence
    adherences = CohortTool.adherence(params[:quarter])
    @quater = params[:quarter]
    type = "patients_with_adherence_greater_than_hundred"
    @report_type = "Adherence Histogram for all patients"
    @adherence_summary = "&nbsp;&nbsp;<button onclick='adhSummary();'>Summary</button>" unless adherences.blank?
    @adherence_summary+="<input class='test_name' type=\"button\" onmousedown=\"document.location='/cohort_tool/reports?report=#{@quater}&report_type=#{type}';\" value=\"Over 100% Adherence\"/>"  unless adherences.blank?
    @adherence_summary_hash = Hash.new(0)
    adherences.each{|adherence,value|
      adh_value = value.to_i
      current_adh = adherence.to_i
      if current_adh <= 94
        @adherence_summary_hash["0 - 94"]+= adh_value
      elsif current_adh >= 95 and current_adh <= 100
        @adherence_summary_hash["95 - 100"]+= adh_value
      else current_adh > 100
        @adherence_summary_hash["> 100"]+= adh_value
      end
    }
    @adherence_summary_hash['missing'] = CohortTool.missing_adherence(@quater).length rescue 0
    @adherence_summary_hash.values.each{|n|@adherence_summary_hash["total"]+=n}

    data = ""
    adherences.each{|x,y|data+="#{x}:#{y}:"}
    @id = data[0..-2] || ''

    @results = @id
    @results = @results.split(':').enum_slice(2).map
    @results = @results.each {|result| result[0] = result[0]}.sort_by{|result| result[0]}
    @results.each{|result| @graph_max = result[1].to_f if result[1].to_f > (@graph_max || 0)}
    @graph_max ||= 0
    render :layout => false
  end

  def patients_with_adherence_greater_than_hundred

      min_range = params[:min_range]
      max_range = params[:max_range]
      missing_adherence = false
      missing_adherence = true if params[:show_missing_adherence] == "yes"
      session[:list_of_patients] = nil

      @patients = CohortTool.adherence_over_hundred(params[:quater],min_range,max_range,missing_adherence)

      @quater = params[:quater] + ": (#{@patients.length})" rescue  params[:quater]
      if missing_adherence
        @report_type = "Patient(s) with missing adherence"
      elsif max_range.blank? and min_range.blank?
        @report_type = "Patient(s) with adherence greater than 100%"
      else
        @report_type = "Patient(s) with adherence starting from  #{min_range}% to #{max_range}%"
      end
      render :layout => 'report'
      return
  end
end

