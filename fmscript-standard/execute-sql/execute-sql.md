---
type: FileMaker Script Step
title: Execute SQL
description: Executes an SQL statement on an ODBC data source.
resource: https://fmscript.org/steps/execute-sql/
tags: [sql, odbc, schema]
timestamp: 2026-10-03T00:00:00Z
version: 2
standard_version: 0.4
category: Miscellaneous
tested_on: [22, 26]
step_id: 117
---

# Execute SQL

**Step ID 117** · Executes an SQL statement on an ODBC data source.

---

## Syntax

```fmscript
Execute SQL [
	With dialog: <On|Off> ;
	ODBC Data Source: <name> ;
	User Name: <calculation> ;
	Password: <calculation> ;
	Save credentials: <On|Off> ;
	SQL Text: <statement>
]
```

The step with nothing set:

```fmscript
Execute SQL [ With dialog: On ]
```

`SQL Text:` and `Calculated SQL Text:` are alternatives — a step has one or the other:

```fmscript
Execute SQL [ With dialog: Off ; ODBC Data Source: gemini ; User Name: "root" ; Password: 12345678 ; Save credentials: On ; Calculated SQL Text: myTable::myField ]
```

---

## Parameters

| Parameter | Required | Value | Default |
|---|---|---|---|
| `With dialog:` | **Yes** | enum(On\|Off) | — |
| `ODBC Data Source:` | No | text | — |
| `User Name:` | No | calculation | — |
| `Password:` | No | calculation | — |
| `Save credentials:` | No | enum(On\|Off) | — |
| `SQL Text:` | No | text | — |
| `Calculated SQL Text:` | No | calculation | — |

Parameters are separated by `;` and **must appear in the order listed above.**

`Save credentials:` is written whenever a data source is set.

`With dialog:` is always written. There is no `Execute SQL [ ]`.

---

## Data source and credentials

`ODBC Data Source:` names the DSN. The data source can be any ODBC source — including a FileMaker file, reached through a DSN that points at it.

`User Name:` and `Password:` are the login for that data source. In FileMaker 2026 both are calculations; in FileMaker 2025 and earlier both are plain text.

| written | FileMaker 2026 | FileMaker 2025 |
|---|---|---|
| `Admin` | the text `Admin` | the text `Admin` |
| `"Admin"` | the text `Admin` | the text `Admin` |
| `$user` | the value of `$user` | the text `$user` |
| `Get ( AccountName )` | the signed-in account's name | the text `Get ( AccountName )` |

A bare word is a name. A credential that contains a quote is written as an escaped string, for example `Password: "\"Iam#password"`.

`Save credentials:` records whether the user name and password are stored with the step.

---

## SQL Text and Calculated SQL Text

`SQL Text:` is the statement, written in the data source's own SQL. It may run over several lines.

```fmscript
SQL Text: UPDATE Employees SET Title = 'Manager' WHERE EmployeeID = 103
```

`Calculated SQL Text:` is a calculation whose result is the statement:

```fmscript
Calculated SQL Text: myTable::myField
Calculated SQL Text: "INSERT INTO dbo.TEMP_ITEM (CODE, NAME) Values (" & "'" & myTable::TypeID & "'"& "," & "'" & myTable::myField & "'" & ")"
```

In a calculated statement the double quotes are FileMaker's and delimit the text; the single quotes are SQL's and end up in the statement. A single quote inside a value is doubled for SQL: `Substitute ( $lastName ; "'" ; "''" )`.

---

## A FileMaker file as the data source

When the DSN points at a FileMaker file, the statements change that file's schema and records:

| SQL | result in the file |
|---|---|
| `CREATE TABLE` | a table and its table occurrence; no layout |
| `FOREIGN KEY REFERENCES "T"("pk")` | a relationship in the graph (FileMaker 2026); error 8201 if it would close a cycle |
| `DEFAULT 1` | auto-enter data `"1"` |
| `DEFAULT CURRENT_USER` · `CURRENT_DATE` · `CURRENT_TIME` · `CURRENT_TIMESTAMP` | auto-enter creation values; there is no modification default |
| `NUMERIC(2,2)` · `DECIMAL(2,3)` | a Number field with auto-enter `Truncate ( field ; scale )` |
| `VARCHAR(20)` | validation "Maximum number of characters = 20" |
| `BLOB` · `VARBINARY` · `LONGVARBINARY` · `BINARY VARYING` | a container field |
| `BLOB EXTERNAL '<path>' SECURE` · `OPEN '<folder>'` · `SECURE FEWER_FOLDERS` | an externally stored container field |
| `CREATE INDEX ON "T" ("f")` | Indexing Minimal (text) or All, and "Automatically create indexes as needed" |
| `DROP INDEX ON "T" ("f")` | Indexing None, "Automatically create indexes as needed" cleared |
| `ALTER TABLE … ADD COLUMN` · `DROP COLUMN` | a field added or removed, one per statement |
| `DROP TABLE` | the table and its records removed |

