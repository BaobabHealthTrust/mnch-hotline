class Location < ActiveRecord::Base
  set_table_name "location"
  set_primary_key "location_id"
  has_many :obs, :foreign_key => :location_id
  has_many :patient_identifiers, :foreign_key => :location_id
  has_many :encounters, :foreign_key => :location_id
  belongs_to :parent, :foreign_key => :parent_location_id, :class_name => "Location"
  has_many :children, :foreign_key => :parent_location_id, :class_name => "Location"
  belongs_to :user, :foreign_key => :user_id
  has_many :location_tag_map, :foreign_key => :location_id

  include Openmrs

  cattr_accessor :current_location

  def site_id
    Location.current_health_center.description.match(/\(ID=(\d+)\)/)[1] 
  rescue 
    raise "The id for this location has not been set (#{Location.current_location.name}, #{Location.current_location.id})"   
  end

  # Looks for the most commonly used element in the database and sorts the results based on the first part of the string
  def self.most_common_program_locations(search)
    return (self.find_by_sql([
      "SELECT DISTINCT location.name AS name, location.location_id AS location_id \
       FROM location \
       INNER JOIN patient_program ON patient_program.location_id = location.location_id AND patient_program.voided = 0 \
       WHERE location.retired = 0 AND name LIKE ? \
       GROUP BY patient_program.location_id \
       ORDER BY INSTR(name, ?) ASC, COUNT(name) DESC, name ASC \
       LIMIT 10", 
       "%#{search}%","#{search}"]) + [self.current_health_center]).uniq
  end

  def children
    return [] if self.name.match(/ - /)
    Location.find(:all, :conditions => ["name LIKE ?","%" + self.name + " - %"])
  end

  def parent
    return nil unless self.name.match(/(.*) - /)
    Location.find_by_name($1)
  end

  def site_name
    self.name.gsub(/ -.*/,"")
  end

  def related_locations_including_self
    if self.parent
      return self.parent.children + [self]
    else
      return self.children + [self]
    end
  end

  def related_to_location?(location)
    self.site_name == location.site_name
  end

  def self.current_health_center
    @@current_health_center = Location.find(GlobalProperty.find_by_property("current_health_center_id").property_value)
  end

  def self.current_arv_code
    current_health_center.neighborhood_cell rescue nil
  end
  
  def Location.get_list
    return @@location_list
  end

  def self.search(search_string)
      field_name = "name"
      @names = self.find_by_sql("SELECT * FROM location WHERE name LIKE '%#{search_string}%' ORDER BY name ASC").collect{|name| name.send(field_name)}

  end

  def self.find_by_tag(location_tag)
    query  = "SELECT name FROM location, location_tag_map, location_tag " +
    "WHERE location.location_id = location_tag_map.location_id " +
      "AND location_tag.location_tag_id = location_tag_map.location_tag_id " +
      "AND location_tag.tag = '" + location_tag + "'"

      locations = Location.find_by_sql(query)
      locations
  end

end
