# ==========================================
# HELPER: Discordrb Log Filter
# DESCRIPTION: Silences noisy, untraceable Discord API errors that
# get logged BEFORE discordrb raises them — meaning even properly
# rescued exceptions still spam the console. We can't pinpoint the
# call sites with 1000+ users across 13+ servers, so we filter the
# log output instead. Add new patterns to SUPPRESSED_LOG_PATTERNS
# if more low-signal noise shows up.
# ==========================================

# Substrings (or Regexps) that, if present in an error log line,
# cause that line to be silently dropped. Keep this list small —
# anything we add here is genuinely invisible.
SUPPRESSED_LOG_PATTERNS = [
  'Unknown Member', # 10007: stale member fetch (left/kicked/etc.)
  'Unknown Channel' # 10003: deleted/missing channel; callers rescue and log in context
].freeze

module Discordrb
  class Logger
    alias_method :__blossom_original_error, :error

    def error(message)
      msg = message.to_s
      return if SUPPRESSED_LOG_PATTERNS.any? { |pat| pat.is_a?(Regexp) ? msg.match?(pat) : msg.include?(pat) }

      __blossom_original_error(message)
    end
  end
end
