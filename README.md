# Blossom

> **"Welcome to the Neon Arcade. I run the games, the economy, and your entire server. You're welcome."**

Hey, chat. I'm Blossom -- your favorite digital streamer, arcade manager, and the reason your Discord server isn't boring. Built by my mom **baonuki**, I handle everything from keeping your community in check to running a full-blown underground VTuber economy. Yeah, I'm kind of a big deal.

## What I Actually Do

### The Economy (AKA Why You're All Broke)
I run the entire financial ecosystem around here. You grind, I pay. Simple.
- `/stream`, `/post`, `/work` -- Generate income like a real content creator. Or at least pretend to.
- `/daily` -- Free coins every day because I'm generous like that.
- `/collab` -- Team up with another player for bonus revenue. Friendship is profitable.
- `/balance` -- Check your stats, inventory, VTuber collection, and achievements all in one place.

### The VTuber Gacha (Your New Addiction)
Over **100+ collectible VTubers** across four rarity tiers. Good luck.
- `/summon` -- Roll the gacha portal. Pray for something good.
- `/banner` -- See who's in the current rotation.
- `/buy` -- Skip the RNG and buy characters directly. If you can afford it.
- `/sell` -- Dump your duplicates for coins. Declutter arc.
- `/ascend` -- Feed 5 dupes to create a **Shiny Ascended** variant. Flex material.
- `/view` -- Admire your pulls. I'll comment on them whether you like it or not.
- `/collection` -- Browse your full collection by rarity.

### The Black Market
My underground tech shop. Permanent upgrades and one-time consumables to give you an edge.
- **Stream Upgrades** -- Headset, RGB Keyboard, Studio Mic, and more. Boost your payouts permanently.
- **Gamer Fuel** -- Crack one open and reset ALL your content cooldowns instantly.
- **Stamina Pill** -- Reset your summon cooldown. Back to the gacha mines.
- **RNG Manipulator** -- Guarantees your next summon is Rare or higher. You're welcome.

### The Arcade (Gambling, Basically)
Risk your hard-earned coins for glory or go home broke. Your call.
- `/slots` -- Classic slot machine. Triple match = jackpot.
- `/roulette` -- Pick a color, place your bet, hold your breath.
- `/coinflip` -- 50/50. The purest form of gambling.
- `/scratch` -- Scratcher tickets. Cheap thrills.

### Leveling & Community
- **Auto XP** -- Just chat and you level up. Lurkers don't get rewarded here.
- `/level` -- Check your level, XP, and rank.
- `/leaderboard` -- See who's on top. Spoiler: it's probably not you.
- `/serverinfo` -- Your server's community level and stats.

### Social Commands
- `/hug`, `/slap` -- Express yourself. With tracked stats, because everything is a competition.

### Moderation
I keep things clean so you don't have to.
- Verification gates, mod logging, member management, and server-wide configs.
- Bomb system for custom server thresholds and admin-only settings.

