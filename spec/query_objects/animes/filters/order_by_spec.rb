describe Animes::Filters::OrderBy do
  describe '#call' do
    subject { described_class.call scope, terms }

    let(:scope) { Anime.all }

    let!(:anime_1) do
      create :anime,
        ranked: 10,
        ranked_shiki: 1,
        ranked_random: 45,
        name: 'AAA',
        episodes: 10,
        aired_on: { year: 2001 }
    end
    let!(:anime_2) do
      create :anime,
        ranked: 5,
        ranked_shiki: 34,
        ranked_random: 6,
        name: 'CCC',
        episodes: 20,
        aired_on: { year: 2010 }
    end
    let!(:anime_3) do
      create :anime,
        ranked: 5,
        ranked_shiki: 124,
        ranked_random: 43,
        name: 'BBB',
        episodes: 0,
        episodes_aired: 15
    end

    context 'id' do
      let(:terms) { Animes::Filters::OrderBy::Field[:id] }
      it { is_expected.to eq [anime_1, anime_2, anime_3] }
    end

    context 'name' do
      let(:terms) { Animes::Filters::OrderBy::Field[:name] }
      it { is_expected.to eq [anime_1, anime_3, anime_2] }
    end

    context 'ranked' do
      let(:terms) { Animes::Filters::OrderBy::Field[:ranked] }
      it { is_expected.to eq [anime_2, anime_3, anime_1] }
    end

    context 'ranked_shiki' do
      let(:terms) { Animes::Filters::OrderBy::Field[:ranked_shiki] }
      it { is_expected.to eq [anime_1, anime_2, anime_3] }
    end

    context 'ranked_random' do
      let(:terms) { Animes::Filters::OrderBy::Field[:ranked_random] }
      it { is_expected.to eq [anime_2, anime_3, anime_1] }
    end

    context 'ranked,name' do
      let(:terms) do
        [
          Animes::Filters::OrderBy::Field[:ranked],
          Animes::Filters::OrderBy::Field[:name]
        ].join(',')
      end
      it { is_expected.to eq [anime_3, anime_2, anime_1] }
    end

    context 'aired_on' do
      let(:terms) { Animes::Filters::OrderBy::Field[:aired_on] }
      it { is_expected.to eq [anime_2, anime_1, anime_3] }
    end

    context 'custom surtings' do
      context 'user_1' do
        let(:terms) { Animes::Filters::OrderBy::Field[:user_1] }
        let(:scope) { Anime.order(:id) }
        it { is_expected.to eq [anime_1, anime_2, anime_3] }
      end

      context 'user_2' do
        let(:terms) { Animes::Filters::OrderBy::Field[:user_2] }
        let(:scope) { Anime.order(id: :desc) }
        it { is_expected.to eq [anime_3, anime_2, anime_1] }
      end
    end

    context 'rate_id' do
      let!(:user_rate_2) { create :user_rate, target: anime_2, user: user }
      let!(:user_rate_1) { create :user_rate, target: anime_1, user: user }
      let(:terms) { 'rate_id' }

      context 'no user_rates joined' do
        it { expect { subject }.to raise_error InvalidParameterError }
      end

      context 'has user_rates joined' do
        let(:scope) { Anime.joins :rates }
        it { is_expected.to eq [anime_2, anime_1] }
      end
    end

    context 'invalid parameter' do
      let(:terms) { 'z' }
      it { expect { subject }.to raise_error InvalidParameterError }
    end
  end

  describe '.terms_sql' do
    subject do
      described_class.terms_sql(
        terms: %i[id name],
        scope: [Anime.all, Anime].sample,
        arel_sql: false
      )
    end
    it { is_expected.to eq 'animes.id,animes.name' }
  end

  describe '.term_sql' do
    subject do
      described_class.term_sql(
        term: :id,
        scope: [Anime.all, Anime].sample,
        arel_sql: false
      )
    end
    it { is_expected.to eq 'animes.id' }
  end
end
