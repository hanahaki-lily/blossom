const fs = require("fs");

module.exports = {
    name: "interactionCreate",
    async execute(interaction) {
        if (!interaction.isButton()) return;

        if (interaction.customId.startsWith("hugback_")) {
            const [, originalHugger, originalReceiver] = interaction.customId.split("_");

            const hugger = interaction.user;

            // Hug back can only be pressed by the receiver
            if (hugger.id !== originalReceiver) {
                return interaction.reply({ content: "Only the hugged person can hug back 💞", ephemeral: true });
            }

            // Load data
            let hugData = {};
            if (fs.existsSync("./hugData.json")) {
                hugData = JSON.parse(fs.readFileSync("./hugData.json"));
            }

            // Add hug back count
            if (!hugData[hugger.id]) hugData[hugger.id] = 0;
            hugData[hugger.id] += 1;

            fs.writeFileSync("./hugData.json", JSON.stringify(hugData, null, 2));

            // Reply embed
            const embed = {
                color: 0xffc1cc,
                title: "💞 Hug Returned!",
                description: `**${hugger}** hugged <@${originalHugger}> back!`,
                fields: [
                    { name: "💗 Total Hugs Given", value: `${hugData[hugger.id]}`, inline: true }
                ],
                timestamp: new Date()
            };

            await interaction.reply({ embeds: [embed] });
        }
    }
};
