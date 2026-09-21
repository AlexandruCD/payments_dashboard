# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:merchant_user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:password) }

    it "does not allow the base class to be persisted" do
      base_user = build(:user)

      expect(base_user).not_to be_valid
      expect(base_user.errors[:type]).to include("can't be blank")
    end
  end

  describe "role predicates" do
    it "has no privileged role at the base class" do
      base_user = build(:user)

      expect(base_user).not_to be_admin
      expect(base_user).not_to be_merchant
    end
  end
end
