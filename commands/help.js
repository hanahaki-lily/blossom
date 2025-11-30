import fs from "fs";
import path from "path";
import { EmbedBuilder } from "discord.js";

export default {
  name: "help",
  description: "Show all available commands",
  execute: (message) => {
    const commandsPath = path.join(process.cwd(), "commands");
    const files = fs.readdirSync(commandsPath).filter(f => f.endsWith(".js"));

    // Load command names & descriptions dynamically
    const commandsList = files.map(file => {
      const command = require(path.join(commandsPath, file)).default;
      return `**!${command.name}** — ${command.description}`;
    });

    const embed = new EmbedBuilder()
      .setTitle("🌸 Blossom's Commands")
      .setDescription(commandsList.join("\n"))
      .setColor("#ffc1cc")
      .setTimestamp();

    message.channel.send({ embeds: [embed] });
  },
};
