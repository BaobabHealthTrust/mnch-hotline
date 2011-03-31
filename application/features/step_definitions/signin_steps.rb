Given /^I am not signed in$/ do
  visit "/logout"
end

Given /^I am signed in$/ do
  Given %{I am signed in at the reception station}
end

Given /^I am signed in at (.+)$/ do |location|
  visit "/login"
  fill_in "Enter user name", :with => 'admin'
  click_button "Next"
  fill_in "Enter password", :with => 'admin'
  click_button "Finish"
  case location
    when "the reception station"
      fill_in "Workstation location", :with => '7'    
      click_button "Finish"
    when "the clinician station"
      fill_in "Workstation location", :with => '31'    
      click_button "Finish"
  end
end