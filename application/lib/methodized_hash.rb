class MethodizedHash < HashWithIndifferentAccess
  def initialize(constructor = {})
    super(constructor)
    methodize!
    freeze
  end

  def self.[](*values)
    # HashWithIndifferentAccess[...] doesn't convert symbols to strings
    obj = super().update(Hash[*values])
    obj.methodize!
    obj.freeze
  end

  def self.methodize(key)
    # not smart (doesn't move leading numbers, etc) but works for reporting
    key.to_s.parameterize.tr('-','_').to_sym
  end

  def methodize!
    @methodized = Hash[keys.map {|k| [self.class.methodize(k), k.to_s]}]
  end

  def methodized_keys
    @methodized.keys
  end

  # could've used OpenStruct instead but doesn't show what is defined
  def method_missing(name, *args, &blk)
    self[@methodized[name]]
  end

end
