export interface Badge {
  id: string;
  name: string;
  description: string;
  icon: string;
  requirement: number;
  rarity: "common" | "rare" | "epic" | "legendary";
}

const allBadges: Badge[] = [
  {
    id: "1",
    name: "First Steam",
    description: "Complete your first sauna session",
    icon: "♨️",
    requirement: 1,
    rarity: "common",
  },
  {
    id: "2",
    name: "Early Steam",
    description: "Use the sauna before 7 AM",
    icon: "🌅",
    requirement: 5,
    rarity: "common",
  },
  {
    id: "3",
    name: "Night Heat",
    description: "Use the sauna after 10 PM",
    icon: "🦉",
    requirement: 5,
    rarity: "common",
  },
  {
    id: "4",
    name: "Weekly Ritual",
    description: "Complete 7 consecutive sauna days",
    icon: "🔥",
    requirement: 7,
    rarity: "rare",
  },
  {
    id: "5",
    name: "Century Steamer",
    description: "Complete 100 sauna sessions",
    icon: "💯",
    requirement: 100,
    rarity: "epic",
  },
  {
    id: "6",
    name: "Iron Heat",
    description: "Use the sauna 30 days in a row",
    icon: "💪",
    requirement: 30,
    rarity: "epic",
  },
  {
    id: "7",
    name: "Quick Steam",
    description: "Finish a sauna session in under 10 minutes",
    icon: "⚡",
    requirement: 1,
    rarity: "rare",
  },
  {
    id: "8",
    name: "Year of Heat",
    description: "Use the sauna every day for a year",
    icon: "🏆",
    requirement: 365,
    rarity: "legendary",
  },
  {
    id: "9",
    name: "Social Steamer",
    description: "Share a sauna session with 10 different friends",
    icon: "🦋",
    requirement: 10,
    rarity: "rare",
  },
  {
    id: "10",
    name: "Perfect Temp",
    description: "Complete 50 sauna sessions at optimal temperature",
    icon: "⭐",
    requirement: 50,
    rarity: "epic",
  },
  {
    id: "11",
    name: "Humid Master",
    description: "Maintain optimal humidity in 25 sessions",
    icon: "💧",
    requirement: 25,
    rarity: "epic",
  },
  {
    id: "12",
    name: "Long Steam",
    description: "Spend 60 minutes in the sauna in a single session",
    icon: "⏱️",
    requirement: 1,
    rarity: "rare",
  },
  {
    id: "13",
    name: "Daily Devotee",
    description: "Use the sauna 14 consecutive days",
    icon: "📅",
    requirement: 14,
    rarity: "rare",
  },
  {
    id: "14",
    name: "High Heat Hero",
    description: "Reach 90°C in 20 sessions",
    icon: "🔥",
    requirement: 20,
    rarity: "epic",
  },
  {
    id: "15",
    name: "Chill Beginner",
    description: "Start a sauna session at lower temperature (≤60°C)",
    icon: "❄️",
    requirement: 5,
    rarity: "common",
  },
  {
    id: "16",
    name: "Temperature Explorer",
    description: "Experience 10 different temperature ranges",
    icon: "🌡️",
    requirement: 10,
    rarity: "rare",
  },
  {
    id: "17",
    name: "Humidity Explorer",
    description: "Experience 10 different humidity levels",
    icon: "💦",
    requirement: 10,
    rarity: "rare",
  },
  {
    id: "18",
    name: "Steam Duo",
    description: "Complete 50 sessions with a friend",
    icon: "🤝",
    requirement: 50,
    rarity: "epic",
  },
  {
    id: "19",
    name: "Ultimate Streak",
    description: "Use the sauna 60 days in a row",
    icon: "🏅",
    requirement: 60,
    rarity: "legendary",
  },
  {
    id: "20",
    name: "Sauna Marathon",
    description: "Complete 500 sauna sessions",
    icon: "🥇",
    requirement: 500,
    rarity: "legendary",
  },
];

const get3RandomBadges = (badges: Badge[], count: number): Badge[] => {
  const shuffled = badges.sort(() => 0.5 - Math.random());
  return shuffled.slice(0, count);
};

export function getRandomBadges(count: number): Badge[] {
  return get3RandomBadges(allBadges, count);
}

export default allBadges;
