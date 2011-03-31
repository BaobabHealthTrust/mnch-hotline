require File.dirname(__FILE__) + '/../test_helper'

class LocationTest < ActiveSupport::TestCase 
  fixtures :location

  context "Locations" do
    should "be valid" do
      location = Location.make
      assert location.valid?
    end
    
    should "extract the site id from the description" do
      assert_equal "750", location(:neno_district_hospital).site_id
    end

    should "return children" do
      assert_equal 5, Location.find_by_name("Neno District Hospital").children.length
      assert_equal [], Location.find_by_name("Neno District Hospital - Outpatient").children
    end

    should "return parent" do
      ndh = Location.find_by_name("Neno District Hospital")
      assert_nil ndh.parent
      assert_equal ndh, Location.find_by_name("Neno District Hospital - Outpatient").parent
    end

    should "return related locations including self" do
      ndh = Location.find_by_name("Neno District Hospital")
      assert_equal 6, ndh.related_locations_including_self.length
      assert_equal ndh.related_locations_including_self.length, Location.find_by_name("Neno District Hospital - Outpatient").related_locations_including_self.length
    end

    should "be able to determine if two locations are related" do
      ndh = Location.find_by_name("Neno District Hospital")
      assert ndh.related_to_location? Location.find_by_name("Neno District Hospital - Outpatient")
      assert !(ndh.related_to_location? Location.find_by_name("Matandani Rural Health Center"))
    end
  end  
end
