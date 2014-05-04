class UserStatisticsService
  attr_accessor :settings
  attr_accessor :anime_rates, :manga_rates
  attr_accessor :seasons
  attr_accessor :genres
  attr_accessor :studios, :publishers

  # стандартный формат дат для сравнения
  DateFormat = "%Y-%m-%d"

  def initialize user, current_user
    @user = user
    @current_user = current_user
    @settings = user.preferences

    @seasons = AniMangaSeason.all
    @genres, @studios, @publishers = AniMangaAssociationsQuery.new.fetch

    @anime_rates = @user
      .anime_rates
      .joins('join animes on animes.id = target_id')
      .select('user_rates.*, animes.rating, animes.kind, animes.duration, animes.episodes as entry_episodes, animes.episodes_aired as entry_episodes_aired')
      .each do |v|
        v[:rating] = I18n.t("RatingShort.#{v[:rating]}") if v[:rating] != 'None'
      end

    @anime_valuable_rates = @anime_rates.select {|v| v.status == UserRateStatus.get(UserRateStatus::Completed) || v.status == UserRateStatus.get(UserRateStatus::Watching) }
    @anime_history = @user
      .history
      .where(target_type: Anime.name)
      .where("action in (?) or (action = ? and value = ?)",
              [UserHistoryAction::Episodes, UserHistoryAction::CompleteWithScore],
              UserHistoryAction::Status, UserRateStatus.get(UserRateStatus::Completed))

    #@imports = @user.history.where(action: [UserHistoryAction::MalAnimeImport, UserHistoryAction::ApAnimeImport, UserHistoryAction::MalMangaImport, UserHistoryAction::ApMangaImport])

    @manga_rates = @user
      .manga_rates
      .joins('join mangas on mangas.id = target_id')
      .select("user_rates.*, mangas.rating, #{Manga::Duration} as duration, mangas.kind, mangas.chapters as entry_episodes, 0 as entry_episodes_aired")
      .each do |v|
        v[:rating] = I18n.t("RatingShort.#{v[:rating]}") if v[:rating] != 'None'
      end
    @manga_valuable_rates = @manga_rates.select {|v| v.status == UserRateStatus.get(UserRateStatus::Completed) || v.status == UserRateStatus.get(UserRateStatus::Watching) }
    @manga_history = @user
      .history
      .where(target_type: Manga.name)
      .where("action in (?) or (action = ? and value = ?)",
              [UserHistoryAction::Chapters, UserHistoryAction::CompleteWithScore],
              UserHistoryAction::Status, UserRateStatus.get(UserRateStatus::Completed))
  end

  # формирование статистики
  def fetch
    stats = {}

    stats[:graph_statuses] = by_statuses
    stats[:graph_statuses].reverse! if @user.preferences.manga_first?

    stats[:statuses] = { anime: anime_statuses, manga: manga_statuses }

    stats[:scores] = by_criteria :score, 1.upto(10).to_a.reverse

    i18n = if !@current_user || (@current_user && @current_user.preferences.russian_genres?)
      ':klass.Short.%s'
    else
      nil
    end

    stats[:types] = by_criteria :kind, ['TV', 'Movie', 'OVA', 'ONA', 'Music', 'Special'] + ["Manga", "One Shot", "Manhwa", "Manhua", "Novel", "Doujin"], i18n

    stats[:ratings] = by_criteria :rating, ['G', 'PG', 'PG-13', 'R+', 'NC-17', 'Rx'].reverse#, -> v { v[:rating] != 'None' }

    stats[:has_anime?] = @anime_rates.any?
    stats[:has_manga?] = @manga_rates.any?

    stats[:genres] = {
      anime: by_categories('genre', @genres, @anime_valuable_rates, [], 19),
      manga: by_categories('genre', @genres, [], @manga_valuable_rates, 19)
    }
    stats[:studios] = { anime: by_categories('studio', @studios.select {|v| v.real? }, @anime_valuable_rates, nil, 17) }
    stats[:publishers] = { manga: by_categories('publisher', @publishers, nil, @manga_valuable_rates, 17) }

    #stats[:anime_types_intervals] = by_interval :kind, ['TV', 'Movie', 'OVA', 'ONA', 'Music', 'Special'], 80, false
    #stats[:anime_types_intervals] = by_interval :kind, ['TV', 'Movie', 'OVA', 'ONA', 'Music', 'Special'], 42, true
    stats[:activity] = by_activity 42 #41

    #if @settings.manga_genres?
      #stats[:manga_genre] = by_categories('genre', @genres, [], @manga_rates, 20)
    #end

    #if @settings.manga_publishers?
      #stats[:manga_publisher] = by_categories('publisher', @publishers, nil, @manga_rates, 12)
    #end

    #if @settings.genres_graph?
      #stats[:genre] = by_categories('genre', @genres, @anime_rates, @manga_rates, 8)
    #end

    stats
  end

