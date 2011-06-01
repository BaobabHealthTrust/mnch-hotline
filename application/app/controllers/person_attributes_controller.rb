class PersonAttributesController < ApplicationController
  def search(field_name, search_string, attribute_type)
    most_common_values = PersonAttribute.find_most_common(field_name, search_string, attribute_type)
    most_common_values = most_common_values.map{|attribute| attribute.send(field_name)}

    render :text => "<li>" + most_common_values.join("</li><li>") + "</li>"
  end
end
