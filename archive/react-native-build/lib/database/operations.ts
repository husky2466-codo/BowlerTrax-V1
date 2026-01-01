/**
 * Database Operations
 * CRUD operations for all entities
 */

import * as SQLite from 'expo-sqlite';
import { CREATE_TABLES_SQL, DROP_TABLES_SQL } from './schema';
import type { Session, Shot, Center, CalibrationProfile, BallProfile } from '@/types';

let db: SQLite.SQLiteDatabase | null = null;

/**
 * Initialize database connection and create tables
 */
export async function initDatabase(): Promise<void> {
  if (db) return;

  db = await SQLite.openDatabaseAsync('bowlertrax.db');
  await db.execAsync(CREATE_TABLES_SQL);
}

/**
 * Close database connection
 */
export async function closeDatabase(): Promise<void> {
  if (db) {
    await db.closeAsync();
    db = null;
  }
}

/**
 * Reset database (drop and recreate tables)
 * WARNING: This deletes all data
 */
export async function resetDatabase(): Promise<void> {
  if (!db) await initDatabase();
  await db!.execAsync(DROP_TABLES_SQL);
  await db!.execAsync(CREATE_TABLES_SQL);
}

// ============ Sessions ============

export async function saveSession(session: Session): Promise<void> {
  if (!db) await initDatabase();

  await db!.runAsync(
    `INSERT OR REPLACE INTO sessions
     (id, centerId, calibrationId, ballProfileId, name, laneNumber, oilPattern, isLeague, startTime, endTime, notes)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      session.id,
      session.centerId ?? null,
      session.calibrationId ?? null,
      session.ballProfileId ?? null,
      session.name ?? null,
      session.lane ?? null,
      session.oilPattern ?? null,
      session.isLeague ? 1 : 0,
      session.startTime,
      session.endTime ?? null,
      session.notes ?? null,
    ]
  );
}

export async function getSessions(limit: number = 50): Promise<Session[]> {
  if (!db) await initDatabase();

  const results = await db!.getAllAsync<Session>(
    `SELECT * FROM sessions ORDER BY startTime DESC LIMIT ?`,
    [limit]
  );

  return results;
}

export async function getSession(id: string): Promise<Session | null> {
  if (!db) await initDatabase();

  const result = await db!.getFirstAsync<Session>(
    `SELECT * FROM sessions WHERE id = ?`,
    [id]
  );

  return result;
}

export async function deleteSession(id: string): Promise<void> {
  if (!db) await initDatabase();

  // Delete shots first (foreign key)
  await db!.runAsync(`DELETE FROM shots WHERE sessionId = ?`, [id]);
  await db!.runAsync(`DELETE FROM sessions WHERE id = ?`, [id]);
}

// ============ Shots ============

export async function saveShot(shot: Shot): Promise<void> {
  if (!db) await initDatabase();

  await db!.runAsync(
    `INSERT OR REPLACE INTO shots
     (id, sessionId, shotNumber, timestamp, launchSpeedMph, impactSpeedMph,
      foulLineBoard, arrowBoard, breakpointBoard, breakpointDistance, pocketBoard, pocketOffset,
      entryAngle, launchAngle, revRate, revCategory, result, pinsLeft, strikeProbability,
      videoPath, thumbnailPath)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      shot.id,
      shot.sessionId,
      shot.shotNumber,
      shot.timestamp,
      shot.launchSpeed ?? null,
      shot.impactSpeed ?? null,
      shot.foulLineBoard ?? null,
      shot.arrowBoard ?? null,
      shot.breakpointBoard ?? null,
      shot.breakpointDistance ?? null,
      shot.pocketBoard ?? null,
      shot.pocketOffset ?? null,
      shot.entryAngle ?? null,
      shot.launchAngle ?? null,
      shot.revRate ?? null,
      shot.revCategory ?? null,
      shot.result ?? null,
      shot.pinsLeft ?? null,
      shot.strikeProbability ?? null,
      shot.videoPath ?? null,
      shot.thumbnailPath ?? null,
    ]
  );
}

