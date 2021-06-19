describe Summary do
  describe 'associations' do
    it { is_expected.to belong_to :user }
    it { is_expected.to belong_to(:anime).optional }
    it { is_expected.to belong_to(:manga).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :body }
    # it { is_expected.to validate_presence_of :anime }
    # it { is_expected.to validate_presence_of :manga }
  end

  describe 'enumerize' do
    it do
      is_expected
        .to enumerize(:tone)
        .in(*Types::Summary::Tone.values)
    end
  end

  describe 'instance methods' do
    describe '#html_body' do
      subject { build :summary, body: body }
      let(:body) { '[b]zxc[/b]' }
      its(:html_body) { is_expected.to eq '<strong>zxc</strong>' }
    end
  end

  describe 'permissions' do
    subject { Ability.new user }

    context 'guest' do
      let(:user) { nil }
      let(:summary) { build_stubbed :summary }

      it { is_expected.to_not be_able_to :new, summary }
      it { is_expected.to_not be_able_to :create, summary }
      it { is_expected.to_not be_able_to :update, summary }
      it { is_expected.to_not be_able_to :destroy, summary }
    end

    context 'not summary owner' do
      let(:user) { build_stubbed :user, :user, :day_registered }
      let(:user_2) { build_stubbed :user, :user, :day_registered }
      let(:summary) { build_stubbed :summary, user: user_2 }

      it { is_expected.to_not be_able_to :new, summary }
      it { is_expected.to_not be_able_to :create, summary }
      it { is_expected.to_not be_able_to :update, summary }
      it { is_expected.to_not be_able_to :destroy, summary }
    end

    context 'summary owner' do
      let(:user) { build_stubbed :user, :user, :day_registered }
      let(:summary) { build_stubbed :summary, user: user }

      it { is_expected.to be_able_to :new, summary }
      it { is_expected.to be_able_to :create, summary }
      it { is_expected.to be_able_to :update, summary }

      context 'user is registered < 1 day ago' do
        let(:user) { build_stubbed :user, :user }

        it { is_expected.to_not be_able_to :new, summary }
        it { is_expected.to_not be_able_to :create, summary }
        it { is_expected.to_not be_able_to :update, summary }
      end

      context 'banned user' do
        let(:user) { build_stubbed :user, :banned, :day_registered }

        it { is_expected.to_not be_able_to :new, summary }
        it { is_expected.to_not be_able_to :create, summary }
        it { is_expected.to_not be_able_to :update, summary }
      end
    end

    context 'forum moderator' do
      let(:user) { build_stubbed :user, :forum_moderator }
      let(:summary) { build_stubbed :summary, user: build_stubbed(:user) }
      it { is_expected.to be_able_to :manage, summary }
    end
  end

  it_behaves_like :antispam_concern, :summary
end