private
  # статистика активности просмотра аниме / чтения манги
  def by_activity(intervals)
    ##[
      ##{type: :anime, rates: @anime_rates, histories: @anime_history},
      ##{type: :manga, rates: @manga_rates, histories: @manga_history}
    ##].each_with_object({}) do |stat, rez|
      ##rez[stat[:type]] = compute_by_activity stat[:type].to_s, stat[:rates], stat[:histories], intervals
    ##end
    #{
      #stats: compute_by_activity(@anime_rates, @manga_rates, @anime_history, @manga_history, intervals)
    #}
    compute_by_activity(@anime_rates, @manga_rates, @anime_history, @manga_history, intervals)
  end

  # вычисление статистики активности просмотра аниме / чтения манги
  def compute_by_activity(anime_rates, manga_rates, anime_histories, manga_histories, intervals)
    histories = anime_histories + manga_histories
    rates = anime_rates + manga_rates
    return {} if histories.empty?

    # минимальная дата старта статистики
    if @settings.statistics_start_on
      histories.select! { |v| v.created_at >= @settings.statistics_start_on }
    end

    imported = Set.new histories.select { |v| v.action == UserHistoryAction::Status || v.action == UserHistoryAction::CompleteWithScore}
        .group_by { |v| v.updated_at.strftime DateFormat }
        .select { |k,v| v.size > 15 }
        .values.flatten
        .map(&:id)

    # заполняем кеш начальными данными
    cache = rates.each_with_object({}) do |v,rez|
      rez["#{v.target_id}#{v.target_type}"] = {
        duration: v[:duration],
        completed: 0,
        episodes: v[:entry_episodes] > 0 ? v[:entry_episodes] : v[:entry_episodes_aired]
      }
    end
    cache_keys = Set.new cache.keys

    # исключаем импортированное
    histories = histories.select { |v| !imported.include?(v.id) }
    # исключаем то, для чего rates нет, т.е. впоследствии удалённое из списка
    histories = histories.select { |v| cache_keys.include?("#{v.target_id}#{v.target_type}") }
    return {} if histories.empty?

    start_date = histories.map { |v| v.created_at }.min.to_datetime
    end_date = histories.map { |v| v.updated_at }.max.to_datetime

    distance = [(end_date.to_i - start_date.to_i) / intervals, 86400].max

    0.upto(intervals).map do |num|
      from = start_date + (distance*num).seconds
      to = from + distance.seconds + 1.second

      next if from > DateTime.now || from > end_date + 1.hour

      history = histories.select { |v| v.updated_at >= from && v.updated_at < to }

      spent_time = 0

      history.each do |entry|
        cached = cache["#{entry.target_id}#{entry.target_type}"]
        #ap entry
        #ap cached

        entry_time = cached[:duration]/60.0 * if entry.action == UserHistoryAction::CompleteWithScore || entry.action == UserHistoryAction::Status
          # бывает ситуация, когда точное число эпизодов не известно и completed > episodes, в таком случае берём сбсолютное значение
          (cached[:episodes] - cached[:completed]).abs
        else
          episodes = entry.value.split(',').map(&:to_i)
          episodes.unshift(entry.prior_value.to_i+1)
          episodes.uniq!

          completed = cached[:completed]

          # откусываем с конца элементы, т.к. могут задать меньшее число эпизодов после большего
          while episodes.length > 1 && episodes.last < episodes.first
            episodes.pop
          end

          if episodes.size == 1
            cached[:completed] = episodes.first
            if completed > episodes.first
              0
            else
              episodes.first - completed
            end
          else
            cached[:completed] = episodes.last
            count = episodes.last - episodes.first + 1

            # могли указать какой-нибудь сериал, что смотрят сейчас какую-нибудь сотую серию и посчитается как 100-1
            if count > 60
              5
            else
              count
            end
          end
        end

        raise "negative value for entry: #{entry.action}-#{entry.id}, completed: #{completed}, episodes: #{entry.value}" if entry_time < 0
        spent_time += entry_time
      end

      {
        name: [from.to_i, to.to_i],
        value: spent_time.ceil
      }
    end.compact

    #{
      #type: 'anime',
      #stats: stats
    #}
  end

  # статистика по интервалам
  #def by_interval(crirteria, variants, intervals, with_increment)
    #rates = @anime_rates

    #return if rates.empty?
    #start_date = rates.map { |v| v.updated_at }.min.to_datetime
    #end_date = rates.map { |v| v.updated_at }.max.to_datetime

    #distance_in_days = (end_date - start_date).to_i
    #interval_in_days = [distance_in_days / intervals, 1].max

    #stats = {
      #categories: [],
      #series: variants.each_with_object({}) { |v,rez| rez[v] = { data: [], name: v } }
    #}

    #prior_data = nil
    #0.upto(intervals).each do |num|
      #date = start_date + (interval_in_days*num).days
      #break if date > DateTime.now
      ## катеогрии - даты
      #stats[:categories] << date.strftime('%d/%m')

      ## накапливаем статистику в темповую переменную
      #tmp_data = variants.each_with_object({}) { |v,rez| rez[v] = 0 }
      #rates.select { |v| v.updated_at <= date + 24.hours }.each do |rate|
        #tmp_data[rate[:kind]] += 1 if tmp_data[rate[:kind]].present?
      #end

      ## и затем скидываем всё
      #tmp_data.each do |k,v|
        #stats[:series][k][:data] << (prior_data && with_increment ? [v - prior_data[k], 0].max : v)
      #end
      #prior_data = tmp_data
    #end
    ## т.к. в итоге должен быть словарь, а не хеш
    #stats[:series] = stats[:series].values

    #stats
  #end

  # статистика по определённому критерию
  def by_criteria criteria, variants, i18n = nil, filter = -> v { true }
    [{klass: Anime, rates: @anime_valuable_rates}, {klass: Manga, rates: @manga_valuable_rates}].each_with_object({}) do |stat, rez|
      #next unless @settings.send("#{stat[:klass].name.downcase}?")

      #entry = {
        #type: stat[:klass].name.downcase.to_sym,
        #stats: variants.map do |variant|
          #value = stat[:rates].select { |v| filter.(v) }.select {|v| v[criteria] == variant }.size
          #next if value == 0

          #{
            #name: i18n ? I18n.t(i18n.sub(':klass', stat[:klass].name) % variant) : variant,
            #value: value
          #}
        #end.compact
      #}
      #entry[:total] = entry[:stats].sum {|v| v[:value] }
      entry = variants.map do |variant|
        value = stat[:rates].select { |v| filter.(v) }.select {|v| v[criteria] == variant }.size
        next if value == 0

        {
          name: i18n ? I18n.t(i18n.sub(':klass', stat[:klass].name) % variant) : variant,
          value: value
        }
      end.compact

      rez[stat[:klass].name.downcase.to_sym] = entry
    end
  end

  def anime_statuses
    UserRateStatus.statuses.map do |status|
      {
        id: status[:id],
        name: status[:name],
        size: @anime_rates.select {|v| v.status == status[:id] }.size
      }
    end
  end

  def manga_statuses
    UserRateStatus.statuses.map do |status|
      {
        id: status[:id],
        name: status[:name],
        size: @manga_rates.select {|v| v.status == status[:id] }.size
      }
    end
  end

  # статистика по статусам аниме и манги в списке пользователя
  def by_statuses
    data = [
      @settings.anime_in_profile? ? [Anime.name, anime_statuses] : nil,
      @settings.manga_in_profile? ? [Manga.name, manga_statuses] : nil
    ].compact.map do |klass,stat|
      [
        klass,
        stat,
        {
          total: stat.sum {|v| v[:size] },
          completed: stat.select {|v| v[:name] == UserRateStatus::Completed }.sum {|v| v[:size] },
          dropped: stat.select {|v| v[:name] == UserRateStatus::Dropped }.sum {|v| v[:size] },
          incompleted: stat.select {|v| v[:name] != UserRateStatus::Completed && v[:name] != UserRateStatus::Dropped }.sum {|v| v[:size] }
        }
      ]
    end

    data.each do |klass,stat,graph|
      other_stat = data.select { |_klass,_stat,_graph| _klass != klass }

      graph[:scale] = if data.size == 1 || other_stat.sum {|_klass,_stat,_graph| _graph[:total] } == 0
        1.0
      else
        other_total = other_stat[0][2][:total]
        [other_total > 0 ? graph[:total]*1.0 / other_total : 0, 1.0].min
      end
    end
  end

  # выборка статистики по категориям в списке пользователя
  def by_categories(category_name, categories, anime_rates, manga_rates, limit)
    # статистика по предпочитаемым элементам
    categories_by_id = categories.inject({}) do |data,v|
      data[v.id] = v
      data
    end

    # выборка подсчитываемых элементов
    rates = []
    [['anime', anime_rates || []], ['manga', manga_rates || []]].each do |type, rates_data|
      # указывает ли пользовать вообще оценки?
      no_scores = (rates_data || []).all? { |v| v.score.nil? || v.score == 0 }

      ids = (no_scores ? rates_data : rates_data.select { |v| v.score && v.score >= 7 }).map(&:target_id)

      rates += if ids.any?
        query = "select #{category_name}_id from #{[category_name.tableize, type.pluralize].sort.join('_')} where #{type}_id in (#{ids.join(',')})"
        ActiveRecord::Base.connection
                          .execute(query)
                          .to_enum
                          .map { |v| categories_by_id.include?(v[0].to_i) ? categories_by_id[v[0].to_i] : nil }
                          .select { |v| v && v != 'School' && v != 'Action' }
      else
          []
      end
    end

    stats_by_categories = rates.each_with_object({}) do |v,memo|
      memo[v] ||= 0
      memo[v] += 1
    end.sort_by {|k,v| v }.reverse.take(limit)

    # подсчёт процентов
    sum = stats_by_categories.sum {|k,v| v }.to_f

    stats = sum > 8 ? stats_by_categories.map do |k,v|
      [k, ((v * 1000 / sum).to_i / 10.0).to_f]
    end.compact.sort_by {|k,v| k.name } : []

    if stats.any?
      # для жанров занижаем долю комедий
      if category_name == 'genre'
        stats.map! do |genre|
          if genre[0] == 'Комедия'
            [genre[0], genre[1]*0.6]
          else
            genre
          end
        end
      end
      max = stats.max {|l,r| l[1] <=> r[1] }[1]
      min = stats.min {|l,r| l[1] <=> r[1] }[1]

      stats.map do |category|
        {
          category: category[0],
          percent: category[1],
          scale: max == min ? 1 : ((category[1]-min)/(max-min)*4).round(0).to_i
        }
      end
    else
      stats
    end
  end
end
