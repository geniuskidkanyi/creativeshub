class WaychitService
  BASE_URL = "https://api.waychit.com"
  API_KEY = Rails.application.credentials.waychit_api_key
  WEBHOOK_SECRET = Rails.application.credentials.waychit_webhook_secret

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

    def payment_request_id
      @payload.dig("paymentRequest", "id")
    end

    def payment_session_id
      @payload.dig("paymentSession", "id")
    end

    def launch_url
      @payload.dig("paymentRequest", "waychitLaunchUrl") ||
        @payload.dig("paymentSession", "waychitLaunchUrl")
    end

    def raw_response
      @payload
    end
  end

  def self.create_payment_request(amount:, client_reference:, description: nil, success_url:, failure_url:)
    new.create_payment_request(
      amount: amount,
      client_reference: client_reference,
      description: description,
      success_url: success_url,
      failure_url: failure_url
    )
  end

  def self.create_payment_session(client_reference:, line_items:, email:, return_url:, metadata: nil)
    new.create_payment_session(
      client_reference: client_reference,
      line_items: line_items,
      email: email,
      return_url: return_url,
      metadata: metadata
    )
  end

  def self.verify_signature(signature:, raw_body:)
    new.verify_signature(signature: signature, raw_body: raw_body)
  end

  def create_payment_request(amount:, client_reference:, description:, success_url:, failure_url:)
    response = HTTParty.post(
      "#{BASE_URL}/v1/payment-requests",
      headers: auth_headers,
      body: {
        amount: amount,
        description: description,
        clientReference: client_reference,
        successRedirectUrl: success_url,
        failureRedirectUrl: failure_url
      }.to_json
    )

    parse_response(response)
  end

  def create_payment_session(client_reference:, line_items:, email:, return_url:, metadata: nil)
    body = {
      clientReference: client_reference,
      lineItems: line_items.map do |item|
        line = {
          productName: item[:product_name],
          quantity: item[:quantity],
          price: item[:price].to_i
        }
        line[:productDescription] = item[:product_description] if item[:product_description].present?
        line
      end,
      customerEmail: email,
      returnRedirectUrl: return_url,
      metadata: (metadata || {}).transform_values(&:to_s)
    }

    response = HTTParty.post(
      "#{BASE_URL}/v1/payment-sessions/card",
      headers: auth_headers,
      body: body.to_json
    )

    parse_response(response)
  end

  def verify_signature(signature:, raw_body:)
    parts = signature.split(",")
    timestamp_part = parts.find { |p| p.start_with?("t=") }
    return false unless timestamp_part

    timestamp = timestamp_part.split("=")[1]
    signatures = parts
      .filter { |p| p.start_with?("v1=") }
      .map { |p| p.split("=")[1] }
    return false if signatures.empty?

    payload = "#{timestamp}.#{raw_body}"
    expected = OpenSSL::HMAC.hexdigest("sha256", WEBHOOK_SECRET, payload)

    return false if (Time.current.to_i - timestamp.to_i) > 300

    signatures.include?(expected)
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
    if response.success? && response["success"]
      Result.new(true, response.parsed_response)
    else
      Rails.logger.warn "Waychit API error: #{response.code} #{response.message} body=#{response.body}"
      error_msg = response.dig("message") || "HTTP #{response.code}: #{response.message}"
      Result.new(false, response.parsed_response || {}, error_msg)
    end
  rescue => e
    Rails.logger.error "Waychit API exception: #{e.class}: #{e.message}"
    Result.new(false, {}, e.message)
  end
end
