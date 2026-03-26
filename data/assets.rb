# ==========================================
# DATA: Aesthetic Assets
# DESCRIPTION: Brand colors and Emoji ID mapping.
# ==========================================

NEON_COLORS = [0xFF00FF, 0x00FFFF, 0x8A2BE2, 0xFF1493, 0x00BFFF, 0x9400D3, 0xFF69B4].freeze

# ------------------------------------------
# EMOJI_STRINGS: Discord markdown format for text content
# Use in: CV2 Type 10 content, embed titles/descriptions, DMs, any string interpolation
# Format: <:name:id> (static) or <a:name:id> (animated)
# ------------------------------------------
EMOJI_STRINGS = {
  # Animated character emojis
  'coin'         => '<a:coin:1476300163730640956>',         # Girl collecting a coin
  'angry'        => '<a:angry:1476300253094346908>',        # Girl angry
  'bonk'         => '<a:bonk:1476300267359310138>',         # Girl being hit on head with hammer
  'drink'        => '<a:drink:1476300280512516146>',        # Girl drinking a soda
  'error'        => '<a:error:1476300312439554078>',        # Girl shocked with exclamation marks
  'jail'         => '<a:jail:1476300328398885017>',         # Girl locked in jail
  'rich'         => '<a:rich:1476300389652500531>',         # Girl with a lot of money
  'nervous'      => '<a:nervous:1476300444618981599>',      # Girl worried
  'confused'     => '<a:confused:1476300459286331597>',     # Girl confused
  'coins'        => '<a:coins:1476300477217112127>',        # Girl having coins rain down
  'surprise'     => '<a:surprise:1476300545445724200>',     # Girl surprised
  'work'         => '<a:work:1476300654120276148>',         # Girl working at a computer
  'worktired'    => '<a:worktired:1476300670482251960>',    # Girl tired at a computer

  # Static character emojis
  'knife'        => '<:knife:1476300339887214754>',         # Girl threatening with a knife
  'hearts'       => '<:hearts:1476300374993408080>',        # Girl holding a heart
  'mute'         => '<:mute:1476300428860985446>',          # Girl muted
  'sparkle'      => '<:sparkle:1476300494195654820>',       # Girl amazed
  'thumbsup'     => '<:thumbsup:1476300593822826516>',      # Girl giving a thumbs up
  'thumbsdown'   => '<:thumbsdown:1476300611673788607>',    # Girl giving a thumbs down

  # Animated neon/UI emojis
  'neonsparkle'  => '<a:neonsparkle:1476318215339769868>',  # Neon sparkles
  'rainbowheart' => '<a:rainbowheart:1476318353189765140>', # Neon rainbow heart
  'info'         => '<a:info:1476318560123879626>',         # Neon info symbol
  'confuse'      => '<a:confuse:1476318602272444468>',      # Question marks
  'bomb'         => '<a:bomb:1476321595877232802>',         # Bomb exploding in neon colors

  # Static neon/UI emojis
  'x_'           => '<:x_:1476317931099914271>',            # Red X
  'play'         => '<:play:1476317972799815741>',          # Green play button
  'stream'       => '<:stream:1476318017217368084>',        # Streaming logo
  'crown'        => '<:crown:1476318072464871646>',         # Neon crown
  'heart'        => '<:heart:1476318158104039445>',         # Pair of neon hearts
  'developer'    => '<:developer:1476318256200552528>',     # Developer logo
  's_coin'       => '<:s_coin:1476318407044628664>',        # Currency logo
  'prisma'       => '<:prisma:1486142162805723196>',        # Premium logo
}.freeze

# Backwards-compatible alias
EMOJIS = EMOJI_STRINGS

# ------------------------------------------
# EMOJI_OBJECTS: Hash format for CV2 component properties
# Use in: button emoji fields, select menu option emoji fields
# Format: { name: 'name', id: 'id' } with optional animated: true
# ------------------------------------------
EMOJI_OBJECTS = {
  # Animated
  'coin'         => { name: 'coin',         id: '1476300163730640956', animated: true },
  'angry'        => { name: 'angry',        id: '1476300253094346908', animated: true },
  'bonk'         => { name: 'bonk',         id: '1476300267359310138', animated: true },
  'drink'        => { name: 'drink',        id: '1476300280512516146', animated: true },
  'error'        => { name: 'error',        id: '1476300312439554078', animated: true },
  'jail'         => { name: 'jail',         id: '1476300328398885017', animated: true },
  'rich'         => { name: 'rich',         id: '1476300389652500531', animated: true },
  'nervous'      => { name: 'nervous',      id: '1476300444618981599', animated: true },
  'confused'     => { name: 'confused',     id: '1476300459286331597', animated: true },
  'coins'        => { name: 'coins',        id: '1476300477217112127', animated: true },
  'surprise'     => { name: 'surprise',     id: '1476300545445724200', animated: true },
  'work'         => { name: 'work',         id: '1476300654120276148', animated: true },
  'worktired'    => { name: 'worktired',    id: '1476300670482251960', animated: true },
  'neonsparkle'  => { name: 'neonsparkle',  id: '1476318215339769868', animated: true },
  'rainbowheart' => { name: 'rainbowheart', id: '1476318353189765140', animated: true },
  'info'         => { name: 'info',         id: '1476318560123879626', animated: true },
  'confuse'      => { name: 'confuse',      id: '1476318602272444468', animated: true },
  'bomb'         => { name: 'bomb',         id: '1476321595877232802', animated: true },
  # Static
  'knife'        => { name: 'knife',        id: '1476300339887214754' },
  'hearts'       => { name: 'hearts',       id: '1476300374993408080' },
  'mute'         => { name: 'mute',         id: '1476300428860985446' },
  'sparkle'      => { name: 'sparkle',      id: '1476300494195654820' },
  'thumbsup'     => { name: 'thumbsup',     id: '1476300593822826516' },
  'thumbsdown'   => { name: 'thumbsdown',   id: '1476300611673788607' },
  'x_'           => { name: 'x_',           id: '1476317931099914271' },
  'play'         => { name: 'play',         id: '1476317972799815741' },
  'stream'       => { name: 'stream',       id: '1476318017217368084' },
  'crown'        => { name: 'crown',        id: '1476318072464871646' },
  'heart'        => { name: 'heart',        id: '1476318158104039445' },
  'developer'    => { name: 'developer',    id: '1476318256200552528' },
  's_coin'       => { name: 's_coin',       id: '1476318407044628664' },
  'prisma'       => { name: 'prisma',       id: '1486142162805723196' },
}.freeze
