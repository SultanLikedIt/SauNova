import { UserDocument } from "./mongodb/m_user";
import { SessionDocument } from "./mongodb/m_session";
import { Badge, getRandomBadges } from "./mock/data";

export interface Friend {
  id: string;
  name: string;
  image: string | null;
  status: "online" | "offline" | "in sauna";
  badges: Badge[];
}

export function getMockFriends(): Friend[] {
  const friendCount = Math.floor(Math.random() * 8) + 3;
  const friends: Friend[] = [];
  const statuses: Friend["status"][] = ["online", "offline", "in sauna"];

  for (let i = 0; i < friendCount; i++) {
    const badgeCount = Math.floor(Math.random() * 5) + 1;
    friends.push({
      id: `friend_${i + 1}`,
      name: `Friend ${i + 1}`,
      image: "https://picsum.photos/200/300?seed=" + (i + 1),
      status: statuses[Math.floor(Math.random() * statuses.length)],
      badges: getRandomBadges(badgeCount),
    });
  }

  return friends;
}

export interface ResUser {
  user: UserDocument;
  sessions: SessionDocument[];
  badges: Badge[];
  friends: Friend[];
}
