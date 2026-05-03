# ==========================================
# HELPER: Top.gg webhook verification & links
# ==========================================

require 'openssl'

module TopggWebhook
  module_function

  def vote_page_url
    u = ENV['TOPGG_VOTE_PAGE_URL'].to_s.strip
    return u unless u.empty?

    bid = ENV['TOPGG_BOT_DISCORD_ID'].to_s.strip
    bid.empty? ? 'https://top.gg' : "https://top.gg/bot/#{bid}/vote"
  end

  # v1: x-topgg-signature header — HMAC-SHA256 of "#{timestamp}.#{rawBody}"
  def signature_valid?(raw_body, signature_header, secret)
    return false if secret.to_s.empty? || signature_header.to_s.empty? || raw_body.nil?

    ts = nil
    sig = nil
    signature_header.to_s.split(',').each do |part|
      k, v = part.split('=', 2)
      ts = v if k&.strip == 't'
      sig = v if k&.strip == 'v1'
    end
    return false if ts.nil? || sig.nil?

    expected = OpenSSL::HMAC.hexdigest('SHA256', secret, "#{ts}.#{raw_body}")
    return false unless expected.bytesize == sig.bytesize

    OpenSSL.secure_compare(expected, sig)
  end

  # Legacy v0: Authorization header matches secret from bot dashboard.
  def legacy_authorized?(req, secret)
    return false if secret.to_s.empty?

    auth = req['Authorization'] || req['HTTP_AUTHORIZATION']
    auth == secret
  end
end
