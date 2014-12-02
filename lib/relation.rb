class Relation

  attr_reader :params

  def initialize(owner, params = {})
    @owner = owner
    @params = params
  end

  def where(new_params = {})
    @params = @params.merge(new_params)
  end

  def first
    execute { "ORDER BY #{@owner.table_name}.id ASC LIMIT 1" }.first
  end

  def to_a
    execute
  end

  def last
    execute { "ORDER BY #{@owner.table_name}.id DESC LIMIT 1" }.last
  end

  def [](index)
    results = execute
    results[index]
  end

  def inspect
    result = execute
    result.inspect
    super
  end

  def execute(&block)
    block ||= Proc.new {}
    table = @owner.table_name
    search_params = @params.map { |key, value| "#{table}.#{key} = '#{value}'" }.join(' AND ')
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table}
      WHERE
        #{search_params}
        #{block.call}
    SQL

    @owner.parse_all(results)
  end

end
