require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    column_names = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{table_name}
      LIMIT
        0
    SQL

    column_names.map!(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) { attributes[column] }
      define_method("#{column}=".to_sym) { |new_val| attributes[column] = new_val}
    end
  end

  def self.table_name=(table_name)
    instance_variable_set("@table_name".to_sym, table_name)
  end

  def self.table_name
    instance_variable_get("@table_name".to_sym) || self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    parsed_results = results.map do |hash|
      self.new(hash)
    end

    parsed_results
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    return nil if result.length == 0
    self.new(result.first)
  end

  def initialize(params = {})
    self.class.columns.each {|column| send("#{column}=".to_sym, nil)}
    params.each do |attr_name, value|
      raise "unknown attribute '#{attr_name}'" unless attributes.include?(attr_name.to_sym)
      send("#{attr_name}=".to_sym, value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def attribute_names
    attributes.keys
  end

  def insert
    col_names = attribute_names.join(',')
    question_marks = Array.new(attribute_values.length) {"?"}.join(',')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = attribute_names.map{ |col| "#{col} = ?"}.join(',')

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{col_names}
      WHERE
        id = ?
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end
end
