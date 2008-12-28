# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include Forms::ApplicationHelper

  def get_periods
    [ :SELECTED,
    :THIS_DAY,
    :LAST_DAY,
    :THIS_WEEK,
    :LAST_WEEK,
    :LAST_7_DAYS,
    :THIS_MONTH,
    :LAST_MONTH,
    :LAST_4_WEEKS,
    :THIS_QUARTER,
    :LAST_QUARTER,
    :LAST_3_MONTHS,
    :LAST_90_DAYS,
    :THIS_YEAR,
    :LAST_YEAR,
    :LAST_12_MONTHS
  ]
  end


  def date_period_fields(name, start_day, end_day)

    name_id = name.gsub(/_/, '-')
    select_name = name+'_period'
    begin_field_name = get_date_begin_field_name(name)
    end_field_name = get_date_end_field_name(name)

    result = ''
    result += <<-HTML
      <p id="#{name_id}-period"><label for="#{name_id}">Wybierz okres:</label>
    HTML
    
    result += select_tag select_name, options_from_collection_for_select(get_periods, :to_s, :to_s)

    result += <<-HTML
      </p>
    HTML

    result += get_date_field_begin(name, start_day)

    result += get_date_field_end(name, end_day)

    result += observe_field select_name,
        :frequency => 1,
        :update => begin_field_name ,
        :on => 'click' ,
        :with => 'time',
        :url => {:action => :period_changed_start, :controller => :categories }

    result += observe_field select_name,
        :frequency => 1,
        :update => end_field_name ,
        :on => 'click' ,
        :with => 'time',
        :url => {:action => :period_changed_end, :controller => :categories }

    result

  end

  def get_date_field_begin(name, start_day)
    begin_field_name = get_date_begin_field_name(name)
    result = ''
    result += <<-HTML
      <p id="#{begin_field_name}"><label for="#{begin_field_name}">Wybierz datę początkową</label>
    HTML

    result += select_date start_day, :prefix => "#{name}_start"

    result += <<-HTML
      </p>
    HTML

    result
  end


  def get_date_field_end(name, end_day)
    end_field_name = get_date_end_field_name(name)
    result = ''
    result += <<-HTML
      <p id="#{end_field_name}"><label for="#{end_field_name}">wybierz datę końcową</label>
    HTML

    result += select_date end_day, :prefix => "#{name}_end"

    result += <<-HTML
      </p>
    HTML

  end

  private
  def get_date_begin_field_name(name)
    "#{name.gsub(/_/, '-')}-start"
  end

  def get_date_end_field_name(name)
    "#{name.gsub(/_/, '-')}-end"
  end

end