### Premium Perks
Subscribers get the VIP treatment via the **Discord supporter role** Blossom checks (and optional developer lifetime tier):
- **[Ko-fi memberships](https://help.ko-fi.com/hc/en-us/articles/360020363857-Setting-up-Discord-rewards-with-Ko-fi)** — Recommended: Ko-fi’s Discord rewards assign/remove the **same Premium role IDs** Blossom already uses (`PREMIUM_SERVERS` in code). Optionally set **`KOFI_VERIFICATION_TOKEN`** so Ko-fi pings `POST /webhooks/kofi` (see below — logging / cache invalidate; entitlement stays role-based). **`KOFI_PAGE_URL`** powers **`b!premium` / `/premium`** with your public Ko-fi URL.

- **50% reduced cooldowns** on key economy commands (`work`, `stream`, `post`, `fish`; see `/cooldowns`)
- **+10% coin bonus** on all earnings
- **Prisma currency** to buy Goddess-tier characters directly
- **1% chance** to pull a Shiny Ascended straight from the portal

## Tech Stuff

| | |
|---|---|
| **Language** | Ruby 3.4 |
| **Framework** | discordrb 3.7.2 |
| **Database** | PostgreSQL (via `pg` + `connection_pool`) |
| **HTTP (optional)** | WEBrick shared listener — `POST /webhooks/topgg` when **`TOPGG_WEBHOOK_SECRET`**; **`POST /webhooks/kofi`** when **`KOFI_VERIFICATION_TOKEN`**; **`TOPGG_WEBHOOK_BIND`**, **`TOPGG_WEBHOOK_PORT`** (default `8081`) |
| **Architecture** | Modular loader system |

## Self-hosted webhooks (Top.gg votes + Ko-fi memberships)

Expose **`TOPGG_WEBHOOK_PORT`** (default **8081**, bind **`TOPGG_WEBHOOK_BIND`**) reverse-proxied to your Ruby process. One WEBrick stacks optional routes depending on env ([`components/blossom_webhook_server.rb`](components/blossom_webhook_server.rb); **`TopggWebhookServer`** is an alias).

**Reverse-proxy pattern:** terminate TLS on nginx/Caddy/etc. and forward HTTP to **`http://127.0.0.1:<TOPGG_WEBHOOK_PORT>`** preserving `POST` and body (e.g. map **`https://your-domain/webhooks/kofi`** → **`http://127.0.0.1:8081/webhooks/kofi`** and **`…/webhooks/topgg`** the same host/port). Blossom does not serve HTTPS itself.

### Entitlement architecture (Ko-fi Path A vs Path B)

**Path A (recommended)** — Blossom’s premium check ultimately comes from **`PREMIUM_SERVERS`** Discord roles (plus optional lifetime tier in DB). Use **[Ko-fi Discord rewards](https://help.ko-fi.com/hc/en-us/articles/360020363857-Setting-up-Discord-rewards-with-Ko-fi)** so Ko-fi assigns/removes those **exact** role IDs. Revocation stays reliable because removal is tied to **Discord**, not Ko-fi webhook callbacks.

**Path B (optional)** — **`KOFI_VERIFICATION_TOKEN`** enables **`POST /webhooks/kofi`** on the **same bind/port** as Top.gg when set. Blossom verifies payloads, **`kofi_webhooks_processed`** dedupes events, clears **`is_premium?`** after **`grant_premium_roles_after_kofi`**: tries to **`add_role`** each **`PREMIUM_SERVERS`** pairing for that Discord user wherever they share a guild with the bot (**Manage Roles** + hierarchy required). Ko-fi’s webhook **still does not** notify when a subscription *ends,* so combine with **[Ko‑fi Discord rewards](https://help.ko-fi.com/hc/en-us/articles/360020363857-Setting-up-Discord-rewards-with-Ko-fi)** for reliable role **removal**, or use **`dpremium`** / audits—do not rely on Path B alone for end-of-membership.

### Top.gg votes (`/webhooks/topgg`)

Expose `POST …/webhooks/topgg`. In the top.gg dashboard, paste the **v1 webhook secret** (`whs_…`) into **`TOPGG_WEBHOOK_SECRET`**. Set **`TOPGG_BOT_DISCORD_ID`** to your bot’s Discord ID.

Optional: **`TOPGG_VOTE_PAGE_URL`**, **`TOPGG_WEBHOOK_PORT`**, **`TOPGG_WEBHOOK_BIND`** (defaults **8081**, **0.0.0.0**).

### Ko-fi memberships (`/webhooks/kofi`)

**Primary entitlement:** Align **[Ko-fi Discord rewards](https://help.ko-fi.com/hc/en-us/articles/360020363857-Setting-up-Discord-rewards-with-Ko-fi)** with **`PREMIUM_SERVERS`** role IDs (Path A).

**Environment variables:**

| Variable | Required for Ko-fi listener | Purpose |
|---|---|---|
| **`KOFI_VERIFICATION_TOKEN`** | Yes | Must match **`verification_token`** in Ko-fi’s JSON payloads; set from [Ko-fi → Manage → Webhooks](https://ko-fi.com/manage/webhooks). |
| **`KOFI_MEMBERSHIP_WEBHOOK_TYPES`** | No | Comma-separated JSON **`type`** values counted as memberships (default **`Subscription`**). Tips/shop pings still ACK **`200`** but are skipped for membership bookkeeping. |
| **`KOFI_PAGE_URL`** | No | Public Ko-fi creator/membership page shown by **`b!premium`** / **`/premium`** (e.g. `https://ko-fi.com/yourslug`). Omit if you want perk blurbs only — no clickable link line. |

Shared with Top.gg **`WEBrick`** process: **`TOPGG_WEBHOOK_PORT`** (default **8081**), **`TOPGG_WEBHOOK_BIND`** (**0.0.0.0**).

**Webhook URL:** **`POST …/webhooks/kofi`** (same scheme/host as your Top.gg webhook if sharing the listener). Blossom verifies payloads, writes idempotent **`kofi_webhooks_processed`** rows, and when Ko-fi includes a **Discord user snowflake**, syncs **`PREMIUM_SERVERS`** roles (**`grant_premium_roles_after_kofi`**): adds each subscriber role wherever the payer is actually in-server and Blossom has **Manage Roles** + hierarchy over that role.

**Removal:** Membership-end events are **not** in Ko‑fi webhook callbacks today — keep **[Ko‑fi Discord rewards](https://help.ko-fi.com/hc/en-us/articles/360020363857-Setting-up-Discord-rewards-with-Ko-fi)** for automatic **role removal**, or audit manually. Blossom’s webhook grants / no-op skips are **replay-safe** (duplicate Ko-fi retries still reconcile missing roles).

**Discord user id:** Your Ko-fi payloads must expose a Discord snowflake (Ko‑fi’s Discord linkage or a buyer field Blossom recognizes — see **`KofiWebhook::DISCORD_ID_KEYS`** in code). Without it, the webhook still ACKs **`200`** but cannot apply roles automatically.

## The Creator

Built with genuine love (and probably too much caffeine) by **baonuki** -- Software Architect, Game Engine Scripter, and my mom.

*Built by baonuki*
