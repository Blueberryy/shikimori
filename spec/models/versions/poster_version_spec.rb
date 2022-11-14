describe Versions::PosterVersion do
  describe '#action' do
    let(:version) { build :poster_version, item_diff: { action: 'upload' } }
    it { expect(version.action).to eq Versions::PosterVersion::Actions[:upload] }
  end

  describe '#apply_changes' do
    include_context :timecop

    let(:poster) { create :poster, is_approved: false, anime: anime }
    let!(:active_poster) { nil }
    let(:anime) { create :anime }

    subject! { version.apply_changes }

    context 'upload' do
      let(:version) do
        create :poster_version,
          item: poster,
          item_diff: { 'action' => 'upload' },
          associated: anime
      end

      context 'no active poster' do
        it { expect(poster.reload).to be_is_approved }
      end

      context 'has active poster' do
        let!(:active_poster) { create :poster, is_approved: true, anime: anime }
        it do
          expect(poster.reload).to be_is_approved
          expect(active_poster.reload.deleted_at).to be_within(0.1).of Time.zone.now
          expect(version.reload.item_diff).to eq(
            'action' => 'upload',
            'prev_poster_id' => active_poster.id
          )
        end
      end
    end

    context 'delete' do
      pending
    end
  end

  describe '#rollback_changes' do
    subject! { version.rollback_changes }

    context 'upload' do
      pending
    end

    context 'delete' do
      pending
    end
  end

  describe '#sweep_deleted' do
    subject! { version.sweep_deleted }
    pending
  end
end
