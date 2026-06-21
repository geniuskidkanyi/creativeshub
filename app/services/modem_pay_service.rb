class ModemPayService
  BASE_URL = "https://api.modempay.com"
  API_KEY = Rails.application.credentials.modempay_api_secret!
  WEBHOOK_SECRET = Rails.application.credentials.modempay_webhook_secret_hash!

  class Result
    attr_reader :success, :payload, :error

    def initialize(success, payload = {}, error = nil)
      @success = success
      @payload = payload
      @error = error
    end

    def success?
      @success
    end

    def payment_intent_id
      @payload.dig("data", "intent_secret")
    end

    def payment_link
      @payload.dig("data", "payment_link")
    end

    def raw_response
      @payload
    end
  end

  def self.create_payment(amount:, currency: "GMD", description: nil, metadata: {}, return_url: nil, cancel_url: nil, payment_methods: nil, sub_account: nil)
    new.create_payment(
      amount: amount,
      currency: currency,
      description: description,
      metadata: metadata,
      return_url: return_url,
      cancel_url: cancel_url,
      payment_methods: payment_methods,
      sub_account: sub_account
    )
  end

  def self.verify_signature(payload:, signature:)
    new.verify_signature(payload: payload, signature: signature)
  end

  def create_payment(amount:, currency: "GMD", description: nil, metadata: {}, return_url: nil, cancel_url: nil, payment_methods: nil, sub_account: nil)
    data = {
      amount: amount,
      currency: currency,
      from_sdk: false
    }
    data[:title] = description if description.present?
    data[:description] = description if description.present?
    data[:metadata] = metadata.transform_values(&:to_s) if metadata.present?
    data[:return_url] = return_url if return_url.present?
    data[:cancel_url] = cancel_url if cancel_url.present?
    data[:payment_methods] = payment_methods if payment_methods.present?
    data[:sub_account] = sub_account if sub_account.present?

    body = { data: data }

    response = HTTParty.post(
      "#{BASE_URL}/v1/payments",
      headers: auth_headers,
      body: body.to_json,
      timeout: 30
    )

    parse_response(response)
  end

  def verify_signature(payload:, signature:)
    return false if signature.blank? || WEBHOOK_SECRET.blank?

    computed = OpenSSL::HMAC.hexdigest("sha512", WEBHOOK_SECRET, payload)

    return false if computed.length != signature.length

    ActiveSupport::SecurityUtils.secure_compare(computed, signature)
  end

  def self.create_sub_account(business_name:, percentage:, settlement_code:, account_number:)
    new.create_sub_account(
      business_name: business_name,
      percentage: percentage,
      settlement_code: settlement_code,
      account_number: account_number
    )
  end

  def self.update_sub_account(id:, percentage:, settlement_code:, account_number:)
    new.update_sub_account(id: id, percentage: percentage, settlement_code: settlement_code, account_number: account_number)
  end

  def create_sub_account(business_name:, percentage:, settlement_code:, account_number:)
    body = {
      business_name: business_name,
      percentage: percentage,
      settlement_code: settlement_code,
      account_number: account_number
    }

    response = HTTParty.post(
      "#{BASE_URL}/v1/sub-accounts",
      headers: auth_headers,
      body: body.to_json,
      timeout: 30
    )

    parse_response(response)
  end

  def update_sub_account(id:, percentage:, settlement_code:, account_number:)
    body = {
      percentage: percentage,
      settlement_code: settlement_code,
      account_number: account_number
    }

    response = HTTParty.put(
      "#{BASE_URL}/v1/sub-accounts/#{id}",
      headers: auth_headers,
      body: body.to_json,
      timeout: 30
    )

    parse_response(response)
  end

  private

  def auth_headers
    {
      "Authorization" => "Bearer #{API_KEY}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  def parse_response(response)
    if response.success? && (response["status"] || response["id"])
      Result.new(true, response.parsed_response)
    else
      Rails.logger.warn "ModemPay API error: #{response.code} #{response.message} body=#{response.body}"
      error_msg = response.dig("message") || "HTTP #{response.code}: #{response.message}"
      Result.new(false, response.parsed_response || {}, error_msg)
    end
  rescue => e
    Rails.logger.error "ModemPay API exception: #{e.class}: #{e.message}"
    Result.new(false, {}, e.message)
  end
end
