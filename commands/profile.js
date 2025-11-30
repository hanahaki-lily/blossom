import fs from "fs";
import path from "path";
import { EmbedBuilder } from "discord.js";

const chatFile = path.join(process.cwd(), "data/levels.json");
const fishingFile = path.join(process.cwd(), "data/fishing.json");

export default {
  name: "profile",
  description: "Show your chat & fishing levels and coins",
  execute: (message) => {
    const userId = message.author.id;

    const chatData = fs.existsSync(chatFile)
      ? JSON.parse(fs.readFileSync(chatFile, "utf8"))
      : {};
    const chatUser = chatData[userId] || { level: 0, xp: 0 };

    const fishData = fs.existsSync(fishingFile)
      ? JSON.parse(fs.readFileSync(fishingFile, "utf8"))
      : {};
    const fishUser = fishData[userId] || { level: 0, xp: 0, coins: 0 };

    const embed = new EmbedBuilder()
      .setTitle(`🌸 ${message.author.username}'s Profile`)
      .setColor("#ffc1cc")
      .setThumbnail(message.author.displayAvatarURL({ dynamic: true }))
      .addFields(
        {
          name: "💬 Chat Level",
          value: `Level: ${chatUser.level}\nXP: ${chatUser.xp} / ${
            chatUser.level * 100
          }`,
          inline: true,
        },
        {
          name: "🎣 Fishing Level",
          value: `Level: ${fishUser.level}\nXP: ${fishUser.xp} / ${
            fishUser.level * 100
          }\nCoins: ${fishUser.coins}💰`,
          inline: true,
        }
      )
      .setTimestamp();

    message.channel.send({ embeds: [embed] });
  },
};
