
class Factory
  # You need a single user to start the system
  User.destroy_all
  
  def self.creator
    return @@creator.user_id if defined?(@@creator)
    @@creator = User.new(:username => 'default', :plain_password => 'password')
    @@creator.user_id = User.auto_increment
    @@creator.save!      
    @@creator.user_id
  end
end  

Factory.sequence :username do |n|
  "USER#{n}"
end

# In the OpenMRS world this factory would also create an associated person
# And the id for the person and user would be in sync (in 1.5)
Factory.define :user, :class => :user do |user|
  user.creator         { Factory.creator } 
  user.user_id         { User.auto_increment }
  user.username        { Factory.next :username }
  user.plain_password  { "password" }
  user.system_id       { "Electronic Health Record User" }
end