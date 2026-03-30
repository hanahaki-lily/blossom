# ==========================================
# DATA: Global Constants & State
# DESCRIPTION: Holds command categories and active game states.
# ==========================================

# Active session tracking
ACTIVE_BOMBS       = {} 
ACTIVE_COLLABS     = {}
ACTIVE_TRADES      = {}
ACTIVE_PROPOSALS   = {}

# Categorization for the Help Menu
COMMAND_CATEGORIES = {
  'Economy'   => [:balance, :daily, :work, :stream, :post, :collab, :cooldowns, :lottery, :lotteryinfo, :givecoins, :remindme, :event],
  'Gacha'     => [:summon, :collection, :banner, :shop, :buy, :view, :ascend, :trade, :givecard, :sell],
  'Arcade'    => [:coinflip, :slots, :roulette, :scratch, :dice, :cups, :blackjack, :spin],
  'Fun'       => [:kettle, :level, :leaderboard, :hug, :slap, :pat, :rep, :marry, :divorce, :birthday, :interactions, :serverinfo],
  'Utility'   => [:ping, :help, :about, :support, :premium, :link, :suggest, :profile],
  'Admin'     => [:setxp, :bomb, :levelup, :giveaway, :logsetup, :logtoggle, :purge, :kick, :ban, :timeout, :verifysetup, :achievements, :welcomer, :reactionrole, :commleveltoggle],
  'Developer' => [:dcoin, :dpremium, :blacklist, :card, :prisma, :dbomb, :dreset, :syncachievements, :devhelp]
}.freeze