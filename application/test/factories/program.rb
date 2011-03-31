Factory.define :program, :class => :program do |program|
  program.name "Sample Program"
  program.concept Factory(:concept)
  program.creator { Factory.creator }
end
