---
title: "Execute_SQL_Example_0"
---

# Execute_SQL_Example_0

[← Execute SQL](execute-sql.html) · <a href="Execute_SQL_Example_0.fmscript" download>Download Execute_SQL_Example_0.fmscript</a>

```fmscript
# ============================================
# Execute SQL — Example 0. The step with nothing set.
# Captured from: Execute_SQL_Example_2026_v1_0.fmp12
# ============================================

# ⚠️ ATTENTION — THIS IS NOT A FUNCTIONAL SCRIPT. It is a reference, not a procedure.
#
# 🔑 `With dialog:` IS ALWAYS WRITTEN. There is no `Execute SQL [ ]` — the dialog state is the
# one thing every Execute SQL step carries.
#
# ℹ️ With nothing else set there is no data source and no SQL. `On` shows the Specify SQL,
# Select ODBC Data Source and password dialogs when the step runs; `Off` has nothing to run.
# ============================================

Execute SQL [ With dialog: On ]
Execute SQL [ With dialog: Off ]
```
