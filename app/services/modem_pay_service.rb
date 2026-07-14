class ModemPayService
  BASE_URL = "https://api.modempay.com"

  # Live keys in production, test keys in every other environment. The
  # unsuffixed credentials hold the test keys; the _live variants go live.
  LIVE_MODE = Rails.env.production?

  API_KEY = if LIVE_MODE
    Rails.application.credentials.modempay_api_secret_live!
  else
    Rails.application.credentials.modempay_api_secret!
  end

  # Modem Pay signs webhooks with a per-mode secret: test-mode events are
  # signed with the test webhook secret, live events with the live one.
  # The environment's own secret comes first; the other stays as a fallback
  # so e.g. a test-mode charge against production still verifies.
  WEBHOOK_SECRETS = if LIVE_MODE
    [
      Rails.application.credentials.modempay_webhook_secret_hash_live,
      Rails.application.credentials.modempay_webhook_secret_hash
    ]
  else
    [
      Rails.application.credentials.modempay_webhook_secret_hash,
      Rails.application.credentials.modempay_webhook_secret_hash_live
    ]
  end.compact.reject { |s| s.to_s.strip.empty? }.freeze

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

    # Transfer/payout responses may arrive flat or wrapped in "data".
    def transfer_data
      @payload.is_a?(Hash) && @payload["data"].is_a?(Hash) ? @payload["data"] : @payload
    end

    def transfer_id = transfer_data["id"]
    def transfer_status = transfer_data["status"]
    def transfer_reference = transfer_data["transfer_reference"]
    def transfer_fee = transfer_data["fee"]

    def payout_balance = @payload["payout_balance"]
    def available_balance = @payload["available_balance"]
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
    return false if signature.blank? || WEBHOOK_SECRETS.empty?

    WEBHOOK_SECRETS.any? do |secret|
      computed = OpenSSL::HMAC.hexdigest("sha512", secret, payload)
      computed.length == signature.length &&
        ActiveSupport::SecurityUtils.secure_compare(computed, signature)
    end
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

  def self.fetch_balances
    new.fetch_balances
  end

  def self.transfer_fee(amount:, currency: "GMD", network:)
    new.transfer_fee(amount: amount, currency: currency, network: network)
  end

  def self.create_transfer(**kwargs)
    new.create_transfer(**kwargs)
  end

  # GET /v1/balances → { payout_balance:, available_balance: }
  def fetch_balances
    response = HTTParty.get("#{BASE_URL}/v1/balances", headers: auth_headers, timeout: 30)
    parse_plain_response(response)
  end

  # POST /v1/transfers/fees → { fee:, amount:, currency:, network: }
  def transfer_fee(amount:, currency: "GMD", network:)
    response = HTTParty.post(
      "#{BASE_URL}/v1/transfers/fees",
      headers: auth_headers,
      body: { amount: amount, currency: currency, network: network }.to_json,
      timeout: 30
    )
    parse_plain_response(response)
  end

  # POST /v1/transfers — sends a mobile money payout. The Idempotency-Key header
  # guarantees retries of the same request never produce a second transfer.
  def create_transfer(amount:, currency: "GMD", network:, account_number:, beneficiary_name:, idempotency_key:, narration: nil, metadata: {})
    body = {
      amount: amount,
      currency: currency,
      network: network,
      account_number: account_number,
      beneficiary_name: beneficiary_name
    }
    body[:narration] = narration if narration.present?
    body[:metadata] = metadata.transform_values(&:to_s) if metadata.present?

    response = HTTParty.post(
      "#{BASE_URL}/v1/transfers",
      headers: auth_headers.merge("Idempotency-Key" => idempotency_key),
      body: body.to_json,
      timeout: 30
    )
    parse_plain_response(response)
  end

  private

  def auth_headers
    {
      "Authorization" => "Bearer #{API_KEY}",
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  # Balances/fees/transfers respond without the "status"/"id" envelope that
  # parse_response expects, so success is judged on the HTTP code alone.
  def parse_plain_response(response)
    if response.success?
      Result.new(true, response.parsed_response || {})
    else
      Rails.logger.warn "ModemPay API error: #{response.code} #{response.message} body=#{response.body}"
      error_msg = response.parsed_response.is_a?(Hash) && response.parsed_response["message"].presence || "HTTP #{response.code}: #{response.message}"
      Result.new(false, response.parsed_response.is_a?(Hash) ? response.parsed_response : {}, error_msg)
    end
  rescue => e
    Rails.logger.error "ModemPay API exception: #{e.class}: #{e.message}"
    Result.new(false, {}, e.message)
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
