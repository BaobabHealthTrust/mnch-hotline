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

  def self.generate_grouping_date_ranges(grouping, start_date, end_date)
    start_date  = start_date.to_date
    end_date    = end_date.to_date

    grouping_date_ranges  = {:display_text => nil, :date_ranges => []}

    case grouping
      when "week"
        grouping_date_ranges[:display_text] = "Week beginning XXXX ending  YYYY"

        current_week  = start_date.beginning_of_week
        final_week    = end_date.beginning_of_week

        begin
          week_beginning  = current_week.beginning_of_week
          week_ending     = current_week.end_of_week
          grouping_date_ranges[:date_ranges].push([week_beginning.strftime("%Y-%m-%d"), week_ending.strftime("%Y-%m-%d")])
          current_week    += 1.week
        end while current_week <= final_week

      when "month"
        grouping_date_ranges[:display_text]  = "Month beginning XXXX ending  YYYY"
        final_month   = end_date.beginning_of_month
        current_month = start_date.beginning_of_month

        begin
          month_beginning  = current_month.beginning_of_month
          month_ending     = current_month.end_of_month
          grouping_date_ranges[:date_ranges].push([month_beginning.strftime("%Y-%m-%d"), month_ending.strftime("%Y-%m-%d")])
          current_month    += 1.month
        end while current_month <= final_month
    end

    return grouping_date_ranges
  end

end