A name that does not begin with a letter is written in double quotes: `"__pkCustomerContactID"`.

The path of an external container is relative to the file and must already be a base directory in Manage Containers.

---

## Examples

Each example names its `.fmscript` file. They come from two FileMaker files published alongside this page:

```
Execute_SQL_Example_2026_v1_0.fmp12     examples 0 – 12
Execute_SQL_Example_2025_v1_0.fmp12     example 1, FileMaker 2025
```

⚠️ **The scripts on this page are shown with their comments removed.** The published `.fmscript` files are commented, and those comments are FileMaker comment steps: they travel into the Script Workspace with the script. **Read the `.fmscript` files for the reasoning.**

Examples 0 – 9 and 12 use a DSN that points at the file itself (`odbcSelf2026`, `odbcSelf2025`). Examples 10 and 11 use MariaDB (`gemini`), built by [fixtures/gemini_mariadb_fixture.sql](fixtures/gemini_mariadb_fixture.sql). Example 1 creates the table the others use, and Example 12 drops it.

### The step with nothing set

[Execute_SQL_Example_0.fmscript](Execute_SQL_Example_0.fmscript)

```fmscript
Execute SQL [ With dialog: On ]
Execute SQL [ With dialog: Off ]
```

### CREATE TABLE

[Execute_SQL_Example_1.fmscript](Execute_SQL_Example_1.fmscript)

A table with defaults, scaled numbers, containers, external containers and a foreign key.

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2026;
    User Name: "Admin";
    Password: "admin";
    Save credentials: On;
    SQL Text:
        CREATE TABLE "CustomerContactsSQL"
        ("__pkCustomerContactID" INT PRIMARY KEY,
        "_fkCustomerID" INT FOREIGN KEY REFERENCES "Customers"("__pkCustomerID"),
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
        "Photo_5" BLOB EXTERNAL 'Execute_SQL_Example_2026_v1_0/' OPEN 'CustomerContactsSQL/Photo_5/',
        "Photo_6" BLOB EXTERNAL 'Execute_SQL_Example_2026_v1_0/' SECURE,
        "Photo_7" BLOB EXTERNAL 'Execute_SQL_Example_2026_v1_0/' SECURE FEWER_FOLDERS)
    ]
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

Go to Layout [ “CustomerContactsSQL” (CustomerContactsSQL) ]

Show Custom Dialog [
    Title: "SQL Action Status";
    Message: "Table and customer relationship created successfully." & ¶ & 
             "Please assign the TO created to the Layout and add the Table Fields";
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

### CREATE TABLE, FileMaker 2025

[Execute_SQL_Example_1_2025.fmscript](Execute_SQL_Example_1_2025.fmscript)

The same table in FileMaker 2025: bare credentials, and `_fkCustomerID` a plain `INT` with no relationship.

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

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

Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

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

### INSERT

[Execute_SQL_Example_2.fmscript](Execute_SQL_Example_2.fmscript)

Ten records in one statement.

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2026;
    User Name: "Admin";
    Password: "admin";
    Save credentials: On;
    SQL Text:
        INSERT INTO "CustomerContactsSQL"
        ("__pkCustomerContactID", "_fkCustomerID", "FirstName", "LastName",
        "Company", "Street", "City", "State", "Zip")
        VALUES
        (1, 1, 'Anna', 'Meyer', 'Aster Systems', '12 Linden Street', 'Berlin', 'BE', '10115'),
        (2, 2, 'Nikos', 'Pappas', 'Attica Data', '25 Ermou Street', 'Athens', 'AT', '10563'),
        (3, 3, 'Sofia', 'Rossi', 'Forma Studio', '8 Via Roma', 'Rome', 'RM', '00184'),
        (4, 4, 'Lucas', 'Martin', 'Clair Solutions', '41 Rue Victor Hugo', 'Paris', 'PA', '75016'),
        (5, 5, 'Emma', 'Jensen', 'Nordic Works', '17 Havnegade', 'Copenhagen', 'CP', '1058'),
        (6, 6, 'Oliver', 'Smith', 'Bridge Software', '30 King Street', 'London', 'LD', 'SW1A 2AA'),
        (7, 7, 'Maria', 'Garcia', 'Iberia Services', '22 Calle Mayor', 'Madrid', 'MD', '28013'),
        (8, 8, 'Jan', 'Novak', 'Bohemia Labs', '14 Karlova', 'Prague', 'PR', '11000'),
        (9, 9, 'Eva', 'Kovacs', 'Danube Systems', '9 Vaci Street', 'Budapest', 'BU', '1052'),
        (10, 10, 'Lena', 'Andersson', 'Scandia Group', '6 Storgatan', 'Stockholm', 'ST', '11151')
    ]
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
        Title: "SQL Action Status";
        Message: "10 customer contact records inserted successfully.";
        Default Button: "OK", Commit: "Yes"
    ]

    Exit Script [ Result: 0 ]

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```

### UPDATE

[Execute_SQL_Example_3.fmscript](Execute_SQL_Example_3.fmscript)

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2026;
    User Name: "Admin";
    Password: "admin";
    Save credentials: On;
    SQL Text:
        UPDATE "CustomerContactsSQL"
        SET "Company" = 'Aster Systems GmbH',
        "Street" = '18 Friedrichstrasse',
        "City" = 'Berlin',
        "State" = 'BE',
        "Zip" = '10117'
        WHERE "__pkCustomerContactID" = 1
    ]
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
        Title: "SQL Action Status";
        Message: "Customer contact 1 updated successfully.";
        Default Button: "OK", Commit: "Yes"
    ]

    Exit Script [ Result: 0 ]

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```

