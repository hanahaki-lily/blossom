import fs from "fs";
import path from "path";
import { EmbedBuilder } from "discord.js";

const fishingFile = path.join(process.cwd(), "data/fishing.json");

export default {
  name: "myfish",
  description: "Show all the fish you’ve caught",
  execute: (message) => {
    const userId = message.author.id;

    if (!fs.existsSync(fishingFile)) fs.writeFileSync(fishingFile, "{}");

    const data = JSON.parse(fs.readFileSync(fishingFile, "utf8"));
    const user = data[userId];

    if (!user || !user.caught || Object.keys(user.caught).length === 0) {
      return message.channel.send("🎣 You haven’t caught any fish yet! Go fishing with `!fish` 🌸");
    }

    // Format fish list
    const fishList = Object.entries(user.caught)
      .map(([fish, count]) => `**${fish}**: ${count}`)
      .join("\n");

    // Create embed
    const embed = new EmbedBuilder()
      .setTitle(`🎣 ${message.author.username}'s Fish Collection`)
      .setDescription(fishList)
      .setColor("#FFB6C1")
      .setFooter({ text: `Total Coins: ${user.coins}💰 | Level: ${user.level}` })
      .setTimestamp();

    message.channel.send({ embeds: [embed] });
  },
};
