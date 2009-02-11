ENV["RAILS_ENV"] = "selenium"

require 'test_helper'

begin
  
  require 'selenium'

  class MenuTest < Test::Unit::TestCase
    self.use_transactional_fixtures = false
    
    def setup
      selenium_setup
      save_currencies
      save_rupert
      log_rupert
      @selenium.set_context("Menu Test")
    end


    def teardown
      @selenium.stop unless $selenium
      @verification_errors.each do |e|
        puts e.backtrace
      end
      
      assert_equal [], @verification_errors

      @selenium = nil
      Test::Unit::TestCase.use_transactional_fixtures = true
    end


    #Test user can click on each link on main page including top categories from quick acces
    def test_main_page_links

      go_home
      @selenium.click "kategorie-menu-link"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Twoje kategorie")
      }

      go_home
      @selenium.click "transfery-menu-link"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Lista transferów")
      }

      go_home
      @selenium.click "waluty-menu-link"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Waluty")
      }

      go_home
      @selenium.click "raporty-menu-link"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Raporty")
      }

      go_home
      @selenium.click "edycja-ustawien-menu-link"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Edycja ustawień")
      }

      go_home
      @selenium.click "//img[@alt='Manage My Money Logo']"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Twoje kategorie")
      }
      selenium_assert {
          assert @selenium.is_text_present("Zalogowany: #{@rupert.login}")
      }


      @rupert.categories.top.each do |cat|
        go_home
        @selenium.click "category-in-menu-#{cat.id}"
        @selenium.wait_for_page_to_load "30000"
        selenium_assert {
            assert @selenium.is_text_present("#{cat.name} [Edycja]")
        }
      end

      go_home
      @selenium.click "wyloguj-menu-link"
      @selenium.wait_for_page_to_load "30000"
      selenium_assert {
          assert @selenium.is_text_present("Logowanie")
      }
      selenium_assert {
          assert @selenium.is_text_present("Zaloguj się!")
      }
    end

    private
    def go_home
      @selenium.open "/"
      @selenium.wait_for_page_to_load "30000"
    end


  end
end unless TEST_ON_STALLMAN