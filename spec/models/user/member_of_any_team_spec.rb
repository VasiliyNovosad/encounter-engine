require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#member_of_any_team?' do
    context 'when member of any team' do
      let(:user) { create :user }
      let(:team) { create(:team) }

      before :each do
        team.members << user
        team.save
      end

      it 'returns true' do
        expect(user.member_of_any_team?).to be
      end
    end

    context 'when captain of any team' do
      let(:user) { create :user }
      let!(:team) { create(:team, captain: user) }

      it 'returns true' do
        expect(user.member_of_any_team?).to be
      end
    end

    context 'when not member of any team' do
      let(:user) { create :user }

      it 'returns false' do
        expect(user.member_of_any_team?).to be false
      end
    end
  end
end