### DELETE

[Execute_SQL_Example_4.fmscript](Execute_SQL_Example_4.fmscript)

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2026;
    User Name: "Admin";
    Password: "admin";
    Save credentials: On;
    SQL Text:
        DELETE FROM "CustomerContactsSQL"
        WHERE "__pkCustomerContactID" = 10
    ]
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
        Title: "SQL Action Status";
        Message: "Customer contact 10 deleted successfully.";
        Default Button: "OK", Commit: "Yes"
    ]

    Exit Script [ Result: 0 ]

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```

### CREATE INDEX

[Execute_SQL_Example_5.fmscript](Execute_SQL_Example_5.fmscript)

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2026;
    User Name: "Admin";
    Password: "admin";
    Save credentials: On;
    SQL Text:
        CREATE INDEX ON "CustomerContactsSQL" ("LastName")
    ]
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
        Title: "SQL Action Status";
        Message: "The LastName index was created successfully.";
        Default Button: "OK", Commit: "Yes"
    ]

    Open Manage Database

    Exit Script [ Result: 0 ]

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```

### DROP INDEX

[Execute_SQL_Example_6.fmscript](Execute_SQL_Example_6.fmscript)

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2026;
    User Name: "Admin";
    Password: "admin";
    Save credentials: On;
    SQL Text:
        DROP INDEX ON "CustomerContactsSQL" ("LastName")
    ]
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
        Title: "SQL Action Status";
        Message: "The LastName index was removed successfully.";
        Default Button: "OK", Commit: "Yes"
    ]

    Open Manage Database

    Exit Script [ Result: 0 ]

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```

### ALTER TABLE ADD COLUMN

[Execute_SQL_Example_7.fmscript](Execute_SQL_Example_7.fmscript)

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2026;
    User Name: "Admin";
    Password: "admin";
    Save credentials: On;
    SQL Text:
        ALTER TABLE "CustomerContactsSQL"
        ADD COLUMN "Email" VARCHAR(254)
    ]
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
        Title: "SQL Action Status";
        Message: "The Email field was added to CustomerContactsSQL successfully.";
        Default Button: "OK", Commit: "Yes"
    ]

    Open Manage Database

    Exit Script [ Result: 0 ]

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```

### ALTER TABLE DROP COLUMN

[Execute_SQL_Example_8.fmscript](Execute_SQL_Example_8.fmscript)

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2026;
    User Name: "Admin";
    Password: "admin";
    Save credentials: On;
    SQL Text:
        ALTER TABLE "CustomerContactsSQL"
        DROP COLUMN "Email"
    ]
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
        Title: "SQL Action Status";
        Message: "The Email field was removed from CustomerContactsSQL table successfully.";
        Default Button: "OK", Commit: "Yes"
    ]

    Open Manage Database

    Exit Script [ Result: 0 ]

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```

### Reading a record with the ExecuteSQL function

[Execute_SQL_Example_9.fmscript](Execute_SQL_Example_9.fmscript)

Execute SQL returns no rows; the record is read with the `ExecuteSQL` calculation function.

```fmscript
Set Variable [ $customerContact[1] ; Value: ExecuteSQL (
    "SELECT \"Company\", \"Street\", \"Zip\"
     FROM \"CustomerContactsSQL\"
     WHERE \"__pkCustomerContactID\" = ?" ;
    " | " ; ¶ ;
    1
) ]

