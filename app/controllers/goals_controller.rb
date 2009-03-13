class GoalsController < ApplicationController

  layout 'main'
  before_filter :login_required

  #before actions check if this is current user goal

  # GET /goals
  # GET /goals.xml
  def index
    @actual_goals = Goal.find_actual(self.current_user)
    @finished_goals = Goal.find_past(self.current_user)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @actual_goals }
    end
  end

  # GET /goals/1
  # GET /goals/1.xml
  def show
    @goal = self.current_user.goals.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @goal }
    end
  end

  # GET /goals/new
  # GET /goals/new.xml
  def new
    @goal = Goal.new
    prepare_values_for_goal_type_and_currency
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @goal }
    end
  end

  # GET /goals/1/edit
  def edit
    @goal = self.current_user.goals.find(params[:id])
    prepare_values_for_goal_type_and_currency
  end

  # POST /goals
  # POST /goals.xml
  def create
    @goal = Goal.new(params[:goal])

    @goal.user = self.current_user
    set_period_for(@goal, 'goal_day')

    respond_to do |format|
      if @goal.save
        flash[:notice] = 'Cel został utworzony.'
        format.html { redirect_to(:action => :index) }
        format.xml  { render :xml => @goal, :status => :created, :location => @goal }
      else
        prepare_values_for_goal_type_and_currency
        format.html { render :action => "new" }
        format.xml  { render :xml => @goal.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /goals/1
  # PUT /goals/1.xml
  def update
    @goal = self.current_user.goals.find(params[:id])
    set_period_for(@goal, 'goal_day')
    respond_to do |format|
      if @goal.update_attributes(params[:goal])
        flash[:notice] = 'Cel został zapisany.'
        format.html { redirect_to(:action => :index) }
        format.xml  { head :ok }
      else
        prepare_values_for_goal_type_and_currency
        format.html { render :action => "edit" }
        format.xml  { render :xml => @goal.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /goals/1
  # DELETE /goals/1.xml
  def destroy
    @goal = self.current_user.goals.find(params[:id])
    @goal.destroy

    respond_to do |format|
      format.html { redirect_to(goals_url) }
      format.xml  { head :ok }
    end
  end


  def finish
    @goal = self.current_user.goals.find(params[:id])
    if @goal.finish
      flash[:notice] = 'Plan został zakończony.'
    else
      flash[:notice] = 'Plan nie został zakończony. Skontaktuj się z pomocą techniczną.'
    end

    respond_to do |format|
      format.html { redirect_to(:action => :index) }
    end

  end


  def history_index
    @goal = self.current_user.goals.find(params[:id])
    @goals = @goal.all_goals_in_cycle

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @actual_goals }
    end
  end


  private

  def prepare_values_for_goal_type_and_currency
    @values_for_goal_type_and_currency = self.current_user.visible_currencies.map { |cur| [cur.long_symbol, cur.long_symbol]}
    @values_for_goal_type_and_currency << ['Procent wartości z nadkategorii','percent']
  end

end
