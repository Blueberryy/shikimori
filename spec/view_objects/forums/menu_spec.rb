describe Forums::Menu do
  include_context :view_context_stub

  let(:view) { Forums::Menu.new double(id: 1), nil }

  describe '#club_topics' do
    let!(:club_topic) { create :club_topic, linked: create(:club) }

    it { expect(view.club_topics).to eq [club_topic] }
  end

  describe '#changeable_forums?' do
    it { expect(view.changeable_forums?).to eq false }
  end

  describe '#forums' do
    it { expect(view.forums).to be_kind_of Forums::List }
  end

  describe '#critiques' do
    let(:user_en) { build_stubbed :user }

    let!(:critique) { create :critique }

    it { expect(view.critiques).to eq [critique] }
  end

  describe '#sticky_topics' do
    it { expect(view.sticky_topics).to have(6).items }
  end

  describe '#new_topic_url' do
    it { expect(view.new_topic_url).to be_present }
  end
end
