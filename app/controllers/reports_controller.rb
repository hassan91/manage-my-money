class ReportsController < ApplicationController

 layout 'main'
 before_filter :login_required

 def index
   @user_reports = Report.find :all, :conditions => ["user_id = ?", self.current_user.id]
   @system_reports = prepare_system_reports
 end

 def show
   @report = Report.find params[:id]
   respond_to do |format|
    format.html do
      if @report.flow_report?
        render :template => 'reports/show_flow_report'
      else
        @graph = open_flash_chart_object(600,300, url_for(:controller => 'reports', :action => 'show', :id => @report.id, :format => 'json'))
        render :template => 'reports/show_graph_report'
      end
    end
    format.json do
      render :text => get_graph_data
    end
   end
 end

 def new
   prepare_reports
   @report = Report.new
 end

 def create
   @share_report = nil
   @value_report = nil
   @flow_report = nil
   @report = case params[:report_type]
     when 'ShareReport'
       @share_report = ShareReport.new(params[:share_report])
     when 'ValueReport'
       @value_report = ValueReport.new(params[:value_report])
     when 'FlowReport'
       @flow_report = FlowReport.new(params[:flow_report])
     else
       raise 'Unknown Report Class'
     end

   @report.user = @current_user
   @report.period_type = :custom #TODO
   @report.period_start, @report.period_end = get_period('report_day')

   if @report.save
     flash[:notice] = "Twoj raport zostal dodany"
     redirect_to :action => :index
   else
     flash[:error]  = "Nie udalo sie dodac raportu"
     prepare_reports
     @partial_name = get_report_partial_name @report
     render :action => 'new'
   end

 end

 def destroy
    @report = Report.find params[:id]
    @report.destroy
    flash[:notice] = 'Raport zostal pomyslnie usuniety'
    redirect_to :action => :index
 end

 def edit
    @report = Report.find(params[:id])
    if @report.value_report? || @report.flow_report?
      @report.prepare_category_report_options @current_user.categories
    end
    @partial_name = get_report_partial_name @report
 end

 def update
   @report = Report.find params[:id]
   @report.period_start, @report.period_end = get_period('report_day')
   if @report.update_attributes(params[@report.type_str.underscore.intern])
      flash[:notice] = 'Raport zostal pomyslnie zapisany'
      redirect_to :action => :index
   else
     flash[:notice] = 'Raport nie zostal pomyslnie zapisany'
     if @report.value_report? || @report.flow_report?
      @report.prepare_category_report_options @current_user.categories
     end
     @partial_name = get_report_partial_name @report
     render :action => :edit
   end
 end


 


 private
 def prepare_system_reports
   reports = []
   r = ShareReport.new
   r.category = self.current_user.categories.top_of_type :ASSET
   r.report_view_type = :pie
   r.period_type = :week
   r.share_type = :percentage
   r.name = "Systemowy raport 1"
   r.save!
   reports << r

#   r = ValueReport.new
#   self.current_user.categories.top.each do |c|
#     r.categories << c
#   end
#   r.report_view_type = :bar
#   r.period_type = :week
#   r.period_division = :none
#   r.name = "Systemowy raport 2"
#   r.save!
#   reports << r


   reports
 end

 def get_report_partial_name(report)
     report.type_str.underscore + '_fields'
 end

 def prepare_reports
   @value_report = ValueReport.new if !@value_report
   @share_report = ShareReport.new if !@share_report
   @flow_report = FlowReport.new if !@flow_report
   @value_report.prepare_category_report_options @current_user.categories
   @flow_report.prepare_category_report_options @current_user.categories
   @flow_report.report_view_type = :text
 end

 def get_graph_data
   @report = Report.find(params[:id])
   title = Title.new(@report.name)
   chart = OpenFlashChart.new
   chart.title = title

   graph = nil
   elements = []
   
    if @report.share_report?
      values_and_labels = @report.category.calculate_share_values @report.max_categories_count, @report.depth, @report.period_start, @report.period_end, @report.share_type
      graph = get_graph_object @report
      if @report.report_view_type == :pie
        graph.values = values_and_labels.map {|val| PieValue.new(val[0],val[1])}
      else
        graph.values = values_and_labels.map {|val| val[0]}
        x_axis = XAxis.new
        x_axis.labels = values_and_labels.map {|val| val[1]}
        chart.x_axis = x_axis
      end
      elements << graph
    else if @report.value_report?
      @report.category_report_options.each do |option|
        values = option.category.calculate_values option.inclusion_type, @report.period_division, @report.period_start, @report.period_end
        graph = get_graph_object @report
        graph.values = values
        graph.set_key(option.category.name,12)
        elements << graph
      end
      labels = Category.get_values_labels @report.period_division, @report.period_start, @report.period_end
      x_axis = XAxis.new
      x_axis.labels = labels
      chart.x_axis = x_axis
    else
      throw 'Wrong report type'
    end
   end
   elements.each {|e| chart << e }
   chart.to_s
 end

  def get_graph_object report
    case report.report_view_type
    when :bar then Bar.new
    when :pie then Pie.new
    when :linear then Line.new
    end
 end


end
