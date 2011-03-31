require 'digest/sha1'
require 'digest/sha2'

class User < ActiveRecord::Base
  set_table_name :users
  set_primary_key :user_id
  include Openmrs

  before_save :set_password, :before_create

  cattr_accessor :current_user
  attr_accessor :plain_password

  has_many :user_properties, :foreign_key => :user_id # no default scope
  has_many :user_roles, :foreign_key => :user_id, :dependent => :delete_all # no default scope
  has_many :names, :class_name => 'PersonName', :foreign_key => :person_id, :dependent => :destroy, :order => 'person_name.preferred DESC', :conditions => {:voided =>  0}

  def first_name
    self.names.first.given_name rescue ''
  end

  def last_name
    self.names.first.family_name rescue ''
  end

  def name
    name = self.names.first
    "#{name.given_name} #{name.family_name}"
  end

  def try_to_login
    User.authenticate(self.username,self.password)
  end
  
  def set_password
    # We expect that the default OpenMRS interface is used to create users
    self.password = encrypt(self.plain_password, self.salt) if self.plain_password
  end
   
  def self.authenticate(login, password)
    u = find :first, :conditions => {:username => login} 
    u && u.authenticated?(password) ? u : nil
  end
      
  def authenticated?(plain)
    encrypt(plain, salt) == password || Digest::SHA1.hexdigest("#{plain}#{salt}") == password || Digest::SHA512.hexdigest("#{plain}#{salt}") == password
  end
  
  def admin?
    admin = user_roles.map{|user_role| user_role.role }.include? 'Informatics Manager'
    admin = user_roles.map{|user_role| user_role.role }.include? 'System Developer' unless admin
    admin = user_roles.map{|user_role| user_role.role }.include? 'Superuser' unless admin
    admin
  end  
      
  # Encrypts plain data with the salt.
  # Digest::SHA1.hexdigest("#{plain}#{salt}") would be equivalent to
  # MySQL SHA1 method, however OpenMRS uses a custom hex encoding which drops
  # Leading zeroes
  def encrypt(plain, salt)
    encoding = ""
    digest = Digest::SHA1.digest("#{plain}#{salt}") 
    (0..digest.size-1).each{|i| encoding << digest[i].to_s(16) }
    encoding
  end  

   def before_create
    super
    self.salt = User.random_string(10) if !self.salt?
    self.password = User.encrypt(self.password,self.salt)
  end
 
   def self.random_string(len)
    #generat a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def self.encrypt(password,salt)
    Digest::SHA1.hexdigest(password+salt)
  end
 
  # This goes away after 1.6 is here I think, but the users table in 1.5 has no
  # auto-increment
  def self.auto_increment
    User.last.user_id + 1 rescue 0
  end
end
