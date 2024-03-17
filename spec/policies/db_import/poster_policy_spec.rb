describe DbImport::PosterPolicy do
  let(:policy) { described_class.new entry:, image_url: }
  subject { policy.need_import? }

  let(:poster) { build_stubbed :poster, mal_url:, created_at: downloaded_at }
  let(:mal_url) { nil }
  let(:downloaded_at) { described_class::OLD_INTERVAL.ago - 1.day }

  before do
    if poster
      allow(poster)
        .to receive_message_chain(:image, :id)
        .and_return 123
      allow(poster)
        .to receive_message_chain(:image, :storage, :path)
        .with(123)
        .and_return existing_poster_path
      allow(ImageChecker)
        .to receive(:valid?)
        .with(existing_poster_path)
        .and_return is_valid
    end
  end
  let(:is_valid) { true }
  let(:existing_poster_path) { '/tmp/zxc' }

  context 'anime' do
    let(:entry) { build_stubbed :anime, poster:, desynced: }
    let(:desynced) { [] }
    let(:image_url) { 'http://zxc.vbn' }

    it { is_expected.to eq true }

    describe '#invalid_entry?' do
      context 'new record' do
        before { allow(entry).to receive(:new_record?).and_return true }
        it { is_expected.to eq false }
      end

      context 'new record' do
        before { allow(entry).to receive(:valid?).and_return false }
        it { is_expected.to eq false }
      end
    end

    describe '#bad_image?' do
      describe 'has image url' do
        it { is_expected.to eq true }

        context 'na_series.gif' do
          let(:image_url) { 'http://zxc.vbn/na_series.gif' }
          it { is_expected.to eq false }
        end

        context 'na.gif' do
          let(:image_url) { 'http://zxc.vbn/na.gif' }
          it { is_expected.to eq false }
        end
      end

      context 'no image_url' do
        let(:image_url) { ['', nil].sample }
        it { is_expected.to eq false }
      end
    end

    describe '#desynced_poster?' do
      context 'desynced' do
        let(:desynced) { [%w[poster], %w[image]].sample }
        it { is_expected.to eq false }
      end
    end

    describe '#poster_expired?' do
      context 'no existing poster' do
        let(:poster) { nil }
        it { is_expected.to eq true }
      end

      context 'has existing poster' do
        context 'expired' do
          let(:mal_url) { ['zxc', '', nil, image_url + 'z'].sample }
          it { is_expected.to eq true }
        end

        context 'not expired' do
          let(:mal_url) { image_url }
          it { is_expected.to eq false }
        end
        # context 'ongoing' do
        #   let(:entry) { build_stubbed :anime, poster: poster, status: :ongoing }
        #
        #   context 'expired' do
        #     let(:downloaded_at) { DbImport::ImagePolicy::ONGOING_INTERVAL.ago - 1.day }
        #     it { is_expected.to eq true }
        #   end
        #
        #   context 'not expired' do
        #     let(:downloaded_at) { DbImport::ImagePolicy::ONGOING_INTERVAL.ago + 1.day }
        #     it { is_expected.to eq false }
        #   end
        # end
        #
        # context 'latest' do
        #   let(:entry) do
        #     build_stubbed :anime, poster: poster, status: :released, aired_on: 1.month.ago
        #   end
        #
        #   context 'expired' do
        #     let(:downloaded_at) { DbImport::ImagePolicy::LATEST_INTERVAL.ago - 1.day }
        #     it { is_expected.to eq true }
        #   end
        #
        #   context 'not expired' do
        #     let(:downloaded_at) { DbImport::ImagePolicy::LATEST_INTERVAL.ago + 1.day }
        #     it { is_expected.to eq false }
        #   end
        # end
        #
        # context 'old anime' do
        #   context 'expired' do
        #     let(:downloaded_at) { DbImport::ImagePolicy::OLD_INTERVAL.ago - 1.day }
        #     it { is_expected.to eq true }
        #   end
        #
        #   context 'not expired' do
        #     let(:downloaded_at) { DbImport::ImagePolicy::OLD_INTERVAL.ago + 1.day }
        #     it { is_expected.to eq false }
        #   end
        # end
      end
    end
  end

  context 'character' do
    let(:entry) { build_stubbed :character, poster: }
    let(:image_url) { 'http://zxc.vbn' }

    before do
      allow(entry)
        .to receive_message_chain(:animes, :where, :any?)
        .and_return is_ongoing
    end
    let(:is_ongoing) { [true, false].sample }

    it { is_expected.to eq true }

    # describe '#poster_expired?' do
    #   context 'no existing poster' do
    #     let(:poster) { nil }
    #     it { is_expected.to eq true }
    #   end
    #
    #   context 'has existing poster' do
    #     context 'ongoing' do
    #       let(:is_ongoing) { true }
    #
    #       context 'expired' do
    #         let(:downloaded_at) { DbImport::ImagePolicy::ONGOING_INTERVAL.ago - 1.day }
    #         it { is_expected.to eq true }
    #       end
    #
    #       context 'not expired' do
    #         let(:downloaded_at) { DbImport::ImagePolicy::ONGOING_INTERVAL.ago + 1.day }
    #         it { is_expected.to eq false }
    #       end
    #     end
    #
    #     context 'not ongoing' do
    #       let!(:is_ongoing) { false }
    #
    #       context 'expired' do
    #         let(:downloaded_at) { DbImport::ImagePolicy::OLD_INTERVAL.ago - 1.day }
    #         it { is_expected.to eq true }
    #       end
    #
    #       context 'not expired' do
    #         let(:downloaded_at) { DbImport::ImagePolicy::OLD_INTERVAL.ago + 1.day }
    #         it { is_expected.to eq false }
    #       end
    #     end
    #   end
    # end
  end
end
