module ReportHelper

## The following functions will generate table cells for Tips Activity Report

  def pregnancy_data_cell(content_type)
    if (content_type.capitalize == "All" ||  content_type.capitalize == "Pregnancy") 
       content_type.capitalize == "Pregnancy" ? colspan = '4': colspan = '2'
       table_cell = "<td width=\"12%\" colspan = #{colspan} class=\"cellleft cellbottom main-table-cell\" style=\"font-weight: bold; text-align:center;\">" + "Pregnancy" +"</td>"
    end
    table_cell
  end  
  
  def child_data_cell(content_type)
    if (content_type.capitalize == "All" ||  content_type.capitalize == "Child") 
      content_type.capitalize == "Child" ? colspan = '4' : colspan = '2'
      table_cell = "<td width=\"12%\" colspan = #{colspan} class=\"cellleft cellbottom main-table-cell\" style=\"font-weight: bold; text-align:center;\">" + "Child" +"</td>"
    end
    table_cell
  end  
  
  def chiyao_data_cell(language)
    if (language.capitalize == "All" ||  language.capitalize == "Yao" )
      language.capitalize == "All" ? colspan = '2': colspan = '4'
      table_cell = "<td width=\"12%\" colspan = #{colspan} class=\"cellleft cellbottom main-table-cell\" style=\"font-weight: bold; text-align:center;\">" + "Chiyao" +"</td>"
    end
    table_cell
  end  
  
  def chichewa_data_cell(language)
    if (language.capitalize == "All" ||  language.capitalize == "Chichewa" )
      language.capitalize == "All" ? colspan = '2': colspan = '4'
      table_cell = "<td width=\"12%\" colspan = \"#{colspan}\" class=\"cellleft cellbottom main-table-cell\" style=\"font-weight: bold; text-align:center;\">" + "Chichewa" +"</td>"
    end
    table_cell
  end  
  
  def sms_data_cell(delivery)
    if (delivery.capitalize == "All" ||  delivery.capitalize == "Sms" )
      delivery.capitalize == "All" ? colspan = '2': colspan = '4'
      table_cell = "<td width=\"12%\" colspan = \"#{colspan}\" class=\"cellleft cellbottom main-table-cell\" style=\"font-weight: bold; text-align:center;\">" + "SMS" +"</td>"
    end
    table_cell
  end  
  
  def voice_data_cell(delivery)
    if (delivery.capitalize == "All" ||  delivery.capitalize == "Voice" )
      delivery.capitalize == "All" ? colspan = '2': colspan = '4'
      table_cell = "<td width=\"12%\" colspan = \"#{colspan}\" class=\"cellleft cellbottom main-table-cell\" style=\"font-weight: bold; text-align:center;\">" + "Voice" +"</td>"
    end
    table_cell
  end  
  
  def pregnancy_count_and_percent_header(content_type)
    if ( content_type.capitalize == "All" ||  content_type.capitalize == "Pregnancy" )
        content_type.capitalize == "Pregnancy" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" +"Count" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" + "%age" + "</td>"
    end
  end
  
  def child_count_and_percent_header(content_type)
    if (content_type.capitalize == "All" ||  content_type.capitalize == "Child" )
        content_type.capitalize == "Child" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" +"Count" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" + "%age" + "</td>"
    end
    table_cell
  end
  
  def chiyao_count_and_percent_header(language)
    if (language.capitalize == "All" ||  language.capitalize == "Yao" )
        language.capitalize == "Yao" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" +"Count" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" + "%age" + "</td>"
    end
    table_cell
  end
  
  def chichewa_count_and_percent_header(language)
    if (language.capitalize == "All" ||  language.capitalize == "Chichewa" )
        language.capitalize == "Chichewa" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" +"Count" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" + "%age" + "</td>"
    end
    table_cell
  end
  
  def sms_count_and_percent_header(delivery)
    if (delivery.capitalize == "All" ||  delivery.capitalize == "Sms") 
        delivery.capitalize == "Sms" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" +"Count" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" + "%age" + "</td>"
    end
    table_cell
  end
  
  def voice_count_and_percent_header(delivery)
    if (delivery.capitalize == "All" ||  delivery.capitalize == "Voice" )
        delivery.capitalize == "Voice" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" +"Count" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" style=\"font-weight: bold;\">" + "%age" + "</td>"
    end
    table_cell
  end
  
  def pregnancy_count_and_percent_values(content_type, pregnancy_value, pregnancy_pct_value)
    if (content_type.capitalize == "All" ||  content_type.capitalize == "Pregnancy" )
        content_type.capitalize == "Pregnancy" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" >" +"#{pregnancy_value}" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\">" + "#{pregnancy_pct_value}" + "</td>"
    end 
    table_cell
  end
  
  def child_count_and_percent_values(content_type, child_value, child_pct_value)
    if (content_type.capitalize == "All" ||  content_type.capitalize == "Child" )
        content_type.capitalize == "Child" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" >" +"#{child_value}" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\">" + "#{child_pct_value}" + "</td>"
    end 
    table_cell
  end
  
  def chiyao_count_and_percent_values(language, chiyao_count, chiyao_pct_value)
    if (language.capitalize == "All" ||  language.capitalize == "Yao" )
        language.capitalize == "Yao" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" >" +"#{chiyao_count}" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\">" + "#{chiyao_pct_value}" + "</td>"
    end 
    table_cell
  end
  
  def chichewa_count_and_percent_values(language, chichewa_count, chichewa_pct_value)
    if (language.capitalize == "All" ||  language.capitalize == "Chichewa") 
        language.capitalize == "Chichewa" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" >" +"#{chichewa_count}" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\">" + "#{chichewa_pct_value}" + "</td>"
    end 
    table_cell
  end
  
  def sms_count_and_percent_values(delivery, sms_count, sms_pct_value)
    if (delivery.capitalize == "All" ||  delivery.capitalize == "Sms" )
        delivery.capitalize == "Sms" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" >" +"#{sms_count}" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\">" + "#{sms_pct_value}" + "</td>"
    end 
    table_cell
  end
    
  def voice_count_and_percent_values(delivery, voice_count, voice_pct_value)
    if (delivery.capitalize == "All" ||  delivery.capitalize == "Voice" )
        delivery.capitalize == "Voice" ? colspan = '2' : colspan = '1'
        table_cell = "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\" >" +"#{voice_count}" + "</td>" + "<td colspan = \"#{colspan}\" class=\" cellleft cellbottom main-table-cell\">" + "#{voice_pct_value}" + "</td>"
    end 
    table_cell
  end
  
end