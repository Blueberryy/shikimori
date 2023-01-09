# frozen_string_literal: true

describe Critique::Create do
  subject(:critique) { Critique::Create.call params }

  let(:anime) { create :anime, is_censored: is_censored }
  let(:is_censored) { [true, false].sample }
  let(:params) do
    {
      user_id: user.id,
      target_type: anime.class.name,
      target_id: anime.id,
      text: 'x' * Critique::MIN_BODY_SIZE,
      storyline: 1,
      characters: 2,
      animation: 3,
      music: 4,
      overall: 5
    }
  end

  context 'valid params' do
    it do
      expect(critique).to be_persisted
      expect(critique.errors).to be_empty

      expect(critique.topic).to be_present
      expect(critique.topic.is_censored).to eq is_censored
    end
  end

  context 'invalid params' do
    let(:params) do
      {
        user_id: user.id,
        text: 'x' * Critique::MIN_BODY_SIZE,
        storyline: 1,
        characters: 2,
        animation: 3,
        music: 4,
        overall: 5
      }
    end
    it do
      expect(critique).to be_new_record
      expect(critique.errors).to be_present
      expect(critique.topic).to_not be_present
    end
  end

  describe 'auto-accept' do
    context 'critique_moderator' do
      let(:user) { create :user, :critique_moderator }

      it do
        expect(critique).to be_persisted
        expect(critique).to have_attributes(
          approver: user,
          moderation_state: 'accepted'
        )
      end
    end

    context 'not critique_moderator' do
      it do
        expect(critique).to be_persisted
        expect(critique).to have_attributes(
          approver: nil,
          moderation_state: 'pending'
        )
      end
    end
  end
end
