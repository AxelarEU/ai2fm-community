---
title: "Execute_SQL_Example_1_2025"
---

# Execute_SQL_Example_1_2025

[← Execute SQL](execute-sql.html) · <a href="Execute_SQL_Example_1_2025.fmscript" download>Download Execute_SQL_Example_1_2025.fmscript</a>

```fmscript
# ============================================
# Execute SQL — Example 1, FileMaker 2025. CREATE TABLE — a table and its fields, from SQL.
# The same statement as Example 1, within FileMaker 2025's limits: no relationship.
# Captured from: Execute_SQL_Example_2025_v1_0.fmp12
# ============================================

# 🔑 THE EXAMPLES ARE COMPLETE CRUD. Examples 1-8 create, change and remove. Example 9
# reads one row with the ExecuteSQL calculation function. Example 12 removes the example table.
# Import Records from ODBC is the separate path for importing an external query result as records.

# 🚨 RUN THIS ONCE PER SET. A table with the same name must not already exist, so a second run
# fails — until Example 12 drops the table, which lets the set start again from here.

# 🔑 THE NAMES ARE ALL IN DOUBLE QUOTES. A name that does not begin with a letter — `__pk…`,
# `_fk…`, `_static…` — must be a quoted identifier. The rest are quoted for consistency.
# ============================================

Enter Browse Mode [ Pause: Off ]

# ⚠️ With error capture on, FileMaker shows no alert of its own. Every dialog below is the
# script's own, built from the two error values captured after the step.
Set Error Capture [ On ]

# 🔑 odbcSelf2025 IS A SYSTEM DSN THAT POINTS BACK AT THIS FILE, through FileMaker's own
# ODBC driver. Execute SQL talks to ODBC data sources, not to FileMaker files — so the file
# reaches itself as one.

# ⚠️ `With dialog: Off` NEEDS `Save credentials: On`. Nothing can prompt for a user name or
# password, so the credentials have to be stored with the step.

# 🔑 BOTH CREDENTIALS ARE NOT QUOTED — Admin, admin. User Name and Password are LITERAL TEXT and
# are not enclosed in quotes.

# 🔑 THE FOREIGN KEY CANNOT BE USED TO BUILD A RELATIONSHIP AT FileMaker 2025 - 22 AND EARLIER
# _fkCustomerID is created as a Number to be used in the rest of the example scripts

# ℹ️ `DEFAULT` takes a constant or one of the named values: CURRENT_USER, CURRENT_DATE,
# CURRENT_TIME, CURRENT_TIMESTAMP. A constant becomes auto-enter data — `DEFAULT 1` is
# Auto-enter: "1" on `_staticOne`.

# 🔑 THE SCALE BECOMES A TRUNCATE. `NUMERIC(2,2)` and `DECIMAL(2,3)` make Number fields with an
# auto-enter calculation that replaces the existing value:
#    Percentage_1   Truncate ( Percentage_1 ; 2 )
#    Percentage_2   Truncate ( Percentage_2 ; 3 )
# ⚠️ TRUNCATED, NOT ROUNDED — 0.129 stored in Percentage_1 becomes 0.12. Only the scale (the
# second number) is carried; the precision (the first) sets nothing.

# ℹ️ `VARCHAR(20)` becomes a validation, "Maximum number of characters = 20". Bare `VARCHAR`
# sets no limit.

# ⚠️ SQL HAS NO MODIFICATION DEFAULT. `DEFAULT` fills a value once, when the record is created —
# so ModificationDate, ModificationTime and ModificationTimestamp are created as plain Date, Time
# and Timestamp fields. Their modification auto-enter has to be set by hand in Manage Database.

# ℹ️ Photo_1-4 use the four binary type names — BLOB, VARBINARY, LONGVARBINARY, BINARY VARYING.
# Each one makes a container field, stored in the file.

# 🔑 Photo_5, Photo_6 AND Photo_7 STORE EXTERNALLY. `EXTERNAL '<path>'` names the folder, relative
# to the file's own location, and then one of:
#    OPEN '<folder>'          open storage, in that folder inside the path
#    SECURE                   secure storage
#    SECURE FEWER_FOLDERS     secure storage, "With fewer folders"

# 🚨 THE PATH MUST ALREADY BE A BASE DIRECTORY IN MANAGE CONTAINERS, or the step fails with
# 1408 and ODBC 8315, "Invalid container base directory specified". Here it is
# [database location]/Execute_SQL_Example_2025_v1_0/ — so the SQL says
# 'Execute_SQL_Example_2025_v1_0/', with no leading folder. The path uses forward slashes.
Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2025;
    User Name: Admin;
    Password: admin;
    Save credentials: On;
    SQL Text:
        CREATE TABLE "CustomerContactsSQL"
        ("__pkCustomerContactID" INT PRIMARY KEY,
        "_fkCustomerID" INT,
        "_staticOne" NUMERIC DEFAULT 1,
        "_staticZero" NUMERIC DEFAULT 0,
        "CreatedBy" VARCHAR DEFAULT CURRENT_USER,
        "CreationDate" DATE DEFAULT CURRENT_DATE,
        "CreationTime" TIME DEFAULT CURRENT_TIME,
        "CreationTimestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        "ModificationDate" DATE,
        "ModificationTime" TIME,
        "ModificationTimestamp" TIMESTAMP,
        "Percentage_1" NUMERIC(2,2),
        "Percentage_2" DECIMAL(2,3),
        "FirstName" VARCHAR(20),
        "LastName" VARCHAR,
        "Company" VARCHAR,
        "Street" VARCHAR,
        "City" VARCHAR,
        "State" VARCHAR(2),
        "Zip" VARCHAR,
        "Photo_1" BLOB,
        "Photo_2" VARBINARY,
        "Photo_3" LONGVARBINARY,
        "Photo_4" BINARY VARYING,
        "Photo_5" BLOB EXTERNAL 'Execute_SQL_Example_2025_v1_0/' OPEN 'CustomerContactsSQL/Photo_5/',
        "Photo_6" BLOB EXTERNAL 'Execute_SQL_Example_2025_v1_0/' SECURE,
        "Photo_7" BLOB EXTERNAL 'Execute_SQL_Example_2025_v1_0/' SECURE FEWER_FOLDERS)
    ]
# ------------------------------------------------------
# Check for errors and log if needed
# ------------------------------------------------------
# 🔑 BOTH ERROR VALUES, CAPTURED IN ONE STEP. Get ( LastError ) is FileMaker's code;
# Get ( LastErrorDetail ) is the ODBC state — the driver's own reason, which the code alone does
# not give. Reading both inside one Let means the second read cannot see a reset value.

# ℹ️ $noError is never set. The Let's result is thrown away; only its two assignments matter.
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

    # ⚠️ SQL MAKES THE TABLE AND ITS OCCURRENCE — NEVER A LAYOUT, AND IN 2025 NO RELATIONSHIP.
    # This layout already exists in the file; the dialog below asks you to point it at the new
    # occurrence and place the new fields, so Manage Layouts opens, then Manage Database.
    Go to Layout [ “CustomerContactsSQL” (CustomerContactsSQL) ]

    Show Custom Dialog [
        Title: "SQL Action Status";
        Message: "The table CustomerContactsSQL was created successfully."
        & ¶ &
        "Please create the relationship of _fkCustomerID to Customers"
        & ¶ &
        " and add the Table Fields to the Layout.";
        Default Button: "OK", Commit: "Yes"
    ]

    Open Manage Layouts

    Open Manage Database

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```
