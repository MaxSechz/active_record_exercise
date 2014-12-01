require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      foreign_key: (name.to_s + 'Id').underscore.to_sym,
      primary_key: :id,
      class_name: name.to_s.camelcase
    }

    options = defaults.merge(options)
    options.each {|key, value| send((key.to_s + '=').to_sym, value)}
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      foreign_key: (self_class_name.to_s + 'Id').underscore.to_sym,
      primary_key: :id,
      class_name: name.to_s.singularize.camelcase
    }
    options = defaults.merge(options)
    options.each {|key, value| send((key.to_s + '=').to_sym, value)}
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      foreign_val = send(options.foreign_key)
      result = options.model_class.where(id: foreign_val)
      result.first.nil? ? nil : result.first
    end

  end

  def has_many(name, options = {})
    assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      foreign_val = send(options.primary_key)
      result = options.model_class.where(options.foreign_key => foreign_val)
    end

  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
