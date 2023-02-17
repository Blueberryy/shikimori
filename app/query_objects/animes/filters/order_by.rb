class Animes::Filters::OrderBy < Animes::Filters::FilterBase # rubocop:disable ClassLength
  method_object :scope, :value

  COMMON_FIELDS = %i[
    name
    russian
    status
    popularity
    ranked
    ranked_shiki
    ranked_random
    random
    released_on
    aired_on
    id
    id_desc
    rate_id
    rate_status
    rate_updated
    rate_score
    site_score
    kind
    licensor
    user_1
    user_2
    score
    score_2
    created_at
    created_at_desc
  ]

  AnimeField = Types::Strict::Symbol
    .constructor(&:to_sym)
    .enum(:episodes, *COMMON_FIELDS)

  MangaField = Types::Strict::Symbol
    .constructor(&:to_sym)
    .enum(:chapters, :volumes, *COMMON_FIELDS)

  Field = Types::Strict::Symbol
    .constructor(&:to_sym)
    .enum(*(AnimeField.values + MangaField.values).uniq)

  dry_type Field
  field :order

  DEFAULT_ORDER = Field[:ranked]

  ORDER_SQL = {
    Field[:name] => '%<table_name>s.name',
    Field[:russian] => '%<table_name>s.russian, %<table_name>s.name',
    Field[:episodes] => ( # rubocop:disable Style/RedundantParentheses
      <<-SQL.squish
        (case
          when %<table_name>s.episodes = 0
          then %<table_name>s.episodes_aired
          else %<table_name>s.episodes
        end) desc
      SQL
    ),
    Field[:chapters] => '%<table_name>s.chapters desc',
    Field[:volumes] => '%<table_name>s.volumes desc',
    Field[:status] => '%<table_name>s.status',
    Field[:popularity] => ( # rubocop:disable Style/RedundantParentheses
      <<-SQL.squish
        (case
          when %<table_name>s.popularity = 0
          then 999999
          else %<table_name>s.popularity
        end)
      SQL
    ),
    Field[:score] => '%<table_name>s.score desc',
    Field[:score_2] => '%<table_name>s.score_2 desc',
    Field[:ranked] => ( # rubocop:disable Style/RedundantParentheses
      <<-SQL.squish
        (case
          when %<table_name>s.ranked = 0
          then 999999
          else %<table_name>s.ranked
        end), %<table_name>s.score desc
      SQL
    ),
    Field[:ranked_shiki] => '%<table_name>s.ranked_shiki, %<table_name>s.score_2 desc',
    Field[:released_on] => ( # rubocop:disable Style/RedundantParentheses
      <<-SQL.squish
        (case
          when %<table_name>s.released_on_computed is null
          then %<table_name>s.aired_on_computed
          else %<table_name>s.released_on_computed
        end) desc
      SQL
    ),
    Field[:aired_on] => "coalesce(%<table_name>s.aired_on_computed, '1900-01-01') desc",
    Field[:id] => '%<table_name>s.id',
    Field[:id_desc] => '%<table_name>s.id desc',
    Field[:created_at] => '%<table_name>s.created_at',
    Field[:created_at_desc] => '%<table_name>s.created_at desc',
    Field[:rate_id] => 'user_rates.id',
    Field[:rate_status] => 'user_rates.status',
    Field[:rate_updated] => 'user_rates.updated_at desc, user_rates.id',
    Field[:rate_score] => ( # rubocop:disable Style/RedundantParentheses
      <<-SQL.squish
        user_rates.score desc,
        %<table_name>s.name,
        %<table_name>s.id
      SQL
    ),
    Field[:site_score] => '%<table_name>s.site_score desc',
    Field[:kind] => '%<table_name>s.kind',
    Field[:licensor] => '%<table_name>s.licensor',
    Field[:ranked_random] => '%<table_name>s.ranked_random',
    # TODO: after 2023-01-01 switch 'random()' to '%<table_name>s.ranked_random'
    Field[:random] => 'random()'
  }

  CUSTOM_SORTINGS = [
    [Field[:user_1]],
    [Field[:user_2]]
  ]

  USER_RATES_SORTINGS = [
    [Field[:rate_id]],
    [Field[:rate_status]],
    [Field[:rate_updated]],
    [Field[:rate_score]]
  ]

  def call
    return @scope if custom_sorting?

    fail_with_negative! if negatives.any?
    fail_with_scope! if user_rates_sortings? && scope_missing_user_rates?

    @scope.order(self.class.arel_sql(terms: positives, scope: @scope))
  end

  def self.arel_sql scope:, term: nil, terms: nil
    if term
      term_sql term: term, scope: scope, arel_sql: true
    else
      terms_sql terms: terms, scope: scope, arel_sql: true
    end
  end

  def self.terms_sql terms:, scope:, arel_sql:
    sql = (terms + [Field[:id]])
      .map { |term| term_sql term: term, scope: scope, arel_sql: false }
      .uniq
      .join(',')

    arel_sql ? Arel.sql(sql) : sql
  end

  def self.term_sql term:, scope:, arel_sql:
    sql = format(
      ORDER_SQL[scope.table_name == 'animes' ? AnimeField[term] : MangaField[term]],
      table_name: scope.table_name
    )

    arel_sql ? Arel.sql(sql) : sql
  end

private

  def fixed_value
    @value.presence || DEFAULT_ORDER
  end

  def custom_sorting?
    CUSTOM_SORTINGS.include? positives
  end

  def user_rates_sortings?
    USER_RATES_SORTINGS.include? positives
  end

  def scope_missing_user_rates?
    !@scope.to_sql.match?(/(?:inner|left) join (?:'|"|)user_rates(?:'|"|)/i)
  end
end
