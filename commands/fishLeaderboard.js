import fs from "fs";
import path from "path";

const fishingFile = path.join(process.cwd(), "data/fishing.json");

export default {
  name: "fishleaderboard",
  description: "Show top fishers",
  execute: (message) => {
    const data = JSON.parse(fs.readFileSync(fishingFile, "utf8"));

    const sorted = Object.entries(data)
      .sort(([, a], [, b]) => b.level - a.level || b.xp - a.xp)
      .slice(0, 10);

    if (sorted.length === 0) {
      return message.channel.send("No one has gone fishing yet! 🌸");
    }

    const leaderboard = sorted
      .map(
        ([id, u], i) =>
          `**${i + 1}.** <@${id}> — Level ${u.level} (${u.xp} XP, ${u.coins}💰)`
      )
      .join("\n");

    message.channel.send(`🎣 **Fishing Leaderboard**\n\n${leaderboard}`);
  },
};
