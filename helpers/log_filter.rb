# ==========================================
# HELPER: Discordrb Log Filter
# DESCRIPTION: Silences noisy discordrb output: websocket reconnect churn
# (normal Discord/infra) and Discord API errors that get logged BEFORE
# discordrb raises them so rescued code still spams the console.
# Add new patterns to SUPPRESSED_LOG_PATTERNS if more low-signal noise shows up.
# ==========================================

unless defined?(BLOSSOM_LOG_FILTER_PATCHED)
  BLOSSOM_LOG_FILTER_PATCHED = true

  # Substrings (or Regexps) that, if present in an error log line,
  # cause that line to be silently dropped. Keep this list small —
  # anything we add here is genuinely invisible.
  SUPPRESSED_LOG_PATTERNS = [
    'Unknown Member', # 10007: stale member fetch (left/kicked/etc.)
    'Unknown Channel' # 10003: deleted/missing channel; callers rescue and log in context
  ].freeze

  module Discordrb
    class Logger
      alias_method :__blossom_original_write, :write

      def write(message, mode_hash)
        # All gateway disconnect/reconnect chatter runs on discordrb's :websocket worker thread (non-actionable noise).
        return if Thread.current[:discordrb_name].to_s.casecmp('websocket').zero?

        __blossom_original_write(message, mode_hash)
      end

      alias_method :__blossom_original_error, :error

      def error(message)
        msg = message.to_s
        return if SUPPRESSED_LOG_PATTERNS.any? { |pat| pat.is_a?(Regexp) ? msg.match?(pat) : msg.include?(pat) }

        __blossom_original_error(message)
      end
    end
  end
end
