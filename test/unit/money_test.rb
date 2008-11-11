require 'test_helper'
require 'money'

class MoneyTest < Test::Unit::TestCase
  
  
  def setup
    @zloty = Currency.new(:symbol => 'zl', :long_symbol => 'PLN', :name => 'Złoty', :long_name =>'Polski złoty')    
    @dolar = Currency.new(:symbol => '$', :long_symbol => 'USD', :name => 'Dolar', :long_name =>'Dolar amerykańcki')
    @euro = Currency.new(:symbol => '€', :long_symbol => 'EUR', :name => 'Euro', :long_name =>'Europejckie euro')
  end
  
  
  def test_initialize
    assert_nothing_raised do
      Money.new(@zloty => 10, @dolar =>15)
      Money.new(@zloty, 10)
      Money.new()
    end
    assert_raise ArgumentError do
      Money.new(1)
    end
    assert_raise ArgumentError do
      Money.new(1, 2, 3)
    end
  end
  
  
  def test_contains_currencies_from_constructor
    money = Money.new()
    assert_equal 0, money.currencies.size
    assert !money.currencies.include?(@zloty), "Object should only contain currencies used in constructor"
    assert !money.currencies.include?(@dolar), "Object should contain currencies used in constructor"
    assert !money.currencies.include?(@euro), "Object should contain currencies used in constructor"
    
    money = Money.new(@zloty => 10, @dolar =>15)
    assert_equal 2, money.currencies.size
    assert money.currencies.include?(@zloty), "Object should contain currencies used in constructor (zloty)"
    assert money.currencies.include?(@dolar), "Object should contain currencies used in constructor (dollar)"
    assert !money.currencies.include?(@euro), "Object should contain currencies used in constructor"
  end
  
  
  def test_returns_valid_values_from_constructor
    money = Money.new()
    assert_equal 0, money.value(@dolar), "Value for currency not contained should be 0"
    assert_equal 0, money.value(@zloty), "Value for currency not contained should be 0"
    
    money = Money.new(@zloty => 20.1, @dolar =>25)
    assert_equal 20.1, money.value(@zloty), "Returned values should not differ from those used in constructor"
    assert_equal 25, money.value(@dolar), "Returned values should not differ from those used in constructor"
  end
  
  
  def test_values_after_adding_value
    money = Money.new(@zloty => 11.1, @dolar =>22.2)
    money.add(0.9, @zloty)
    assert_equal 12, money.value(@zloty), "Should properly add values"
    
    money.add(-1.2, @dolar)
    assert_equal 21, money.value(@dolar), "Should properly subtract values"
    
    money.add(1_000_000, @euro)
    assert_equal 1_000_000, money.value(@euro), "Should properly add value from new currency"
  end
  
  
  def test_containst_currencies_after_adding_value
    money = Money.new(@zloty => 11)
    money.add(0.9, @zloty)
    assert money.currencies.include?(@zloty)
    assert 1, money.currencies.size
    assert !money.currencies.include?(@dolar)
    
    money.add(0.9, @dolar)
    assert money.currencies.include?(@zloty)
    assert money.currencies.include?(@dolar)
    assert 2, money.currencies.size
    
    money.add(123.9, @euro)
    assert money.currencies.include?(@zloty)
    assert money.currencies.include?(@dolar)
    assert money.currencies.include?(@euro)
    assert 3, money.currencies.size
  end


  def test_adding_two_money_objects
    money = Money.new(@zloty => 11, @euro =>12)
    assert_nothing_raised do 
      assert_currencies_list_unchanged money do
        money.add(Money.new())
        assert_equal 11, money.value(@zloty)
        assert_equal 12, money.value(@euro)
      end
    end

    assert_currencies_list_unchanged money do
      money.add(Money.new(@zloty => 10, @euro => 20))
      assert_equal 21, money.value(@zloty)
      assert_equal 32, money.value(@euro)
    end

    money.add(Money.new(@dolar => 5, @zloty => 10, @euro => 20))
    assert_equal 31, money.value(@zloty)
    assert_equal 52, money.value(@euro)
    assert_equal 5, money.value(@dolar)
    assert_equal 3, money.currencies.size
    assert money.currencies.include?(@dolar)
  end


  def test_modyfying_returned_all_values_is_not_possible
    money = Money.new()
    money.values_in_currencies + {@zloty => 5}
    assert money.empty?
  end

  def test_does_not_containt_zero_value_currency
    money = Money.new(@zloty => 0)
    assert_equal 0, money.currencies.size, "Should not contains currency which value is 0"
    
    money.add(10, @zloty)
    assert_equal 1, money.currencies.size
    assert money.currencies.include?(@zloty)
    
    money.add(-10, @zloty)
    assert_equal 0, money.currencies.size, "Should not contains currency which value is 0"
    assert !money.currencies.include?(@zloty)
  end


  def test_emptyness
    money = Money.new()
    assert money.is_empty?
    
    money.add(10, @zloty)
    assert !money.is_empty?
    
    money.add(-10, @zloty)
    assert money.is_empty?
  end
  
  
  def test_range
    #testowanie zaokraglen tylko do 2 miejsc po przecinku i takie tam
  end

  private

  # Checks if list of returned currencies is the same before and after evaluating given block
  def assert_currencies_list_unchanged(money, &proc)
    raise "Code block required" unless Kernel.block_given?
    before = money.currencies
    proc.call
    assert_equal before, money.currencies
  end
  
end
