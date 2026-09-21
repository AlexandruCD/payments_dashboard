# frozen_string_literal: true

require "rails_helper"

RSpec.describe "English interface translations" do
  it "pluralizes form error headings" do
    expect(I18n.t("shared.error_messages.heading", count: 1)).to eq(
      "1 error prohibited this from being saved:"
    )
    expect(I18n.t("shared.error_messages.heading", count: 2)).to eq(
      "2 errors prohibited this from being saved:"
    )
  end

  it "formats dashboard timestamps" do
    timestamp = Time.zone.local(2026, 1, 2, 3, 4)

    expect(I18n.l(timestamp, format: :dashboard)).to eq("2026-01-02 03:04")
  end
end
