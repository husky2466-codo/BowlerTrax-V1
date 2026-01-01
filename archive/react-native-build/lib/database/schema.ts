/**
 * SQLite Database Schema
 * Tables for sessions, shots, centers, calibrations, and ball profiles
 */

export const CREATE_TABLES_SQL = `
  -- Bowling centers
  CREATE TABLE IF NOT EXISTS centers (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT,
    laneCount INTEGER,
    oilPattern TEXT,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL
  );

  -- Calibration profiles (per lane per center)
  CREATE TABLE IF NOT EXISTS calibrations (
    id TEXT PRIMARY KEY,
    centerId TEXT,
    laneNumber INTEGER,
    name TEXT NOT NULL,
    pixelsPerFoot REAL NOT NULL,
    pixelsPerBoard REAL NOT NULL,
    foulLineY INTEGER NOT NULL,
    arrowY INTEGER NOT NULL,
    laneLeftX INTEGER NOT NULL,
    laneRightX INTEGER NOT NULL,
    createdAt TEXT NOT NULL,
    FOREIGN KEY (centerId) REFERENCES centers(id)
  );

  -- Ball color profiles
  CREATE TABLE IF NOT EXISTS ballProfiles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT,
    colorHue INTEGER NOT NULL,
    colorSaturation INTEGER NOT NULL,
    colorValue INTEGER NOT NULL,
    colorTolerance INTEGER DEFAULT 15,
    createdAt TEXT NOT NULL
  );

  -- Bowling sessions
  CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    centerId TEXT,
    calibrationId TEXT,
    ballProfileId TEXT,
    name TEXT,
    laneNumber INTEGER,
    oilPattern TEXT,
    isLeague INTEGER DEFAULT 0,
    startTime TEXT NOT NULL,
    endTime TEXT,
    notes TEXT,
    FOREIGN KEY (centerId) REFERENCES centers(id),
    FOREIGN KEY (calibrationId) REFERENCES calibrations(id),
    FOREIGN KEY (ballProfileId) REFERENCES ballProfiles(id)
  );

  -- Individual shots
  CREATE TABLE IF NOT EXISTS shots (
    id TEXT PRIMARY KEY,
    sessionId TEXT NOT NULL,
    shotNumber INTEGER NOT NULL,
    timestamp TEXT NOT NULL,

    -- Speed metrics
    launchSpeedMph REAL,
    impactSpeedMph REAL,

    -- Position metrics (in boards)
    foulLineBoard REAL,
    arrowBoard REAL,
    breakpointBoard REAL,
    breakpointDistance REAL,
    pocketBoard REAL,
    pocketOffset REAL,

    -- Angle metrics
    entryAngle REAL,
    launchAngle REAL,

    -- Rev rate
    revRate INTEGER,
    revCategory TEXT,

    -- Result
    result TEXT,
    pinsLeft TEXT,
    strikeProbability REAL,

    -- Video reference
    videoPath TEXT,
    thumbnailPath TEXT,

    FOREIGN KEY (sessionId) REFERENCES sessions(id)
  );

  -- Create indexes for common queries
  CREATE INDEX IF NOT EXISTS idx_shots_session ON shots(sessionId);
  CREATE INDEX IF NOT EXISTS idx_sessions_center ON sessions(centerId);
  CREATE INDEX IF NOT EXISTS idx_calibrations_center ON calibrations(centerId);
`;

export const DROP_TABLES_SQL = `
  DROP TABLE IF EXISTS shots;
  DROP TABLE IF EXISTS sessions;
  DROP TABLE IF EXISTS ballProfiles;
  DROP TABLE IF EXISTS calibrations;
  DROP TABLE IF EXISTS centers;
`;
