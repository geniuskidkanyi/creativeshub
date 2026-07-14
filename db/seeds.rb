puts "Seeding database..."

# --- SmartPay users (idempotent — safe to run repeatedly in any env) ---
[
  { email: "joop@smartpay.gm",  name: "Joop",           business_name: "Joop SmartPay" },
  { email: "kanyi@smartpay.gm", name: "Muhammed Kanyi", business_name: "Kanyi SmartPay" }
].each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  if user.new_record?
    account = Account.create!(business_name: attrs[:business_name], currency: "GMD")
    user.assign_attributes(
      name: attrs[:name],
      password: "Syj7i5qaJ4QH",
      account: account,
      confirmed_at: Time.current # confirmable: without this they can't log in
    )
    user.save!
    puts "Created user: #{user.email} with account #{account.business_name}"
  else
    puts "User already present: #{user.email}"
  end
end

# --- Demo dataset (opt-in: SEED_DEMO=1 bin/rails db:seed) ---
if ENV["SEED_DEMO"].present? && User.find_by(email: "jane@creativestudio.gm").nil?
  account = Account.create!(
    business_name: "Creative Studio Ltd",
    address: "123 Kairaba Avenue, Serrekunda",
    phone: "+220 123 4567",
    website: "https://smartpay.gm",
    tax_id: "TAX-001",
    currency: "GMD"
  )

  owner = User.create!(
    name: "Jane Doe",
    email: "jane@creativestudio.gm",
    password: "password123",
    role: :owner,
    account: account,
    confirmed_at: Time.current
  )

  puts "Created account: #{account.business_name}"
  puts "Created owner: #{owner.email}"

  10.times do
    Client.create!(
      account: account,
      name: Faker::Name.name,
      email: Faker::Internet.email,
      phone: Faker::PhoneNumber.cell_phone,
      company: Faker::Company.name,
      address: Faker::Address.full_address
    )
  end

  puts "Created 10 clients"

  5.times do |i|
    client = account.clients.sample
    invoice = Invoice.create!(
      account: account,
      client: client,
      status: [ :paid, :sent, :draft ].sample,
      issue_date: rand(60).days.ago.to_date,
      due_date: rand(30).days.from_now.to_date,
      tax_rate: [ 0, 10, 15 ].sample,
      notes: "Thank you for your business!"
    )

    rand(1..4).times do |j|
      InvoiceItem.create!(
        invoice: invoice,
        description: [ "Web Design", "Logo Design", "Branding Package", "Social Media Graphics", "UI/UX Design", "Consulting" ][j],
        quantity: rand(1..5),
        unit_price: rand(500..5000)
      )
    end

    invoice.reload

    if invoice.paid?
      Payment.create!(
        invoice: invoice,
        waychit_id: "waychit_test_#{i}",
        status: :succeeded,
        amount: invoice.total_amount,
        currency: "GMD",
        payment_method: [ :payment_request, :payment_session ].sample,
        transaction_reference: "trx_test_#{i}",
        paid_at: invoice.issue_date + rand(1..5).days
      )
    end

    if invoice.draft?
      invoice.update!(invoice_number: nil)
    end
  end

  puts "Created 5 invoices with line items and payments"
  puts "Demo login: jane@creativestudio.gm / password123"
end

puts "Done."
