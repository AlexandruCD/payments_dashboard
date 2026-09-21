# frozen_string_literal: true

SEED_PASSWORD = "password123"

admin_emails = %w[admin@payments-dashboard.test ops@payments-dashboard.test]

admin_emails.each do |email|
  AdminUser.find_or_create_by!(email: email) do |user|
    user.password = SEED_PASSWORD
  end
end

merchants = [
  { name: "Acme Corp", description: "Retail and e-commerce", email: "acme@payments-dashboard.test", status: "active" },
  { name: "Globex Inc", description: "B2B software licensing", email: "globex@payments-dashboard.test", status: "active" },
  { name: "Initech", description: "Office supplies distributor", email: "initech@payments-dashboard.test", status: "inactive" }
]

merchants.each do |attrs|
  merchant = Merchant.find_or_create_by!(email: attrs[:email]) do |record|
    record.name        = attrs[:name]
    record.description = attrs[:description]
    record.status      = attrs[:status]
  end

  MerchantUser.find_or_create_by!(merchant: merchant) do |user|
    user.email = attrs[:email]
    user.password = SEED_PASSWORD
  end
end

puts "Seeded #{User.count} users and #{Merchant.count} merchants"
