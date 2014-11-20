class HsaVillage < ActiveRecord::Base
  has_many :users, :foreign_key => :user_id
  has_many :villages, :foreign_key => :village_id   
  has_many :healthcenters, :foreign_key => :heath_center_id
  has_many :districts, :foreign_key => :district_id
end
