describe Genre do
  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(4096) }
  end

  describe 'enumerize' do
    it { is_expected.to enumerize(:entry_type).in(*Types::Genre::EntryType.values) }
    it { is_expected.to enumerize(:kind).in(*Types::Genre::Kind.values) }
  end

  describe 'instance methods' do
    describe '#anime?, #manga?' do
      before { subject.entry_type = entry_type }

      context 'Anime' do
        let(:entry_type) { Types::Genre::EntryType['Anime'] }

        its(:anime?) { is_expected.to eq true }
        its(:manga?) { is_expected.to eq false }
      end

      context 'Manga' do
        let(:entry_type) { Types::Genre::EntryType['Manga'] }

        its(:anime?) { is_expected.to eq false }
        its(:manga?) { is_expected.to eq true }
      end
    end

    describe '#title' do
      subject { genre.title ru_case: ru_case, user: user }

      let(:ru_case) { :subjective }
      let(:user) { nil }

      let(:genre) { build :genre, name: name, entry_type: entry_type }
      let(:entry_type) { Types::Genre::EntryType['Anime'] }
      let(:name) { 'Romance' }

      context 'Anime' do
        let(:entry_type) { Types::Genre::EntryType['Anime'] }

        context 'Magic' do
          let(:name) { 'Magic' }
          it { is_expected.to eq 'Аниме про магию' }
        end

        context 'Shounen' do
          let(:name) { 'Shounen' }
          it { is_expected.to eq 'Сёнен аниме' }
        end

        context 'Romance' do
          let(:name) { 'Romance' }
          it { is_expected.to eq 'Романтические аниме про любовь' }
        end
      end

      context 'Manga' do
        let(:entry_type) { Types::Genre::EntryType['Manga'] }

        context 'Magic' do
          let(:name) { 'Magic' }
          it { is_expected.to eq 'Манга про магию' }
        end

        context 'Shounen' do
          let(:name) { 'Shounen' }
          it { is_expected.to eq 'Сёнен манга' }
        end

        context 'Romance' do
          let(:name) { 'Romance' }
          it { is_expected.to eq 'Романтическая манга про любовь' }
        end
      end

      context 'genitive case' do
        let(:ru_case) { :genitive }
        it { is_expected.to eq 'Романтических аниме про любовь' }
      end

      context 'default title' do
        let(:genre) { build :genre, name: name, entry_type: entry_type, russian: 'Безумие' }
        let(:name) { 'Dementia' }

        it { is_expected.to eq 'Аниме жанра безумие' }
      end
    end
  end

  describe 'permissions' do
    let(:genre) { build_stubbed :genre }
    let(:user) { build_stubbed :user, :user }
    subject { Ability.new user }

    context 'super_moderator' do
      let(:user) { build_stubbed :user, :super_moderator }

      it { is_expected.to be_able_to :read, genre }
      it { is_expected.to be_able_to :tooltip, genre }
      it { is_expected.to be_able_to :edit, genre }
      it { is_expected.to be_able_to :update, genre }
    end

    context 'forum_moderator' do
      let(:user) { build_stubbed :user, :forum_moderator }

      it { is_expected.to be_able_to :read, genre }
      it { is_expected.to be_able_to :tooltip, genre }
      it { is_expected.to be_able_to :edit, genre }
      it { is_expected.to_not be_able_to :update, genre }
    end

    context 'user' do
      it { is_expected.to be_able_to :read, genre }
      it { is_expected.to be_able_to :tooltip, genre }
      it { is_expected.to be_able_to :edit, genre }
      it { is_expected.to_not be_able_to :update, genre }
    end

    context 'guest' do
      let(:user) { nil }

      it { is_expected.to be_able_to :read, genre }
      it { is_expected.to be_able_to :tooltip, genre }
      it { is_expected.to_not be_able_to :edit, genre }
      it { is_expected.to_not be_able_to :update, genre }
    end
  end
end
