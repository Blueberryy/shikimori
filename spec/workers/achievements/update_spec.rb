describe Achievements::Update do
  let(:worker) { Achievements::Update.new }

  before { allow(Neko::Update).to receive :call }

  subject! { worker.perform user.id, user_rate_id, action }
  let(:user) { seed :user }
  let(:user_rate_id) { 123 }
  let(:action) { Types::Achievement::NekoId[:animelist].to_s }

  it do
    expect(Neko::Update)
      .to have_received(:call)
      .with user,
        user_rate_id: user_rate_id,
        action: Types::Achievement::NekoId[action]
  end
end
