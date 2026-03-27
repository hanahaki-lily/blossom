# ==========================================
# DATA: Seasonal Events
# DESCRIPTION: Configuration for the Spring Carnival.
# ==========================================

SPRING_CARNIVAL = {
  name: "🎪 Spring Carnival",
  month: 4,
  currency: "Carnival Tickets",
  emoji: "🎟️",
  characters: {
    rare: [
      { name: "Rainbow Sparkles", gif: "https://media.discordapp.net/attachments/1485541740872994817/1485541810142056558/G8_fL5ZXcAAzQud.jfif?ex=69c7841f&is=69c6329f&hm=72fd932bd3d72a4bc340d1c0ed82269272de14c912a79b5a77529e42a330fd68&=&format=webp&width=662&height=856", price: 800 },
      { name: "Toma", gif: "https://media.discordapp.net/attachments/1485541740872994817/1485541811345817692/Toma_by_klaeia.webp?ex=69c7841f&is=69c6329f&hm=175511adab1cc611749ad9714fb8943f96b40098cb5b7518a77b04930282dcf5&=&format=webp&width=558&height=855", price: 800 }
    ],
    legendary: [
      { name: "EmieVT", gif: "https://media.discordapp.net/attachments/1485541740872994817/1485541809185620119/Dndntic_Emie.webp?ex=69c7841f&is=69c6329f&hm=252e2d9e14d82a8606841b4771f3e487ea68ad78ad800c03d0b0341ecc908f60&=&format=webp&width=643&height=856", price: 1500 },
      { name: "Necronival", gif: "https://media.discordapp.net/attachments/1485541740872994817/1485541810540646400/HEDB4i9a8AAGhOp.jfif?ex=69c7841f&is=69c6329f&hm=0e74376569b6db306a39b7a976a75d38f267808ff4136ad2141d7d9567296b08&=&format=webp&width=550&height=855", price: 1500 },
      { name: "Umaru Polka", gif: "https://media.discordapp.net/attachments/1485541740872994817/1485541810989305957/Omaru.Polka.600.3540629.jpg?ex=69c7841f&is=69c6329f&hm=3eea60a55660ce7f31082bcd72931800a3b9461524a68d969b5b72f31e09a3a8&=&format=webp&width=553&height=855", price: 1500 }
    ]
  },
  items: {
    'Cotton Candy' => { price: 50, desc: 'A sweet carnival treat!' },
    'Candy Apple' => { price: 75, desc: 'Crunchy and sweet!' }
  }
}.freeze