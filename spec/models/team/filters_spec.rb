require 'rails_helper'

RSpec.describe Team, type: :model do
  context 'when assigning a team member as a captain' do
    let(:captain) { create :user }
    let(:user) { create :user }
    let(:team) { create :team }

    before :each do
      team.members << [user, captain]
      team.captain = captain
      team.save
    end

    it 'sets user as captain' do
      expect(team.captain).to eq(captain)
    end
  end

  context "when assigning an 'external' user as a captain" do
    let(:captain) { create :user }
    let(:member) { create :user }
    let(:team) { create :team }

    before :each do
      team.members << [member]
      team.captain = captain
      team.save
    end

    it 'sets user as captain' do
      expect(team.captain).to eq(captain)
    end

    it 'adds captain to members list' do
      expect(team.members).to include captain
    end
  end
end