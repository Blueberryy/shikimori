describe CommentsController, type: :controller do
  let!(:comment) { create :comment, commentable: commentable, user: user_2 }

  subject do
    get :show, params: { id: comment.id }
  end

  context 'regular comment' do
    let(:commentable) { create :topic }

    context 'guest' do
      include_examples :has_access
    end

    context 'user' do
      include_context :authenticated, :user
      include_examples :has_access
    end
  end

  context 'club comment' do
    let(:commentable) { create :club_topic, linked: club }
    include_context :club_access_check, true
  end

  context 'club_page comment' do
    let(:commentable) { create :club_page_topic, linked: club_page }
    let(:club_page) { create :club_page, club: club }
    include_context :club_access_check, true
  end
end
