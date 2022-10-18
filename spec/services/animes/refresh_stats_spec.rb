describe Animes::RefreshStats do
  subject { described_class.call scope }

  let(:scope) { Anime.all }

  let(:anime_1) { create :anime, options: anime_1_options }
  let(:anime_2) { create :anime }

  let(:user_4) { create :user }

  let(:anime_1_options) { [] }
  before { user_3.update roles: %i[cheat_bot] }

  let!(:anime_1_rate_1) do
    create :user_rate,
      target: anime_1,
      user: user_1,
      status: :completed,
      score: 10
  end
  let!(:anime_1_rate_2) do
    create :user_rate,
      target: anime_1,
      user: user_2,
      status: :completed,
      score: 8
  end
  let!(:anime_1_rate_3) do
    create :user_rate,
      target: anime_1,
      user: user_3,
      status: :dropped,
      score: 1
  end
  let!(:anime_1_rate_4) do
    create :user_rate,
      target: anime_1,
      user: user_4,
      status: :watching,
      score: 10
  end
  let!(:anime_2_rate_1) do
    create :user_rate,
      target: anime_2,
      user: user_1,
      status: :completed,
      score: 10
  end

  context 'no anime stat' do
    it do
      expect { subject }.to change(AnimeStat, :count).by 2
      expect(anime_1.stats).to have_attributes(
        scores_stats: [['10', 2], ['8', 1]],
        list_stats: [['completed', 2], ['watching', 1]]
      )
      expect(anime_2.stats).to have_attributes(
        scores_stats: [['10', 1]],
        list_stats: [['completed', 1]]
      )
    end

    context 'anime_stat_history entry' do
      it do
        expect { subject }.to change(AnimeStatHistory, :count).by 2
        expect(anime_1.anime_stat_histories.first).to have_attributes(
          scores_stats: [['10', 2], ['8', 1]],
          list_stats: [['completed', 2], ['watching', 1]],
          created_on: Time.zone.today,
          score_2: anime_1.score_2
        )
        expect(anime_2.anime_stat_histories.first).to have_attributes(
          scores_stats: [['10', 1]],
          list_stats: [['completed', 1]],
          created_on: Time.zone.today,
          score_2: anime_2.score_2
        )
      end
    end
  end

  context 'has some stat' do
    let!(:anime_stat_2) { create :anime_stat, entry: anime_2 }
    let!(:manga_stat) { create :anime_stat, entry: manga }
    let(:manga) { create :manga }

    it do
      expect { subject }.to change(AnimeStat, :count).by 1
      expect { anime_stat_2.reload }.to raise_error ActiveRecord::RecordNotFound
      expect(manga_stat).to be_persisted
    end

    context 'anime_state_history entry' do
      let!(:anime_stat_history_1) do
        create :anime_stat_history, anime: anime_2, created_on: Time.zone.today
      end
      let!(:anime_stat_history_2) do
        create :anime_stat_history, anime: anime_2, created_on: Time.zone.yesterday
      end
      let!(:manga_stat_history) do
        create :anime_stat_history, manga: manga, created_on: Time.zone.today
      end

      it do
        expect { subject }.to change(AnimeStatHistory, :count).by 1
        expect { anime_stat_history_1.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(anime_stat_history_2).to be_persisted
        expect(manga_stat).to be_persisted
      end
    end

    describe 'it does not delete stats outside of requested scope' do
      let(:scope) { Anime.where(id: anime_1.id) }
      let!(:anime_stat_1) { create :anime_stat, entry: anime_1 }
      let!(:anime_stat_history_1) do
        create :anime_stat_history, anime: anime_1, created_on: Time.zone.today
      end
      let!(:anime_stat_2) { create :anime_stat, entry: anime_2 }
      let!(:anime_stat_history_2) do
        create :anime_stat_history, anime: anime_2, created_on: Time.zone.today
      end

      it do
        expect { subject }.to_not change AnimeStat, :count
        expect { anime_stat_1.reload }.to raise_error ActiveRecord::RecordNotFound
        expect { anime_stat_history_1.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(anime_stat_2.reload).to be_persisted
        expect(anime_stat_history_2.reload).to be_persisted
        expect(manga_stat).to be_persisted
      end
    end
  end

  context 'score_filter' do
    let(:anime_1_options) { ['score_filter_10_1'] }

    it do
      expect { subject }.to change(AnimeStat, :count).by 2
      expect(anime_1.stats).to have_attributes(
        scores_stats: [['10', 1], ['8', 1]],
        list_stats: [['completed', 2], ['watching', 1]]
      )
    end
  end
end
