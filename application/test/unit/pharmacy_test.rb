require File.dirname(__FILE__) + '/../test_helper'

class PharmacyTest < ActiveSupport::TestCase
  context "Pharmacy" do
    fixtures :pharmacy_encounter_type, :drug, :encounter_type, :encounter, :orders, :drug_order, :users

    should "be valid" do
      pharmacy = Pharmacy.make
      assert pharmacy.valid?
    end

    should "add stock" do
      Pharmacy.new_delivery(2,200,Date.today)
      assert_equal 200.0,Pharmacy.current_stock(2)
    end

    should "display stock according to given date" do
      old_date = (Date.today - 6.month)
      Pharmacy.new_delivery(5,100,old_date,nil,(Date.today + 3.year))
      Pharmacy.new_delivery(5,500,Date.today,nil,(Date.today + 3.year))
      assert_equal 100.0,Pharmacy.current_stock_as_from(5,old_date,(old_date + 3.day))
      assert_equal 600.0,Pharmacy.current_stock_as_from(5,Date.today)
    end

    should "edit stock" do
      Pharmacy.new_delivery(2,10000,(Date.today - 6.month))
      Pharmacy.drug_dispensed_stock_adjustment(2,2000,Date.today,"Given to another clinic")  
      assert_equal 8000.0,Pharmacy.current_stock(2)
    end

    should "give first dispensed date" do
      Pharmacy.new_delivery(2,10000,(Date.today - 9.month))
      Pharmacy.new_delivery(2,100000,Date.today)
      assert_equal (Date.today - 9.month),Pharmacy.first_delivery_date(2)
    end

  end
end
