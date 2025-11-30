import fs from "fs";
import path from "path";
import { EmbedBuilder } from "discord.js";

const fishingFile = path.join(process.cwd(), "data/fishing.json");
if (!fs.existsSync(fishingFile)) fs.writeFileSync(fishingFile, "{}");

function saveFishing(data) {
  fs.writeFileSync(fishingFile, JSON.stringify(data, null, 2));
}

const fishTypes = [
  { name: "Small Fish", xp: 5, coins: 10 },
  { name: "Medium Fish", xp: 15, coins: 25 },
  { name: "Large Fish", xp: 30, coins: 50 },
  { name: "Golden Fish", xp: 50, coins: 100 },
];

export default {
  name: "fish",
  description: "Go fishing and earn XP & coins!",
  execute: (message) => {
    const userId = message.author.id;
    let data = JSON.parse(fs.readFileSync(fishingFile, "utf8"));

    if (!data[userId]) {
      data[userId] = { level: 1, xp: 0, coins: 0, caught: {} };
    }

    const user = data[userId];

    // Random fish
    const caught = fishTypes[Math.floor(Math.random() * fishTypes.length)];

    // XP & coins
    user.xp += caught.xp;
    user.coins += caught.coins;

    // Track caught fish
    if (!user.caught[caught.name]) user.caught[caught.name] = 0;
    user.caught[caught.name]++;

    // Level up
    const nextLevelXP = user.level * 100;
    let levelUpMsg = "";
    if (user.xp >= nextLevelXP) {
      user.level++;
      user.xp -= nextLevelXP;
      levelUpMsg = `\n✨ You leveled up! Now at Level ${user.level}!`;
    }

    saveFishing(data);

    // Embed reply
    const embed = new EmbedBuilder()
      .setTitle(`🎣 ${message.author.username} went fishing!`)
      .setDescription(
        `You caught a **${caught.name}**!\n💗 XP: +${caught.xp}\n💰 Coins: +${caught.coins}${levelUpMsg}`
      )
      .setColor("#ffc1cc")
      .setTimestamp()
      .setThumbnail(message.author.displayAvatarURL({ dynamic: true }));

    message.channel.send({ embeds: [embed] });
  },
};
