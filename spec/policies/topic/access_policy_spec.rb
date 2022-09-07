describe Topic::AccessPolicy do
  subject { described_class.allowed? topic, decorated_user }

  let(:decorated_user) { [user.decorate, nil].sample }
  before do
    allow(Club::AccessPolicy)
      .to receive(:allowed?)
      .with(club, decorated_user)
      .and_return is_allowed
  end
  let(:club) { build_stubbed :club }
  let(:club_page) { build_stubbed :club_page, club: club }

  let(:is_allowed) { [true, false].sample }

  context 'no linked club' do
    let(:topic) { build_stubbed :topic }
    it { is_expected.to eq true }
  end

  context 'linked club' do
    context 'Topics::EntryTopics::ClubTopic' do
      let(:topic) { build_stubbed :club_topic, linked: club }
      it { is_expected.to eq is_allowed }
    end

    context 'Topics::EntryTopics::ClubPageTopic' do
      let(:topic) { build_stubbed :club_page_topic, linked: club_page }
      it { is_expected.to eq is_allowed }
    end

    context 'Topics::ClubUserTopic' do
      let(:topic) { build_stubbed :club_user_topic, linked: club }
      it { is_expected.to eq is_allowed }
    end
  end
end
