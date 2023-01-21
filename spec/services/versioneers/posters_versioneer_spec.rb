describe Versioneers::PostersVersioneer do
  let(:service) { described_class.new anime }
  let(:anime) { create :anime }
  let(:author) { build_stubbed :user, role }
  let(:role) { :user }
  let(:reason) { 'change reason' }

  let(:params) do
    {
      poster_id: poster_id,
      poster_data_uri: poster_data_uri,
      poster_crop_data: poster_crop_data.to_json
    }
  end
  let(:poster_crop_data) do
    {
      'left' => 0,
      'top' => 0,
      'width' => 1,
      'height' => 1
    }
  end

  describe '#premoderate' do
    subject(:version) { service.premoderate params, author, reason }

    context 'upload' do
      context 'new poster' do
        let(:poster_id) { '' }
        let(:poster_data_uri) do
          attributes_for(:poster, :image_data_uri)[:image_data_uri]
        end

        it do
          expect { subject }.to change(Poster, :count).by(1)

          expect(version).to be_persisted
          expect(version).to_not be_changed
          expect(version).to be_pending
          expect(version).to be_instance_of Versions::PosterVersion
          expect(version).to have_attributes(
            user: author,
            reason: reason,
            item_diff: { 'action' => 'upload' },
            associated: anime,
            moderator: nil
          )
          expect(version.item).to be_kind_of Poster
          expect(version.item).to be_persisted
          expect(version.item).to_not be_changed
          expect(version.item).to have_attributes(
            anime_id: anime.id,
            manga_id: nil,
            character_id: nil,
            person_id: nil,
            crop_data: poster_crop_data,
            is_approved: false
          )
        end
      end

      context 'update existing' do
        let!(:poster) do
          create :poster, :image_data_file,
            anime: anime,
            mal_url: mal_url
        end
        let(:poster_id) { poster.id }
        let(:poster_data_uri) { '' }
        let(:mal_url) { 'https://test.com/image.jpg' }

        it do
          expect { subject }.to change(Poster, :count).by(1)

          expect(version).to be_persisted
          expect(version).to_not be_changed
          expect(version).to be_pending
          expect(version).to be_instance_of Versions::PosterVersion
          expect(version).to have_attributes(
            user: author,
            reason: reason,
            item_diff: { 'action' => 'upload' },
            associated: anime,
            moderator: nil
          )
          expect(version.item).to be_kind_of Poster
          expect(version.item).to be_persisted
          expect(version.item).to_not be_changed
          expect(version.item).to have_attributes(
            anime_id: anime.id,
            manga_id: nil,
            character_id: nil,
            person_id: nil,
            crop_data: poster_crop_data,
            is_approved: false,
            mal_url: mal_url
          )
        end
      end
    end

    context 'delete' do
      let(:poster_id) { '' }
      let(:poster_data_uri) { '' }

      context 'anime has poster' do
        let!(:poster) { create :poster, anime: anime }

        it do
          expect { subject }.to_not change Poster, :count

          expect(version).to be_persisted
          expect(version).to_not be_changed
          expect(version).to be_pending
          expect(version).to be_instance_of Versions::PosterVersion
          expect(version).to have_attributes(
            user: author,
            reason: reason,
            item: poster,
            item_diff: { 'action' => 'delete' },
            associated: anime,
            moderator: nil
          )
        end
      end

      context 'anime has no poster' do
        it do
          expect { subject }.to_not change Poster, :count
          expect(version).to be_new_record
        end
      end
    end
  end
end
