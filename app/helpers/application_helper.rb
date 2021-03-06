module ApplicationHelper
  include Forms::ApplicationHelper
  include ShadowHelper
  include TabHelper
  include LinkActionHelper

  #Returns all periods including :Selected which cannote be computed by Date.compute
  def get_periods(periods = [:present, :past])
    periods_table = [[:SELECTED, 'Wybrane z menu']]
    periods_table += Date::ACTUAL_PERIODS if periods.include?(:present)
    periods_table += Date::PAST_PERIODS if periods.include?(:past)
    periods_table += Date::FUTURE_PERIODS if periods.include?(:future)
    return periods_table
  end

  module_function :get_periods

  # Returns id='name-#{obj.id}'
  def obj_id(name, obj)
    "id='#{name}-#{obj.id}'"
  end

  # Returns hash { :id => 'name-#{obj.id}' }
  def obj_hash_id(name, obj)
    {:id => "#{name}-#{obj.id}"}
  end

  # display_if(proc_object)
  # display_if { 1 == 2 }
  #
  # Returns "display:none" if condition is evaluated as false
  # otherwise returns empty string.
  def display_if(condition = nil, &block)
    raise 'Condition as Proc or code block required' if condition.nil? && !Kernel.block_given?
    condition = block if condition.nil?
    return '' if condition.call == true
    return 'display:none'
  end


  # display_if(proc_object)
  # display_if { 1 == 2 }
  #
  # Returns style="display:none" if condition is evaluated as false
  # otherwise returns style="" string.
  def style_display_if(condition = nil, &block)
    raise 'Condition as Proc or code block required' if condition.nil? && !Kernel.block_given?
    condition = block if condition.nil?
    return "style=\"#{display_if(condition)}\""
  end


  def add_transfer_item(transfer_item_type)
    text = render :partial => '/transfers/transfer_item', :locals => {:hack => true}, :object => TransferItem.new(:transfer_item_type => transfer_item_type, :currency_id => @current_user.default_currency.id)
    #    jsfunction = "onclick=\"var my_uid = uid();\n"
    jsfunction = "var my_uid = uid();\n $(this).up().down('table').insert('#{ escape_javascript(text) }'); return false;"
    jsfunction.gsub! "PUT_ID_HERE", "'+ my_uid +'"
    #TODO: wyjąc metodę UID  z head'a layoutu
    return link_to_function 'Nowy element', jsfunction, :id => "new-#{transfer_item_type}-transfer-item"
  end



  def date_period_fields(name, start_day = Date.today, end_day = Date.today, selected = 'SELECTED', periods = nil)

    name_id = name.gsub(/_/, '-')
    select_periods = periods ? get_periods(periods) : get_periods
    select_name = name+'_period'
    start_field_name = get_date_start_field_name(name)
    end_field_name = get_date_end_field_name(name)
    computed_name = "#{name_id}-computed"

    result = ''
    result << <<-HTML
      <p id="#{name_id}-period"><label for="#{name_id}">Wybierz okres: </label>
    HTML

    result << select_tag(select_name, options_from_collection_for_select(select_periods, :first, :second, selected))
    result << help_tag('system_elements.other.date.period')
    
    result << get_date_field_start(name, start_day)
    result << get_date_field_end(name, end_day)
    result << <<-HTML
      </p>
    HTML

    result << <<-HTML
      <p id="#{computed_name}" style="display:none"></p>
    HTML

    function = <<-JS
      if (value == 'SELECTED') {
        Element.hide('#{computed_name}');
        Element.update('#{computed_name}','');
        Element.show('#{start_field_name}');
        Element.show('#{end_field_name}');
        return;
      }
      var text1 = '<p><label>Data początkowa: </label> '
      var text2 = '</p> <p><label>Data końcowa: </label> '
      var text3 = '</p>'
      switch (value) {
    JS


    select_periods.delete_if{ |e| e[0] == :SELECTED}.each do |period_type, period_name|
      range = Date.calculate(period_type)
      function << "case '#{period_type.to_s}': \n"
      function << "  text1 = text1 + '#{range.begin}' ;\n"
      function << "  text2 = text2 + '#{range.end}' ;\n"
      function << "break;\n"
    end
    function << <<-JS
    }
    text1 = text1 + text2 + text3
    Element.update('#{computed_name}', text1);
    Element.hide('#{start_field_name}');
    Element.hide('#{end_field_name}');
    Element.show('#{computed_name}');
    JS

    result << observe_field(select_name,
      :on => 'click' ,
      :function => function)
  end

  def get_date_field_start(name, start_day = Date.today)
    begin_field_name = get_date_start_field_name(name)
    html = "<p id='#{begin_field_name}'><label for='#{begin_field_name}'>Data początkowa: </label>"
    html << select_date(start_day, :prefix => "#{name}_start")
    html << help_tag('system_elements.other.date.start')
    html << '</p>'
    html
  end


  def get_date_field_end(name, end_day = Date.today)
    end_field_name = get_date_end_field_name(name)
    html = "<p id='#{end_field_name}'><label for='#{end_field_name}'>Data końcowa: </label>"
    html << select_date(end_day, :prefix => "#{name}_end")
    html << help_tag('system_elements.other.date.end')
    html << "</p>"
    html
  end


  #obsolete! Use js toggle instead
  def switch(div_id, name)
    link_to_function name, :id => "switch_for_#{div_id}", :onclick =>  <<-JS
      Element.toggle('#{div_id}')
    JS
  end

  if defined? WillPaginate

    include WillPaginate::ViewHelpers
    def will_paginate_with_i18n(collection, options = {})
      will_paginate_without_i18n(collection, options.merge(:previous_label => I18n.translate(:previous, :default => 'Previous'), :next_label => I18n.translate(:next, :default => 'Next')))
    end

    alias_method_chain :will_paginate, :i18n
  end


  def help_tag(a_id, title = 'Pomoc')
    result =  <<-HTML
<span class="help" title="#{title}">
  <a href="/help/help.html##{a_id}" target="_blank" tabindex="-1">
    <img alt="Pomoc" src="/images/icon_help.png" style="vertical-align: top;"/>
  </a>
</span>
    HTML
    result
  end



  protected

  def block_to_partial(partial_name, options = {}, &block)
    options.merge!(:body => capture(&block))
    concat(render(:partial => partial_name, :locals => options), block.binding)
  end


  private


  def get_date_start_field_name(name)
    "#{name.gsub(/_/, '-')}-start"
  end

  def get_date_end_field_name(name)
    "#{name.gsub(/_/, '-')}-end"
  end


end
