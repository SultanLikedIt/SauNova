import {
  getModelForClass,
  prop,
  modelOptions,
  ReturnModelType,
  DocumentType,
  index,
} from "@typegoose/typegoose";
import { TimeStamps } from "@typegoose/typegoose/lib/defaultClasses";

@modelOptions({
  schemaOptions: { timestamps: true },
})
class User extends TimeStamps {
  @prop({ required: true, unique: true })
  firebaseID!: string;

  @prop({ required: true, unique: true })
  email!: string;

  @prop({ required: true })
  gender!: string;

  @prop({ required: true })
  height!: number;

  @prop({ required: true })
  weight!: number;

  @prop({ required: true })
  age!: number;

  @prop({ required: true, default: [String] })
  goals!: string[];

  @prop({ required: true, default: false })
  onboardingCompleted!: boolean;

  @prop({ required: true, default: null })
  image!: string | null;

  static async findByFirebaseID(
    this: ReturnModelType<typeof User>,
    firebaseID: string
  ): Promise<UserDocument | null> {
    return this.findOne({ firebaseID }).exec();
  }

  static async createUser(
    this: ReturnModelType<typeof User>,
    firebaseID: string,
    email: string,
    image: string | null
  ): Promise<UserDocument> {
    const user = new this({
      firebaseID,
      email,
      gender: "empty",
      height: 0,
      weight: 0,
      age: 0,
      goals: [],
      onboardingCompleted: false,
      image,
    });
    return user.save();
  }

  static async finishSetup(
    this: ReturnModelType<typeof User>,
    firebaseID: string,
    gender: string,
    height: number,
    weight: number,
    age: number,
    goals: string[]
  ): Promise<UserDocument | null> {
    return this.findOneAndUpdate(
      { firebaseID },
      { gender, height, weight, age, goals, onboardingCompleted: true },
      { new: true }
    ).exec();
  }

  static async setProfileImage(
    this: ReturnModelType<typeof User>,
    firebaseID: string,
    imageUrl: string | null
  ): Promise<void> {
    await this.findOneAndUpdate({ firebaseID }, { image: imageUrl }).exec();
  }

  static async createDemoUsers(
    this: ReturnModelType<typeof User>
  ): Promise<void> {
    const demoUsers = [];
    for (let i = 1; i <= 10; i++) {
      demoUsers.push(
        new this({
          firebaseID: `demo_user_${i}`,
          email: `demo_user_${i}@example.com`,
          gender: "empty",
          height: 0,
          weight: 0,
          age: 0,
          goals: [],
          onboardingCompleted: false,
          image: "https://picsum.photos/200/300",
        })
      );
    }
    await this.insertMany(demoUsers);
  }
}

export const UserModel = getModelForClass(User);
export type UserDocument = DocumentType<User>;
