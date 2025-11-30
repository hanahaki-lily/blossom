import fs from "fs";
import path from "path";
import { EmbedBuilder } from "discord.js";

const levelsFile = path.join(process.cwd(), "data/levels.json");

export default {
  name: "leaderboard",
  description: "Show the top 10 users by chat level",
  execute: (message) => {
    if (!fs.existsSync(levelsFile)) fs.writeFileSync(levelsFile, "{}");

    const data = JSON.parse(fs.readFileSync(levelsFile, "utf8"));
    const sorted = Object.entries(data)
      .sort(([, a], [, b]) => b.level - a.level || b.xp - a.xp)
      .slice(0, 10);

    if (sorted.length === 0)
      return message.channel.send("No users have earned XP yet! 🌸");

    const leaderboard = sorted
      .map(
        ([id, u], i) =>
          `**${i + 1}.** <@${id}> — Level ${u.level} (${u.xp} XP)`
      )
      .join("\n");

    const embed = new EmbedBuilder()
      .setTitle("🌸 Blossom's Chat Leaderboard")
      .setDescription(leaderboard)
      .setColor("#ffc1cc")
      .setTimestamp();

    message.channel.send({ embeds: [embed] });
  },
};

