module Report

  def self.generate_report_date_range(start_date, end_date)
    report_date_ranges  = {}

    if end_date
      today       = end_date
      this_week_beginning   = today.beginning_of_week
      last_week_beginning   = (this_week_beginning - 1.week)
      last_week_ending      = (last_week_beginning + 4.days) # the fifth day is the actual beginning of week itself
      this_month_beginning  = today.beginning_of_month

      this_week  = "#{this_week_beginning.strftime("%d-%m")} to #{today.strftime("%d-%m")}"
      last_week  = "#{last_week_beginning.strftime("%d-%m")} to #{last_week_ending.strftime("%d-%m")}"
      this_month = "#{this_month_beginning.strftime("%d-%m")} to #{today.strftime("%d-%m")}"

      report_date_ranges["this_week"]   = {"range"      =>["This Week (#{this_week})"],
                                            "datetime"  =>[this_week_beginning.strftime("%Y-%m-%d"), today.strftime("%Y-%m-%d")]}

      report_date_ranges["last_week"]   = {"range"      =>["Last Week (#{last_week})"],
                                            "datetime"  =>[last_week_beginning.strftime("%Y-%m-%d"), last_week_ending.strftime("%Y-%m-%d")]}

      report_date_ranges["this_month"]  = {"range"      =>["This Month (#{this_month})"],
                                            "datetime"  =>[this_month_beginning.strftime("%Y-%m-%d"), today.strftime("%Y-%m-%d")]}
      report_date_ranges["all_dates"]  = {"range"      =>["All Dates"],
                                            "datetime"  =>[start_date.strftime("%Y-%m-%d"), end_date.strftime("%Y-%m-%d")]}
    end
    report_date_ranges
  end

end
