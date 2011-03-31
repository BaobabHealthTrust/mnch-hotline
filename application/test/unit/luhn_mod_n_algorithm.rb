require File.dirname(__FILE__) + '/../test_helper'

class LuhnModNAlgorithmTest < ActiveSupport::TestCase 
  context "Luhn variable base algorithm" do
    setup do
      # we are taking out the following letters B, I, O, Q, S, Z because the might be mistaken for 8, 1, 0, 0, 5, 2 respectively
      @valid = ["0","1","2","3","4","5","6","7","8","9","A","C","D","E","F","G","H","J","K","L","M","N","P","R","T","U","V","W","X","Y"] 
      @luhn = LuhnModNAlgorithm.new(@valid)    
    end
    
    should "calculate a check digit for base 30 strings" do
      assert_equal 'E', @luhn.generate_check_character("1142KLMXY") 
    end
    
    should "validate valid check digits" do
      assert @luhn.validate_check_character("1142KLMXYE") 
    end
    
    should "not validate invalid check digits" do
      assert !@luhn.validate_check_character("1142KLMXYD") 
    end    
  end
end