If [ $customerContact = "?" ]

    Show Custom Dialog [
        Title: "SQL Query Error";
        Message: "ExecuteSQL returned ?. Check the table, field names, and query syntax.";
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]

Else

    Show Custom Dialog [
        Title: "Customer Contact 1";
        Message: $customerContact;
        Default Button: "OK", Commit: "Yes"
    ]

    Exit Script [ Result: $customerContact ]
End If
```

### A calculated INSERT, into MariaDB

[Execute_SQL_Example_10.fmscript](Execute_SQL_Example_10.fmscript)

```fmscript
Set Variable [
    $$calculatedSqlEmail[1];
    Value: "calculated.sql." & Lower ( Get ( UUID ) ) & "@example.test"
]
Set Variable [ $firstName[1] ; Value: "Codex" ]
Set Variable [ $lastName[1] ; Value: "O'Connor" ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: gemini;
    User Name: "ai2fm_example";
    Password: "ai2fm-demo-only";
    Save credentials: On;
    Calculated SQL Text:
        Let ( [
            sqlFirstName = Substitute ( $firstName ; "'" ; "''" ) ;
            sqlLastName = Substitute ( $lastName ; "'" ; "''" ) ;
            sqlEmail = Substitute ( $$calculatedSqlEmail ; "'" ; "''" )
        ] ;
            "INSERT INTO persons (first_name, last_name, email) VALUES ('" &
            sqlFirstName & "', '" &
            sqlLastName & "', '" &
            sqlEmail & "')"
        )
    ]

