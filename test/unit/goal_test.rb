require 'test_helper'

class GoalTest < ActiveSupport::TestCase

  def setup
    save_jarek
  end
  
  def test_create_next_goal_in_cycle
    g = create_goal
    g.period_type = :NEXT_WEEK
    g.period_start = '01-01-2008'.to_date
    g.period_end = '07-01-2008'.to_date
    g.is_cyclic = true

    g.save!
    new_g = g.create_next_goal_in_cycle

    assert_not_nil new_g

    new_g.save!

    assert_equal g.user, new_g.user
    assert_equal g.category, new_g.category
    assert_equal g.period_type, new_g.period_type
    assert_equal '08-01-2008'.to_date, new_g.period_start
    assert_equal '14-01-2008'.to_date, new_g.period_end
    assert_equal g.goal_type_and_currency, new_g.goal_type_and_currency
    assert_equal g.value, new_g.value
    assert_equal g.description, new_g.description
    assert_equal true, g.is_cyclic
    assert_equal true, new_g.is_cyclic
    assert_not_nil g.cycle_group
    assert_equal g.cycle_group, new_g.cycle_group

    assert_raise RuntimeError, NameError do
      g.create_next_goal_in_cycle
    end
  end

  def test_next_goal_in_cycle_has_proper_date
    g = create_goal
    g.period_type = :NEXT_MONTH
    g.period_start = '01-01-2008'.to_date
    g.period_end = '31-01-2008'.to_date
    g.is_cyclic = true
    g.save!
    new_g = g.create_next_goal_in_cycle
    assert_not_nil new_g
    new_g.save!
    assert_equal '01-02-2008'.to_date, new_g.period_start
    assert_equal '29-02-2008'.to_date, new_g.period_end

    new_g = new_g.create_next_goal_in_cycle
    assert_not_nil new_g
    new_g.save!
    assert_equal '01-03-2008'.to_date, new_g.period_start
    assert_equal '31-03-2008'.to_date, new_g.period_end

  end



  def test_set_cycle_group_on_save
    g = create_goal(false)
    g.period_type = :NEXT_WEEK
    g.period_start = '01-01-2008'.to_date
    g.period_end = '07-01-2008'.to_date
    g.is_cyclic = true
    g.save!
    assert_equal g.id, g.cycle_group
    g.is_cyclic = false
    g.save!
    assert_equal nil, g.cycle_group

    g2 = create_goal(false)
    g2.is_cyclic = false
    g2.save!
    assert_equal nil, g2.cycle_group
    g2.period_type = :NEXT_WEEK
    g2.period_start = '01-01-2008'.to_date
    g2.period_end = '07-01-2008'.to_date
    g2.is_cyclic = true
    g2.save!
    assert_equal g2.id, g2.cycle_group
  end


  def test_validations
    prepare_sample_catagory_tree_for_jarek

    g = Goal.new
    assert !g.save
    assert_equal 8, g.errors.size

    assert g.errors.on(:description)
    assert_equal 2, g.errors.on(:value).size
    assert g.errors.on(:user)
    assert g.errors.on(:category)
    assert g.errors.on(:period_type)
    assert g.errors.on(:period_start)
    assert g.errors.on(:period_end)

    g.description = 'aaa'
    g.value = 'bbb'
    g.user = @jarek
    g.category = @jarek.income
    g.period_type = :SELECTED
    g.period_start = '12-12-2012'.to_date
    g.period_end = '12-12-2012'.to_date

    assert !g.save
    assert_equal 2, g.errors.size
    assert g.errors.on(:value)
    assert_match(/wymagane jest/, g.errors.on(:base))

    g.value = 1.1
    g.category = @jarek.categories.find_by_name('test')
    
    assert g.save

    g.category = @jarek.income
    g.goal_type_and_currency = 'PLN'

    assert g.save
    
    
    g.is_cyclic = true
    assert !g.save
    assert_equal 1, g.errors.size
    assert_match(/musisz wybrać.*okres/, g.errors.on(:base))

    g.is_cyclic = false
    assert g.save

    g.is_cyclic = true
    g.period_type = :NEXT_DAY
    assert g.save
  end

  def test_text_properties
    g = create_goal(true)
    assert_not_nil g.goal_type_and_currency
    assert_not_nil g.value_with_unit
    assert_not_nil g.actual_value_with_unit
    assert_not_nil g.unit
    assert_not_nil g.period_description
    assert_not_nil g.value_description
  end

  def test_find_past
    goals = []
    assert_find_past(goals)

    g = create_goal(false)
    g.period_start = Date.yesterday
    g.period_end = Date.yesterday
    g.save!
    goals << g
    assert_find_past(goals)

    g = create_goal(false)
    g.period_start = Date.today
    g.period_end = Date.today
    g.is_finished = true
    g.save!
    goals << g
    assert_find_past(goals)

    g = create_goal(false)
    g.period_start = Date.tomorrow
    g.period_end = Date.tomorrow
    g.is_finished = true
    g.save!
    goals << g
    assert_find_past(goals)

    g = create_goal(false)
    g.period_start = Date.today
    g.period_end = Date.today
    g.is_finished = false
    g.save!
    assert_find_past(goals)

    g = create_goal(false)
    g.period_type = :NEXT_DAY
    g.period_start = Date.today
    g.period_end = Date.today
    g.is_cyclic = true
    g.save!
    assert_find_past(goals)

    g.period_type = :NEXT_DAY
    g.period_start = Date.yesterday.yesterday
    g.period_end = Date.yesterday.yesterday
    g.save!
    goals << g
    assert_find_past(goals)

    g2 = g.create_next_goal_in_cycle
    g2.save!
    
    goals.delete(g)
    goals << g2

    assert_find_past(goals)

    g3 = g2.create_next_goal_in_cycle
    g3.save!
    assert_find_past(goals)

  end


  def test_find_actual
    goals = []
    assert_find_actual goals

    past_goals = []

    g = create_goal(false)
    g.period_start = Date.yesterday
    g.period_end = Date.yesterday
    g.save!
    past_goals << g

    g = create_goal(false)
    g.period_start = Date.today
    g.period_end = Date.today
    g.is_finished = true
    g.save!
    past_goals << g

    g = create_goal(false)
    g.period_start = Date.tomorrow
    g.period_end = Date.tomorrow
    g.is_finished = true
    g.save!
    past_goals << g
    assert_find_actual(goals)

    g = create_goal(false)
    g.period_start = Date.today
    g.period_end = Date.today
    g.is_finished = false
    g.save!
    goals << g
    assert_find_actual(goals)

    g = create_goal(false)
    g.period_type = :NEXT_DAY
    g.period_start = Date.today
    g.period_end = Date.today
    g.is_finished = false
    g.is_cyclic = true
    g.save!
    goals << g
    assert_find_actual(goals)

    g.period_type = :NEXT_DAY
    g.period_start = Date.yesterday.yesterday
    g.period_end = Date.yesterday.yesterday
    g.save!
    goals.delete(g)
    assert_find_actual(goals)

    g2 = g.create_next_goal_in_cycle
    g2.save!
    g3 = g2.create_next_goal_in_cycle
    g3.save!
    goals << g3
    assert_find_actual(goals)

  end


  test "should validate category user" do
    save_rupert
    g = create_goal(true, @jarek)
    g.category = @rupert.income
    assert !g.save
    assert g.errors.on(:user_id)
  end



  #TODO
  #test_actual_value
  #test_finish
  #test_finished?
  #test_positive?
  #test_all_goals_in_cycle
  #test_next_goal_in_cycle

  private
  def assert_find_past(goals)
    past = Goal.find_past(@jarek)
    assert_equal goals.map{|e|e.id}.sort, past.map{|e|e.id}.sort
  end

  def assert_find_actual(goals)
    past = Goal.find_actual(@jarek)
    assert_equal goals.map{|e|e.id}.sort, past.map{|e|e.id}.sort
  end




end
