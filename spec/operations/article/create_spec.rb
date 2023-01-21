# frozen_string_literal: true

describe Article::Create do
  subject(:model) { described_class.call params }

  let(:params) do
    {
      name: 'Test Article Name',
      user_id: user.id,
      body: 'Test Article Text'
    }
  end

  it do
    expect(model).to be_persisted
    expect(model).to_not be_changed
    expect(model).to have_attributes params.merge(
      state: 'unpublished'
    )
    expect(model.errors).to be_empty
    expect(model.topic).to have_attributes(
      linked: model,
      type: Topics::EntryTopics::ArticleTopic.name,
      forum_id: Forum::HIDDEN_ID
    )
  end
end
