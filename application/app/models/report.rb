module Report
    def self.generate_cohort_date_range(quarter = "", start_date = nil, end_date = nil)

    quarter_beginning   = start_date.to_date  rescue nil
    quarter_ending      = end_date.to_date    rescue nil
    quarter_end_dates   = []
    quarter_start_dates = []
    date_range          = [nil, nil]

    if(!quarter_beginning.nil? && !quarter_ending.nil?)
      date_range = [quarter_beginning, quarter_ending]
		elsif (!quarter.nil? && quarter == "Cumulative")
      quarter_beginning = Encounter.initial_encounter.encounter_datetime.to_date
      quarter_ending    = Date.today.to_date

      date_range        = [quarter_beginning, quarter_ending]
		elsif(!quarter.nil? && (/Q[1-4][\_\+\- ]\d\d\d\d/.match(quarter)))
			quarter, quarter_year = quarter.humanize.split(" ")

      quarter_start_dates = ["#{quarter_year}-01-01".to_date, "#{quarter_year}-04-01".to_date, "#{quarter_year}-07-01".to_date, "#{quarter_year}-10-01".to_date]
      quarter_end_dates   = ["#{quarter_year}-03-31".to_date, "#{quarter_year}-06-30".to_date, "#{quarter_year}-09-30".to_date, "#{quarter_year}-12-31".to_date]

      current_quarter   = (quarter.match(/\d+/).to_s.to_i - 1)
      quarter_beginning = quarter_start_dates[current_quarter]
      quarter_ending    = quarter_end_dates[current_quarter]

      date_range = [quarter_beginning, quarter_ending]

    end

    return date_range
  end

  def self.cohort_range(date)
    year = date.year
    if date >= "#{year}-01-01".to_date and date <= "#{year}-03-31".to_date
      quarter = "Q1 #{year}"
    elsif date >= "#{year}-04-01".to_date and date <= "#{year}-06-30".to_date
      quarter = "Q2 #{year}"
    elsif date >= "#{year}-07-01".to_date and date <= "#{year}-09-30".to_date
      quarter = "Q3 #{year}"
    elsif date >= "#{year}-10-01".to_date and date <= "#{year}-12-31".to_date
      quarter = "Q4 #{year}"
    end
    self.generate_cohort_date_range(quarter)
  end

  def self.generate_cohort_quarters(start_date, end_date)
    cohort_quarters   = []
    current_quarter   = ""
    quarter_end_dates = ["#{end_date.year}-03-31".to_date, "#{end_date.year}-06-30".to_date, "#{end_date.year}-09-30".to_date, "#{end_date.year}-12-31".to_date]

    quarter_end_dates.each_with_index do |quarter_end_date, quarter|
      (current_quarter = (quarter + 1) and break) if end_date < quarter_end_date
    end

    quarter_number  =  current_quarter
    cohort_quarters += ["Cumulative"]
    current_date    =  end_date

    begin
      cohort_quarters += ["Q#{quarter_number} #{current_date.year}"]
      (quarter_number > 1) ? quarter_number -= 1: (current_date = current_date - 1.year and quarter_number = 4)
    end while (current_date.year >= start_date.year)

    cohort_quarters
  end
end
