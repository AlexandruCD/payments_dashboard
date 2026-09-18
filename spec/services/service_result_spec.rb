# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceResult do
  it "returns a successful entity without errors" do
    entity = Object.new
    result = described_class.success(entity: entity)

    expect(result).to be_success
    expect(result).not_to be_failure
    expect(result.entity).to equal(entity)
    expect(result.errors).to eq([])
  end

  it "returns a failure without requiring an entity" do
    errors = [ { attribute: :base, code: :invalid, message: "Invalid submission" } ]
    result = described_class.failure(entity: nil, errors: errors)
    errors.first[:code] = :changed
    errors.clear

    expect(result).to be_failure
    expect(result).not_to be_success
    expect(result.entity).to be_nil
    expect(result.errors).to eq([ { attribute: :base, code: :invalid, message: "Invalid submission" } ])
  end
end
