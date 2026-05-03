# ==========================================
# DATA: Core Bot & Leveling Settings
# DESCRIPTION: Basic connectivity and XP math.
# ==========================================

TOKEN  = ENV['TOKEN'] 
PREFIX = 'b!'
DEV_IDS = [701432383160975380].freeze
DEV_ID  = DEV_IDS.first # Primary dev (backwards compat)

# Owner hub: CV2 join/leave logs when Blossom is added or removed from any guild.
# Channel is in guild 1499998845873033316 (Neon Arcade hub).
HUB_GUILD_LOG_CHANNEL_ID = 150_033_978_361_092_9192

# --- LEVELING SYSTEM ---
XP_PER_MESSAGE         = 5
MESSAGE_COOLDOWN       = 10 
COINS_PER_MESSAGE      = 5
GLOBAL_LEVELUP_ENABLED = false

# --- BOMB SETTINGS ---
BOMB_MIN_MESSAGES = 100
BOMB_MAX_MESSAGES = 300