CREATE TABLE tblAuthentication (
    iUserId INTEGER PRIMARY KEY AUTOINCREMENT,
    sEmail TEXT UNIQUE NOT NULL,
    sPasswordHash TEXT NOT NULL,
    sDisplayName TEXT,
    sPhotoUrl TEXT,
    sPhoneNumber TEXT UNIQUE,
    bEmailVerified BOOLEAN DEFAULT 0,
    dCreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dLastLogin TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tblLogs (
    iLogId INTEGER PRIMARY KEY AUTOINCREMENT,
    dDate DATE NOT NULL,
    tTime TIME NOT NULL,
    rAverageDelta REAL NOT NULL,
    rPerCompleted REAL NOT NULL
);

CREATE TABLE tblParameter (
    iParamId INTEGER PRIMARY KEY,
    sName TEXT NOT NULL,
    sDesc TEXT,
    sUnit TEXT,
    rRef REAL,
    rMin REAL,
    rMax REAL,
    rDef REAL,
    dCreated DATE,
    dModified DATE,
    sLastUser TEXT,
    sUniqueRep TEXT,
    UNIQUE (sName)
);

CREATE TABLE tblPost (
    iPostId INTEGER PRIMARY KEY,
    sName TEXT NOT NULL,
    sDesc TEXT,
    dCreated DATE,
    dModified DATE,
    sLastUser TEXT,
    UNIQUE (sName)
);

CREATE TABLE tblVariable (
    iVarId INTEGER NOT NULL,
    iParamId INTEGER NOT NULL,
    iPostId INTEGER NOT NULL,
    sSourceName TEXT,
    dCreated DATE,
    dModified DATE,
    sLastUser TEXT,
    sUniqueRep TEXT,
    CONSTRAINT constraintVariable UNIQUE (iParamId, iPostId) ON CONFLICT REPLACE,
    PRIMARY KEY (iVarId),
    FOREIGN KEY (iParamId) REFERENCES tblParameter(iParamId) ON DELETE CASCADE,
    FOREIGN KEY (iPostId) REFERENCES tblPost(iPostId) ON DELETE CASCADE
);

CREATE TABLE tblDataInbox (
    dTimestamp DATE NOT NULL,
    iSiteId INTEGER NOT NULL,
    iObjectId INTEGER NOT NULL,
    iUserId INTEGER NOT NULL,
    rValue REAL,
    sValue TEXT DEFAULT NULL,
    jsValue TEXT DEFAULT NULL,
    uValue INTEGER DEFAULT NULL,
    iValue INTEGER DEFAULT NULL,
    UNIQUE(dTimestamp, iSiteId, iObjectId) ON CONFLICT REPLACE,
    FOREIGN KEY (iSiteId) REFERENCES tblSite(iSiteId)
);

CREATE TABLE tblSite (
    iSiteId INTEGER PRIMARY KEY,
    sLanguage TEXT,
    sFederalId TEXT,
    jsContactDetails TEXT,
    sStepName TEXT,
    sSiteName TEXT,
    jsBasicInfo TEXT,
    jsSpecificCtes TEXT,
    jsDocList TEXT,
    jsMailAddressList TEXT,
    jsNotes TEXT,
    sMemoNote TEXT
);
