


class SurvivalAnalysis

  def self.report(cohort)

    program_id = Program.find_by_name('HIV PROGRAM').id
    survival_analysis_outcomes = {} ; months = 12 ; patients_found = true
    survival_end_date = cohort.end_date.to_date ; survival_start_date = cohort.start_date.to_date
    first_registration_date = PatientProgram.find(:first,:conditions =>["program_id = ? AND voided = 0",program_id],
                                                  :order => 'date_enrolled ASC').date_enrolled.to_date rescue nil
    return if first_registration_date.blank?

    date_ranges = []

    while (survival_start_date -= 1.year) >= first_registration_date
      survival_end_date   -= 1.year
      date_ranges << {:start_date => survival_start_date,
                      :end_date   => survival_end_date
      }
    end

    ( date_ranges || [] ).each_with_index do | range ,i | 
      states = cohort.outcomes(range[:start_date], range[:end_date], cohort.end_date.to_date, program_id) 
      survival_analysis_outcomes["#{(i + 1)*12} month survival: outcomes by end of #{survival_end_date.strftime('%B %Y')}"] = {'Number Alive and on ART' => 0, 
                                'Number Dead' => 0, 'Number Defaulted' => 0 , 'Number Stopped Treatment' => 0, 'Number Transferred out' => 0, 
                                 'Unknown' => 0,'New patients registered for ART' => states.length}

      (states || [] ).each do | patient_id , state |
        case state
          when 'PATIENT TRANSFERRED OUT'
             survival_analysis_outcomes["#{(i + 1)*12} month survival: outcomes by end of #{survival_end_date.strftime('%B %Y')}"]['Number Transferred out']+=1 
          when 'PATIENT DIED'
             survival_analysis_outcomes["#{(i + 1)*12} month survival: outcomes by end of #{survival_end_date.strftime('%B %Y')}"]['Number Dead']+=1 
          when 'TREATMENT STOPPED'
             survival_analysis_outcomes["#{(i + 1)*12} month survival: outcomes by end of #{survival_end_date.strftime('%B %Y')}"]['Number Stopped Treatment']+=1 
          when 'ON ANTIRETROVIRALS'
             survival_analysis_outcomes["#{(i + 1)*12} month survival: outcomes by end of #{survival_end_date.strftime('%B %Y')}"]['Number Alive and on ART']+=1 
        end
      end
    end
    survival_analysis_outcomes.sort
  end


end
