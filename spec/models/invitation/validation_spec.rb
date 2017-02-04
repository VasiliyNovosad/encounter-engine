require 'rails_helper'

RSpec.describe Invitation, type: :model do
  context 'regular case, captain attempts to invite a new user' do
    let(:captain) { create :user }
    let(:user) { create :user }
    let(:team) { create(:team, captain: captain) }
    let(:invitation) { build(:invitation, to_team: team, recepient_nickname: user.nickname)}

    it 'should be valid' do
      expect(invitation).to be_valid
    end
  end

  context 'captain attempts to invite a member of another team' do
    let(:captain) { create :user }
    let(:team) { create(:team, captain: captain) }
    let(:user) { create :user }
    let!(:team2) { create(:team, captain: captain, members: [user]) }

    let(:invitation) { build(:invitation, to_team: team, recepient_nickname: user.nickname)}

    it 'should be valid' do
      expect(invitation).to be_valid
    end
  end

  context 'captain attempts to invite a member of his own team' do
    let(:captain) { create :user }
    let(:user) { create :user }
    let(:team) { create(:team, captain: captain, members: [user]) }

    let(:invitation) { build(:invitation, to_team: team, recepient_nickname: user.nickname)}

    it 'should not be valid' do
      expect(invitation).not_to be_valid
    end
  end

  context 'captain attempts to invite himself :-)' do
    let(:captain) { create :user }
    let(:team) { create(:team, captain: captain) }

    let(:invitation) { build(:invitation, to_team: team, recepient_nickname: captain.nickname)}

    it 'should not be valid' do
      expect(invitation).not_to be_valid
    end
  end

  context 'captain attempts to invite someone twice' do
    let(:captain) { create :user }
    let(:user) { create :user }
    let(:team) { create(:team, captain: captain) }

    let!(:invitation) { create(:invitation, to_team: team, recepient_nickname: user.nickname)}
    let(:invitation2) { build(:invitation, to_team: team, recepient_nickname: user.nickname)}

    it 'should not be valid' do
      expect(invitation2).not_to be_valid
    end
  end

  context 'captain attempts to invite someone twice' do
    let(:captain1) { create :user }
    let(:captain2) { create :user }
    let(:user) { create :user }
    let(:team1) { create(:team, captain: captain1) }
    let(:team2) { create(:team, captain: captain2) }

    let!(:invitation1) { create(:invitation, to_team: team1, recepient_nickname: user.nickname)}
    let(:invitation2) { build(:invitation, to_team: team2, recepient_nickname: user.nickname)}

    it 'should be valid' do
      expect(invitation2).to be_valid
    end
  end

  context 'captain attempts to create invitation without providing recipient email' do
    let(:captain) { create :user }
    let(:team) { create(:team, captain: captain) }

    let(:invitation) { build(:invitation, to_team: team, recepient_nickname: nil)}

    it 'should not be valid' do
      expect(invitation).not_to be_valid
    end
  end

  context 'captain attempts providing an unexistant recipient email' do
    let(:captain) { create :user }
    let(:team) { create(:team, captain: captain) }

    let(:invitation) { build(:invitation, to_team: team, recepient_nickname: 'unexistent@email.com')}

    it 'should not be valid' do
      expect(invitation).not_to be_valid
    end
  end
end