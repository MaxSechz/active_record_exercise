class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |name|
      define_method(name) { instance_variable_get("@#{name}".to_sym) }
      define_method("#{name}=".to_sym) { |new_val| instance_variable_set("@#{name}".to_sym, new_val)}
    end
  end
end
