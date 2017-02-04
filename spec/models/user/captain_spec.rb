require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#captain?' do
    context 'when user is captain of some team' do
      let(:user) { create :user }
      let!(:team) { create(:team, captain: user) }

      it 'returns true' do
        expect(user.captain?).to be
      end
    end

    context 'when user does not belong to any team' do
      let(:user) { create :user }

      it 'returns false' do
        expect(user.captain?).to be false
      end
    end

    context 'when user is a regular member of some team' do
      let(:user) { create :user }
      let(:team) { create(:team) }

      before :each do
        team.members << user
        team.save
      end

      it 'returns false' do
        expect(user.captain?).to be false
      end
    end
  end

end
