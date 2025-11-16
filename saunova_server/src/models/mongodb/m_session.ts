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
class Session extends TimeStamps {
  @prop({ required: true })
  userID!: string;

  @prop({ required: true })
  durationSeconds!: number;

  @prop({ required: true })
  temperatureC!: number;

  @prop({ required: true })
  humidityPercent!: number;

  @prop({ required: true })
  startedAt!: Date;

  @prop({ required: true })
  stoppedAt!: Date;

  @prop({ required: true })
  brief!: string;

  @prop({ required: true })
  axis_data!: any;

  static async createSession(
    this: ReturnModelType<typeof Session>,
    userID: string,
    durationSeconds: number,
    humidityPercent: number,
    startedAt: Date,
    stoppedAt: Date,
    temperatureC: number,
    brief: string,
    axis_data: any
  ): Promise<SessionDocument> {
    const session = new this({
      userID,
      durationSeconds,
      humidityPercent,
      startedAt,
      stoppedAt,
      temperatureC,
      brief,
      axis_data,
    });
    return session.save();
  }

  static async findByUserID(
    this: ReturnModelType<typeof Session>,
    userID: string
  ): Promise<SessionDocument[]> {
    console.log("Finding sessions for userID:", userID);
    return this.find({ userID }).sort({ createdAt: -1 }).exec();
  }
}

export type SessionDocument = DocumentType<Session>;
export const SessionModel = getModelForClass(Session);