Set Variable [ $errorSet[1] ; Value: Let ( [
    $error = Get ( LastError ) ;
    $errorDetail = Get ( LastErrorDetail )
] ;
    $noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
       Title: "Calculated SQL INSERT";
       Message: "The MariaDB record was inserted successfully." & ¶ & $$calculatedSqlEmail;
       Default Button: "OK", Commit: "Yes"
   ]

    Exit Script [ Result: $$calculatedSqlEmail ]

Else

    Show Custom Dialog [ Title: "Error: " & $error ; Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail ; Default Button: "OK", Commit: "No" ]

    Exit Script [ Result: -1 ]
End If
```

### A calculated UPDATE, into MariaDB

[Execute_SQL_Example_11.fmscript](Execute_SQL_Example_11.fmscript)

```fmscript
If [ IsEmpty ( $$calculatedSqlEmail ) ]

    Show Custom Dialog [
        Title: "Calculated SQL UPDATE";
        Message: "Run Execute SQL Example 10 first.";
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If

Set Variable [ $newLastName[1] ; Value: "O'Connor-Smith" ]
Set Variable [ $newCity[1] ; Value: "Athens" ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: gemini;
    User Name: "ai2fm_example";
    Password: "ai2fm-demo-only";
    Save credentials: On;
    Calculated SQL Text:
        Let ( [
            sqlLastName = Substitute ( $newLastName ; "'" ; "''" ) ;
            sqlCity = Substitute ( $newCity ; "'" ; "''" ) ;
            sqlEmail = Substitute ( $$calculatedSqlEmail ; "'" ; "''" )
        ] ;
            "UPDATE persons SET last_name = '" &
            sqlLastName & "', city = '" &
            sqlCity & "' WHERE email = '" &
            sqlEmail & "'"
        )
    ]

Set Variable [ $errorSet[1] ; Value: Let ( [
    $error = Get ( LastError ) ;
    $errorDetail = Get ( LastErrorDetail )
] ;
    $noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
        Title: "Calculated SQL UPDATE";
        Message: "The MariaDB record was updated successfully." & ¶ & $$calculatedSqlEmail;
        Default Button: "OK", Commit: "Yes"
    ]

    Exit Script [ Result: $$calculatedSqlEmail ]

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```

### DROP TABLE

[Execute_SQL_Example_12.fmscript](Execute_SQL_Example_12.fmscript)

```fmscript
Enter Browse Mode [ Pause: Off ]

Set Error Capture [ On ]

Execute SQL [
    With dialog: Off;
    ODBC Data Source: odbcSelf2026;
    User Name: "Admin";
    Password: "admin";
    Save credentials: On;
    SQL Text:
        DROP TABLE "CustomerContactsSQL"
    ]
Set Variable [ $errorSet[1] ; Value: Let( [
$error = Get(LastError) ;
$errorDetail = Get( LastErrorDetail )
] ;
$noError
) ]

If [ $error = 0 ]

    Show Custom Dialog [
        Title: "SQL Action Status";
        Message: "The CustomerContactsSQL table was removed successfully.";
        Default Button: "OK", Commit: "Yes"
    ]

    Open Manage Database

    Exit Script [ Result: 0 ]

Else

    Show Custom Dialog [
        Title: "Error: " & $error;
        Message: "Error: " & $error & ¶ & error.Text ( $error ) & ¶ & $errorDetail;
        Default Button: "OK", Commit: "No"
    ]

    Exit Script [ Result: -1 ]
End If
```

---

## Notes

- `With dialog: On` shows the Specify SQL, the Select ODBC Data Source and the password dialogs when the step runs.
- With `With dialog: Off`, select `Save credentials: On`, or the step may be unable to reach the data source.
- Server-side scripts, FileMaker WebDirect, the FileMaker Data API and Custom Web Publishing support this step only with `With dialog: Off`.
- The step returns no result rows. To read with SQL, use the `ExecuteSQL` calculation function (`SELECT` only, against FileMaker tables) or Import Records from ODBC.
- `Get ( LastError )` returns FileMaker's error, 1408 "Extended error (ODBC)" for an ODBC failure; `Get ( LastErrorDetail )` returns the latest ODBC error state, for example `(8315): Invalid container base directory specified`.
- An SQL statement is limited to 256 K characters (512 KB).
- ODBC data that contains Unicode strings needs an ODBC driver that supports Unicode. For Microsoft SQL Server, prefix Unicode strings with `N`: `N'Smith'`.
- In FileMaker 2025, a variable or a function in `User Name:` or `Password:` is sent as its characters, not evaluated.
- When FileMaker 2026 has turned a saved-off step's Save credentials back on, the text carries a comment above the step:

```fmscript
# ⚠️ You set "Save credentials" to Off, but FileMaker 2026 turned it back On and saved no credentials — this step will prompt for a user name and password when it runs.
```

---

## The clipboard XML

| `.fmscript` | stored as |
|---|---|
| `With dialog:` | `<NoInteract state>` — `True` is `Off` |
| `ODBC Data Source:` | `Profile/@dsn` |
| `User Name:` · `Password:` | `Profile/@UserName` · `Profile/@password` |
| `Save credentials:` | bit 64 of `Profile/@flags` |
| `SQL Text:` | `Profile/@QueryType="Query"` + `<Query>` |
| `Calculated SQL Text:` | `Profile/@QueryType="Calculation"` + `<QueryCalc><Calculation>` |

### Worked example

```fmscript
Execute SQL [ With dialog: Off ; ODBC Data Source: gemini ; User Name: "root" ; Password: 12345678 ; Save credentials: On ; SQL Text: INSERT INTO Employees (EmployeeID, FirstName, LastName, Title, WorkPhone, Salary) VALUES (100, 'Joe', 'Smith', 'Software Engineer', '987-7000', 100000) ]
```

```xml
<Step enable="True" id="117" name="Execute SQL">
  <NoInteract state="True"/>
  <DisableStepCollapsed state="False"/>
  <Profile QueryType="Query" flags="1624" password="12345678" UserName="&quot;root&quot;" dsn="gemini" FieldDelimiter="&#9;" IsPredefined="-1" FieldNameRow="0" DataType="ODBC">
    <Query>INSERT INTO Employees (EmployeeID, FirstName, LastName, Title, WorkPhone, Salary) VALUES (100, 'Joe', 'Smith', 'Software Engineer', '987-7000', 100000)</Query>
  </Profile>
</Step>
```

```xml
<Profile QueryType="Calculation" flags="1624" password="12345678" UserName="&quot;root&quot;" dsn="gemini" …>
  <QueryCalc>
    <Calculation><![CDATA[myTable::myField]]></Calculation>
  </QueryCalc>
</Profile>
```

`DisableStepCollapsed` is FM26 fold state, not a parameter.

---

## Where the step runs

| Product | Supported |
|---|---|
| FileMaker Pro | Yes |
| FileMaker Go | No |
| FileMaker WebDirect | Partial |
| FileMaker Server | Partial |
| FileMaker Cloud | Partial |
| FileMaker Data API | Partial |
| Custom Web Publishing | Partial |

**Originated in version 6.0 or earlier.**

---

## See also

- Import Records from ODBC (35) — imports the rows an SQL query returns
- the `ExecuteSQL` calculation function — `SELECT` against FileMaker tables
