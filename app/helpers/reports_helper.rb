module ReportsHelper

  def get_report_partial_name(report)
     report.type.to_s.underscore + '_fields'
  end


  def get_report_partial_div_name(report)
     report.to_s.underscore + '_options'
  end


  #generuje kod javascript ukrywajacy i pokazujacy divy
  # zawierajace formularze dla poszczegolnych typow raportow
  #@author Jarek
  def control_visibility_of_report_forms(report)
    [FlowReport, ValueReport, ShareReport].inject '' do |mem, item|
      div = get_report_partial_div_name(item)
      command = report.is_a?(item)? "show" : "hide"
      mem += "Element.#{command}('#{div}');"
    end
  end

  def get_desc_for_report_view_type(code)
    case code
    when :bar then 'Wykres słupkowy'
    when :pie then 'Wykres kołowy'
    when :linear then 'Wykres liniowy'
    when :text then 'Raport tekstowy'
    end
  end

  def get_desc_for_share_type(code)
    case code
    when :percentage then 'Procentowy'
    when :value then '"Wartościowy"'
    end
  end

end
