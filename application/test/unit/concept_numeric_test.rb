require File.dirname(__FILE__) + '/../test_helper'

class ConceptNumericTest < ActiveSupport::TestCase 
  fixtures :concept_numeric, :concept

  context "Concept numerics" do
    should "have an associated concept" do
      assert_equal concept(:height), concept_numeric(:height_limits).concept
    end
    
    should "calculate the touchscreen toolkit limit options" do
      limits = concept_numeric(:height_limits).options
      result = {:min => 20, 
                :max => 90, 
                :absoluteMin => 10, 
                :absoluteMax => 100,
                :units => 'cm'}
      assert_equal result, limits
    end
  
    should "calculate the touchscreen toolkit precision options" do
      c = concept_numeric(:height_limits)
      c.update_attributes(:precise => 1)
      result = {
        :validationRule => "([0-9]+\\.[0-9])|Unknown$",
        :validationMessage => "You must enter a decimal between 0 and 9 (for example: 54<b>.6</b>)",
        :tt_pageStyleClass => "Numeric NumbersOnlyWithDecimal"}
      assert_equal result, c.precision
    end

    should "return blank precision options if not precise" do
      precision = concept_numeric(:height_limits).precision
      assert_equal({}, precision)
    end

    should "return blank limit options if all values are nil" do
      c = concept_numeric(:height_limits)
      c.update_attributes(:low_absolute => nil, 
                          :low_critical => nil,
                          :hi_absolute => nil,
                          :hi_critical => nil,
                          :units => nil)                          
      assert_equal({}, c.options)
    end

  end
end
