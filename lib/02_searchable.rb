require_relative 'db_connection'
require_relative '01_sql_object'
require_relative 'relation.rb'

module Searchable
  def where(params = {})
      @relation = Relation.new(self, params)
  end
end

class SQLObject
  extend Searchable
end
