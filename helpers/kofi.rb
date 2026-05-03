# ==========================================
# HELPER: Ko-fi webhook verification & parsing
# Ko-fi POSTs JSON (or occasionally form-urlencoded with a `data` JSON blob).
# See README for setup; Ko-fi does not webhook subscription cancellation today.
# Optional ENV `KOFI_PAGE_URL`: public membership page linked from `premium`/`b!premium`.
# ==========================================

require 'cgi'
require 'json'
require 'openssl'

module KofiWebhook
  module_function

  SNOWFLAKE = /\A\d{17,20}\z/

  # Keys sometimes present on payloads when Discord info is propagated.
  DISCORD_ID_KEYS = %w[
    DiscordUserID discord_user_id shopper_discord_user_id discoDiscordUserProfile
    DiscordUserProfile discoUserID discordId shopper_user_id
  ].freeze

  def verified?(payload, secret)
    s = secret.to_s
    tok = payload.is_a?(Hash) ? payload['verification_token'].to_s : ''
    return false if s.empty? || tok.empty?
    return false if s.bytesize != tok.bytesize

    OpenSSL.fixed_length_secure_compare(s, tok)
  rescue ArgumentError, OpenSSL::OpenSSLError
    false
  end

  def membership_webhook?(payload)
    return false unless payload.is_a?(Hash)

    explicit = payload['type'].to_s.strip
    return true if membership_allowed_types.include?(explicit)

    truthy?(payload['is_subscription_payment']) || truthy?(payload['is_subscription'])
  end

  # Parse raw HTTP body → Hash or nil (malformed requests).
  def parse_payload(raw_body, content_type)
    ct = content_type.to_s.downcase

    parsed = parse_json_maybe(raw_body)
    return parsed if parsed

    if ct.include?('application/x-www-form-urlencoded') ||
       (raw_body.to_s.include?('=') && raw_body.to_s.include?('data'))
      params = CGI.parse(raw_body.to_s)
      blob = params['data']&.first
      return parse_json_maybe(blob) if blob && !blob.to_s.strip.empty?
    end

    nil
  end

  # Ko-fi webhook idempotency primary key — prefer Ko-fi-supplied IDs.
  def message_identifier(payload)
    return '' unless payload.is_a?(Hash)

    %w[message_id kofi_transaction_id payment_id].each do |key|
      v = payload[key]
      s = v.to_s.strip
      return s unless s.empty?
    end
    ''
  end

  def discord_uid(payload)
    return nil unless payload.is_a?(Hash)

    DISCORD_ID_KEYS.each do |key|
      uid = snowflake(payload[key])
      return uid if uid
    end

    %w[user subscriber shopper Discord discord].each do |key|
      sub = payload[key]
      nested = discord_uid(sub) if sub.is_a?(Hash)
      return nested if nested
    end

    nil
  end

  def membership_allowed_types
    raw = ENV['KOFI_MEMBERSHIP_WEBHOOK_TYPES'].to_s.strip
    list = raw.split(',').map(&:strip).reject(&:empty?)
    return ['Subscription'] if list.empty?

    list
  end

  # --- internals ---

  def parse_json_maybe(str)
    return nil if str.nil? || str.to_s.strip.empty?

    JSON.parse(str.to_s)
  rescue JSON::ParserError
    nil
  end

  def truthy?(v)
    v == true || v.to_s == '1' || v.to_s.downcase == 'true'
  end

  def snowflake(val)
    return nil if val.nil?

    str = case val
          when Numeric then val.to_i.to_s
          else val.to_s.strip
          end
    SNOWFLAKE.match?(str) ? str.to_i : nil
  end
end
