describe Comment do
  describe 'associations' do
    it { is_expected.to belong_to :user }
    it { is_expected.to belong_to :commentable }
    it { is_expected.to belong_to(:topic).optional }
    it { is_expected.to have_many(:messages).dependent :destroy }
    it { is_expected.to have_many :viewings }
    it { is_expected.to have_many(:abuse_requests).dependent :destroy }
    it { is_expected.to have_many :bans }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :body }
    it { is_expected.to validate_length_of(:body).is_at_most(10000) }
    it do
      is_expected
        .to validate_inclusion_of(:commentable_type)
        .in_array Types::Comment::CommentableType.values
    end
  end

  describe 'callbacks' do
    let(:topic) { seed :offtopic_topic }
    let(:comment) { create :comment, user: user, commentable: topic }

    describe '#forbid_tags_change' do
      let!(:comment) { create :comment }
      before { allow(Comments::ForbidTagChange).to receive :call }
      subject! do
        if is_conversion
          comment.instance_variable_set :@is_conversion, true
        end
        comment.update body: 'test zxc'
      end

      context 'no migration' do
        let(:is_conversion) { false }
        it do
          expect(Comments::ForbidTagChange).to have_received(:call).twice
          expect(Comments::ForbidTagChange)
            .to have_received(:call)
            .with(
              model: comment,
              field: :body,
              tag_regexp: /(\[ban=\d+\])/,
              tag_error_label: '[ban]'
            )
          expect(Comments::ForbidTagChange)
            .to have_received(:call)
            .with(
              model: comment,
              field: :body,
              tag_regexp: /(\[broadcast\])/,
              tag_error_label: '[broadcast]'
            )
        end
      end

      context 'migration' do
        let(:is_conversion) { true }
        it { expect(Comments::ForbidTagChange).to_not have_received :call }
      end
    end

    describe '#check_access' do
      let(:comment) { build :comment }
      after { comment.save }
      it { expect(comment).to receive :check_access }
    end

    describe '#check_spam_abuse' do
      before do
        allow(Users::CheckHacked).to receive(:call).and_return true
      end
      context 'profile comment' do
        let!(:comment) { create :comment, commentable: user }

        it do
          expect(Users::CheckHacked)
            .to have_received(:call)
            .with(
              model: comment,
              user: comment.user,
              text: comment.body
            )
        end
      end

      context 'not profile comment' do
        let!(:comment) { create :comment }
        it { expect(Users::CheckHacked).to_not have_received :call }
      end
    end

    describe '#increment_comments' do
      let(:comment) { build :comment }
      after { comment.save }
      it { expect(comment).to receive :increment_comments }
    end

    describe '#decrement_comments' do
      let(:comment) { create :comment }
      after { comment.destroy }
      it { expect(comment).to receive :decrement_comments }
    end

    describe '#sync_comments' do
      let(:topic_2) { site_rules_topic }
      let!(:comment) do
        create :comment,
          :with_increment_comments,
          :with_sync_comments,
          :with_decrement_comments,
          commentable: topic
      end

      it do
        expect(topic.comments_count).to eq 1
        expect(topic_2.comments_count).to eq 0
        comment.update! commentable: topic_2
        expect(topic.reload.comments_count).to eq 0
        expect(topic_2.reload.comments_count).to eq 1
      end
    end

    describe '#notify_quoted' do
      describe 'after_save' do
        context 'body changed' do
          let(:comment) { build :comment }
          after { comment.save }
          it { expect(comment).to receive :notify_quoted }
        end

        context 'body not changed' do
          let(:comment) { create :comment }
          after { comment.update is_offtopic: true }
          it { expect(comment).to_not receive :notify_quoted }
        end
      end
    end

    describe '#remove_notifies' do
      describe 'after_destroy' do
        let(:comment) { create :comment }
        after { comment.destroy }
        it { expect(comment).to receive :remove_notifies }
      end
    end

    describe '#destroy_images' do
      let(:comment) { create :comment }
      before { allow(Comment::Cleanup).to receive :call }
      subject! { comment.destroy! }
      it do
        expect(Comment::Cleanup)
          .to have_received(:call)
          .with(comment, skip_model_update: true)
      end
    end

    describe '#release_the_banhammer!' do
      let(:comment) { build :comment, :with_banhammer }
      after { comment.save }
      it { expect(Moderations::Banhammer.instance).to receive :release! }
    end

    describe '#touch_commentable' do
      include_context :timecop

      let(:topic) { create :topic }
      let(:comment) { build :comment, :with_touch_commentable, topic: topic }

      context 'create' do
        subject! { comment.save! }

        context 'commentable with commented_at' do
          it { expect(topic.commented_at).to eq Time.zone.now }
        end

        context 'commentable without updated_at' do
          let(:comment) { build :comment, :with_touch_commentable, commentable: user }
          let(:user) { create :user, updated_at: 1.day.ago }
          it { expect(topic.updated_at).to eq Time.zone.now }
        end
      end

      context 'update' do
        before { comment.save! }
        before { topic.update commented_at: nil }
        subject! { comment.update! body: 'zxcvbn' }

        it { expect(topic.commented_at).to eq Time.zone.now }
      end

      context 'destroy' do
        before { comment.save! }
        before { topic.update commented_at: nil }
        subject! { comment.destroy! }

        it { expect(topic.commented_at).to eq Time.zone.now }
      end
    end
  end

  describe 'instance methods' do
    let(:topic) { seed :offtopic_topic }
    let(:comment) { create :comment, user: user, commentable: topic }

    describe '#html_body' do
      let(:comment) { build :comment, body: body }
      let(:body) { '[b]bold[/b]' }

      it { expect(comment.html_body).to eq '<strong>bold</strong>' }

      describe 'comment in offtopic topic' do
        let(:offtopic_topic) { seed :offtopic_topic }
        let(:comment) do
          create :comment, body: body, commentable: offtopic_topic
        end

        describe 'poster' do
          let(:body) { '[poster]http:///test.com[/poster]' }
          it { expect(comment.html_body).to_not include 'b-poster' }
        end

        describe 'img' do
          let(:body) { '[img w=747 h=1047]http:///test.com[/img]' }
          it { expect(comment.html_body).to_not include 'width=' }
          it { expect(comment.html_body).to_not include 'height=' }
        end

        describe 'image' do
          let!(:user_image) { create :user_image }
          before do
            allow(BbCodes::Text)
              .to receive(:call)
              .with(final_bbcode, object: comment)
              .and_return final_bbcode
          end

          let(:final_bbcode) { "[image=#{user_image.id}]" }
          let(:body) { "[image=#{user_image.id} 9999x9999]" }

          it { expect(comment.html_body).to eq final_bbcode }
        end
      end
    end

    describe '#notify_quoted' do
      before { allow(Comments::NotifyQuoted).to receive :call }
      let!(:comment) { create :comment, :with_notify_quoted }
      it do
        expect(Comments::NotifyQuoted).to have_received(:call).with(
          old_body: nil,
          new_body: comment.body,
          comment: comment,
          user: comment.user
        )
      end
    end

    describe '#remove_notifies' do
      let!(:comment) { create :comment }
      before { allow(Comments::NotifyQuoted).to receive :call }
      before { comment.destroy }
      it do
        expect(Comments::NotifyQuoted).to have_received(:call).with(
          old_body: comment.body,
          new_body: nil,
          comment: comment,
          user: comment.user
        )
      end
    end

    describe '#forbid_tags_change' do
      let(:comment) { create :comment, body: old_body }
      subject! { comment.update body: new_body }

      let(:old_body) { 'zxc' }

      context 'no forbidden tags' do
        let(:new_body) { old_body }
        it { expect(comment).to be_valid }
      end

      context '[ban]' do
        let(:new_body) { '[ban=1]' }
        it do
          expect(comment.errors.messages[:body]).to have(1).item
        end
      end

      context '[broadcast]' do
        let(:new_body) { '[broadcast]' }
        it do
          expect(comment.errors.messages[:body]).to have(1).item
        end
      end
    end

    describe '#mark_offtopic' do
      let!(:comment) { create :comment, is_offtopic: offtopic }
      let!(:inner_comment) do
        create :comment,
          body: "[comment=#{comment.id}]",
          is_offtopic: offtopic
      end

      before { comment.mark_offtopic flag }

      context 'mark offtopic' do
        let(:offtopic) { false }
        let(:flag) { true }

        it { expect(comment.reload).to be_offtopic }
        it { expect(inner_comment.reload).to be_offtopic }
      end

      context 'mark not offtopic' do
        let(:offtopic) { true }
        let(:flag) { false }

        it { expect(comment.reload).to_not be_offtopic }
        it { expect(inner_comment.reload).to be_offtopic }
      end
    end

    describe '#moderatable?' do
      subject { build :comment, commentable: commentable }
      let(:commentable) { nil }

      it { is_expected.to_not be_moderatable }

      context 'profile comment' do
        let(:commentable) { user }
        it { is_expected.to be_moderatable }
      end

      context 'topic comment' do
        let(:commentable) { build :topic, linked: linked }
        let(:linked) { nil }

        it { is_expected.to be_moderatable }

        context 'critique comment' do
          let(:linked) { build :critique }
          it { is_expected.to be_moderatable }
        end

        context 'contest comment' do
          let(:linked) { build :contest }
          it { is_expected.to be_moderatable }
        end

        context 'collection comment' do
          let(:linked) { build :collection }
          it { is_expected.to be_moderatable }
        end

        context 'anime comment' do
          let(:linked) { build :anime }
          it { is_expected.to be_moderatable }
        end

        context 'club comment' do
          let(:linked) { build :club }
          it { is_expected.to be_moderatable }
        end

        context 'club_page comment' do
          let(:linked) { build :club_page }
          it { is_expected.to be_moderatable }
        end
      end
    end

    describe '#strict_moderatable?' do
      subject { build :comment, commentable: commentable }
      let(:commentable) { nil }

      it { is_expected.to_not be_strict_moderatable }

      context 'profile comment' do
        let(:commentable) { user }
        it { is_expected.to_not be_strict_moderatable }
      end

      context 'topic comment' do
        let(:commentable) { build :topic, linked: linked }
        let(:linked) { nil }

        it { is_expected.to be_strict_moderatable }

        context 'critique comment' do
          let(:linked) { build :critique }
          it { is_expected.to be_strict_moderatable }
        end

        context 'contest comment' do
          let(:linked) { build :contest }
          it { is_expected.to be_strict_moderatable }
        end

        context 'collection comment' do
          let(:linked) { build :collection }
          it { is_expected.to be_strict_moderatable }
        end

        context 'anime comment' do
          let(:linked) { build :anime }
          it { is_expected.to be_strict_moderatable }
        end

        context 'club comment' do
          let(:linked) { build :club }
          it { is_expected.to_not be_strict_moderatable }
        end

        context 'club_page comment' do
          let(:linked) { build :club_page }
          it { is_expected.to_not be_strict_moderatable }
        end
      end
    end

    describe '#from_user_profile?' do
      subject { build :comment, commentable: commentable }
      let(:commentable) { nil }

      it { is_expected.to_not be_from_user_profile }

      context 'profile comment' do
        let(:commentable) { user }
        it { is_expected.to be_from_user_profile }
      end

      context 'topic comment' do
        let(:commentable) { build :topic, linked: linked }
        let(:linked) { nil }

        it { is_expected.to_not be_from_user_profile }

        context 'critique comment' do
          let(:linked) { build :critique }
          it { is_expected.to_not be_from_user_profile }
        end

        context 'contest comment' do
          let(:linked) { build :contest }
          it { is_expected.to_not be_from_user_profile }
        end

        context 'collection comment' do
          let(:linked) { build :collection }
          it { is_expected.to_not be_from_user_profile }
        end

        context 'anime comment' do
          let(:linked) { build :anime }
          it { is_expected.to_not be_from_user_profile }
        end

        context 'club comment' do
          let(:linked) { build :club }
          it { is_expected.to_not be_from_user_profile }
        end

        context 'club_page comment' do
          let(:linked) { build :club_page }
          it { is_expected.to_not be_from_user_profile }
        end
      end
    end

    describe '#from_club?' do
      subject { build :comment, commentable: commentable }
      let(:commentable) { nil }

      it { is_expected.to_not be_from_club }

      context 'profile comment' do
        let(:commentable) { user }
        it { is_expected.to_not be_from_club }
      end

      context 'topic comment' do
        let(:commentable) { build :topic, linked: linked }
        let(:linked) { nil }

        it { is_expected.to_not be_from_club }

        context 'critique comment' do
          let(:linked) { build :critique }
          it { is_expected.to_not be_from_club }
        end

        context 'contest comment' do
          let(:linked) { build :contest }
          it { is_expected.to_not be_from_club }
        end

        context 'collection comment' do
          let(:linked) { build :collection }
          it { is_expected.to_not be_from_club }
        end

        context 'anime comment' do
          let(:linked) { build :anime }
          it { is_expected.to_not be_from_club }
        end

        context 'club comment' do
          let(:linked) { build :club }
          it { is_expected.to be_from_club }
        end

        context 'club_page comment' do
          let(:linked) { build :club_page }
          it { is_expected.to be_from_club }
        end
      end
    end

    describe '#allowed_summary?' do
      let(:comment) { build :comment, commentable: commentable }

      context 'Topic commentable' do
        let(:commentable) { build :topic }
        it { expect(comment).to_not be_allowed_summary }
      end

      context 'Topics::EntryTopics::AnimeTopic commentable' do
        let(:commentable) { build :anime_topic }
        it { expect(comment).to be_allowed_summary }
      end

      context 'Topics::EntryTopics::MangaTopic commentable' do
        let(:commentable) { build :manga_topic }
        it { expect(comment).to be_allowed_summary }
      end

      context 'Topics::EntryTopics::RanobeTopic commentable' do
        let(:commentable) { build :ranobe_topic }
        it { expect(comment).to be_allowed_summary }
      end
    end

    describe '#faye_channels' do
      it { expect(comment.faye_channels).to eq %W[/comment-#{comment.id}] }
    end
  end

  describe 'permissions' do
    subject { Ability.new user }

    context 'guest' do
      let(:user) { nil }
      let(:comment) { build_stubbed :comment }

      it { is_expected.to_not be_able_to :new, comment }
      it { is_expected.to_not be_able_to :create, comment }
      it { is_expected.to_not be_able_to :update, comment }
      it { is_expected.to_not be_able_to :destroy, comment }
    end

    context 'not comment owner' do
      let(:user) { build_stubbed :user, :user, :day_registered }
      let(:user_2) { build_stubbed :user, :user, :day_registered }
      let(:comment) { build_stubbed :comment, user: user_2 }

      it { is_expected.to_not be_able_to :new, comment }
      it { is_expected.to_not be_able_to :create, comment }
      it { is_expected.to_not be_able_to :update, comment }
      it { is_expected.to_not be_able_to :destroy, comment }

      context 'comment in own profile' do
        let(:comment) do
          build_stubbed :comment,
            user: user_2,
            commentable: user,
            created_at: 1.week.ago
        end

        it { is_expected.to_not be_able_to :update, comment }
        it { is_expected.to be_able_to :destroy, comment }
      end
    end

    context 'comment owner' do
      let(:user) { build_stubbed :user, :user, :day_registered }
      let(:comment) { build_stubbed :comment, user: user }

      it { is_expected.to be_able_to :new, comment }
      it { is_expected.to be_able_to :create, comment }
      it { is_expected.to be_able_to :update, comment }

      context 'user is registered < 1 day ago' do
        let(:user) { build_stubbed :user, :user }

        it { is_expected.to_not be_able_to :new, comment }
        it { is_expected.to_not be_able_to :create, comment }
        it { is_expected.to_not be_able_to :update, comment }

        context 'comment in own profile' do
          let(:comment) { build_stubbed :comment, user: user, commentable: user }

          it { is_expected.to_not be_able_to :update, comment }
          it { is_expected.to_not be_able_to :destroy, comment }
        end
      end

      context 'banned user' do
        let(:user) { build_stubbed :user, :banned, :day_registered }

        it { is_expected.to_not be_able_to :new, comment }
        it { is_expected.to_not be_able_to :create, comment }
        it { is_expected.to_not be_able_to :update, comment }
      end

      describe 'permissions based on comment creation date' do
        let(:comment) { build_stubbed :comment, user: user, created_at: created_at }

        context 'comment created < 1.day hours ago' do
          let(:created_at) { 1.day.ago + 1.minute }
          it { is_expected.to be_able_to :destroy, comment }
        end

        context 'comment created >= 1.day hours ago' do
          let(:created_at) { 1.day.ago - 1.minute }
          it { is_expected.to_not be_able_to :destroy, comment }
        end
      end
    end

    context 'forum moderator' do
      let(:user) { build_stubbed :user, :forum_moderator }
      let(:comment) { build_stubbed :comment, user: build_stubbed(:user) }
      it { is_expected.to be_able_to :manage, comment }
    end

    describe 'club comment' do
      let(:comment) do
        build_stubbed :comment,
          user: comment_owner,
          commentable: club_topic,
          created_at: 1.month.ago
      end
      let(:comment_owner) { build_stubbed :user }
      let(:club_topic) { build_stubbed :club_topic, linked: club }
      let(:club) { build_stubbed :club }

      context 'common user' do
        let(:user) { build_stubbed :user, :user }
        it { is_expected.to_not be_able_to :update, comment }
        it { is_expected.to_not be_able_to :destroy, comment }
        it { is_expected.to_not be_able_to :broadcast, comment }
      end

      context 'club member' do
        let(:user) { build_stubbed :user, :user, club_roles: [club_member_role] }
        let(:club_member_role) { build_stubbed :club_role, :member, club: club }

        it { is_expected.to_not be_able_to :destroy, comment }
        it { is_expected.to_not be_able_to :broadcast, comment }
        it { is_expected.to_not be_able_to :update, comment }
      end

      context 'club admin' do
        let(:user) do
          build_stubbed :user, :user, :day_registered,
            club_admin_roles: [club_admin_role]
        end
        let(:club_admin_role) { build_stubbed :club_role, :admin, club: club }

        it { is_expected.to be_able_to :destroy, comment }
        it { is_expected.to be_able_to :broadcast, comment }

        context "another user's comment" do
          it { is_expected.to_not be_able_to :update, comment }
        end

        context 'own comment' do
          let(:comment_owner) { user }
          it { is_expected.to be_able_to :update, comment }
        end
      end
    end
  end

  it_behaves_like :antispam_concern, :comment
end
