import fs from "fs";
import path from "path";

const levelsFile = path.join(process.cwd(), "data", "levels.json");
if (!fs.existsSync(levelsFile)) fs.writeFileSync(levelsFile, "{}");

let levels = JSON.parse(fs.readFileSync(levelsFile, "utf8"));

function saveLevels() {
  fs.writeFileSync(levelsFile, JSON.stringify(levels, null, 2));
}

export default {
  name: "messageCreate",
  execute: (client, message) => {
    if (message.author.bot) return;

    // XP gain for chat leveling
    const userId = message.author.id;
    const levelsFile = path.join(process.cwd(), "data/levels.json");
    let levels = JSON.parse(fs.readFileSync(levelsFile, "utf8"));
    if (!levels[userId]) levels[userId] = { xp: 0, level: 1 };

    const user = levels[userId];
    user.xp += Math.floor(Math.random() * 6) + 2;

    const nextLevelXP = user.level * 100;
    if (user.xp >= nextLevelXP) {
      user.level++;
      user.xp -= nextLevelXP;
      message.channel.send(`✨ ${message.author} leveled up to ${user.level}! 🌸`);
    }

    fs.writeFileSync(levelsFile, JSON.stringify(levels, null, 2));

    // **Command handling**
    if (!message.content.startsWith("!")) return;

    const args = message.content.slice(1).trim().split(/ +/);
    const commandName = args.shift().toLowerCase();
    const command = client.commands.get(commandName);

    if (command) command.execute(message, args);
  },
};