export async function getShots(sessionId: string): Promise<Shot[]> {
  if (!db) await initDatabase();

  const results = await db!.getAllAsync<Shot>(
    `SELECT * FROM shots WHERE sessionId = ? ORDER BY shotNumber ASC`,
    [sessionId]
  );

  return results;
}

export async function getShot(id: string): Promise<Shot | null> {
  if (!db) await initDatabase();

  const result = await db!.getFirstAsync<Shot>(
    `SELECT * FROM shots WHERE id = ?`,
    [id]
  );

  return result;
}

// ============ Centers ============

export async function saveCenter(center: Center): Promise<void> {
  if (!db) await initDatabase();

  const now = new Date().toISOString();
  await db!.runAsync(
    `INSERT OR REPLACE INTO centers
     (id, name, address, laneCount, oilPattern, createdAt, updatedAt)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [
      center.id,
      center.name,
      center.address ?? null,
      center.laneCount ?? null,
      center.defaultOilPattern ?? null,
      now,
      now,
    ]
  );
}

export async function getCenters(): Promise<Center[]> {
  if (!db) await initDatabase();

  const results = await db!.getAllAsync<Center>(
    `SELECT * FROM centers ORDER BY name ASC`
  );

  return results;
}

// ============ Calibrations ============

export async function saveCalibration(calibration: CalibrationProfile): Promise<void> {
  if (!db) await initDatabase();

  await db!.runAsync(
    `INSERT OR REPLACE INTO calibrations
     (id, centerId, laneNumber, name, pixelsPerFoot, pixelsPerBoard,
      foulLineY, arrowY, laneLeftX, laneRightX, createdAt)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      calibration.id,
      calibration.centerId ?? null,
      calibration.laneNumber ?? null,
      calibration.centerName,
      calibration.pixelsPerFoot,
      calibration.pixelsPerBoard,
      calibration.foulLineY,
      calibration.arrowsY,
      calibration.leftGutterX,
      calibration.rightGutterX,
      calibration.createdAt,
    ]
  );
}

export async function getCalibrations(): Promise<CalibrationProfile[]> {
  if (!db) await initDatabase();

  const results = await db!.getAllAsync<any>(
    `SELECT * FROM calibrations ORDER BY createdAt DESC`
  );

  // Transform to CalibrationProfile shape
  return results.map(row => ({
    id: row.id,
    centerId: row.centerId,
    centerName: row.name,
    laneNumber: row.laneNumber,
    pixelsPerFoot: row.pixelsPerFoot,
    pixelsPerBoard: row.pixelsPerBoard,
    foulLineY: row.foulLineY,
    arrowsY: row.arrowY,
    leftGutterX: row.laneLeftX,
    rightGutterX: row.laneRightX,
    createdAt: row.createdAt,
  }));
}

// ============ Ball Profiles ============

export async function saveBallProfile(profile: BallProfile): Promise<void> {
  if (!db) await initDatabase();

  await db!.runAsync(
    `INSERT OR REPLACE INTO ballProfiles
     (id, name, brand, colorHue, colorSaturation, colorValue, colorTolerance, createdAt)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      profile.id,
      profile.name,
      profile.brand ?? null,
      profile.color.h,
      profile.color.s,
      profile.color.v,
      profile.colorTolerance ?? 15,
      new Date().toISOString(),
    ]
  );
}

export async function getBallProfiles(): Promise<BallProfile[]> {
  if (!db) await initDatabase();

  const results = await db!.getAllAsync<any>(
    `SELECT * FROM ballProfiles ORDER BY name ASC`
  );

  return results.map(row => ({
    id: row.id,
    name: row.name,
    brand: row.brand,
    color: {
      h: row.colorHue,
      s: row.colorSaturation,
      v: row.colorValue,
    },
    colorTolerance: row.colorTolerance,
  }));
}

export async function deleteBallProfile(id: string): Promise<void> {
  if (!db) await initDatabase();
  await db!.runAsync(`DELETE FROM ballProfiles WHERE id = ?`, [id]);
}
