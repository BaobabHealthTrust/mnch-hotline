class Role < ActiveRecord::Base
  set_table_name "role"
  set_primary_key "role"
  include Openmrs
  has_many :role_roles, :foreign_key => :parent_role # no default scope
  has_many :role_privileges, :foreign_key => :role, :dependent => :delete_all # no default scope
  has_many :privileges, :through => :role_privileges, :foreign_key => :role # no default scope
  has_many :user_roles, :foreign_key => :role # no default scope

  def self.setup_privileges_for_roles
    Role.find(:all).each do |r|
      Privilege.find(:all).each do |p|
        self.add_privilege(p)
      end
    end
  end

  def add_privilege(privilege)
    rp = RolePrivilege.new
    rp.role = self.role
    rp.privilege = privilege.privilege
    rp.save
  end
end
