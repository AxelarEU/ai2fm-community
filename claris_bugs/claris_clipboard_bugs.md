---
layout: default
title: "FileMaker Clipboard Bugs — verified, with reproducible test files"
---

# FileMaker Clipboard Bugs — verified, with reproducible test files

*Published by ai2fm · companion to the v2.5 release · last updated 2026-07-18*

During the R&D for **ai2fm v2.5** we found, documented and reported to Claris International Inc. a set of bugs in FileMaker's clipboard serialisation. This page is the account of each one — but unlike a changelog, **every claim here is backed by files you can download and reproduce yourself.**

For each bug we ship a folder containing the **FileMaker file itself** plus real captures:

- `<Step>_<year>.fmp12` — the actual FileMaker file, one per version, so you can open the exact step we tested and copy it yourself.
- `<Step>_Source_<year>.xml` — the exact clipboard FileMaker produced when we copied that step.
- `<Step>_Result_<year>.fmscript` — what ai2fm made of that clipboard.
- where a recovery exists, the corrected files that prove the fix round-trips.

Open the file, copy the same step in your own FileMaker, and you will get the same clipboard. That is the point: nothing here asks for your trust.

---

## First, the good news: your files are safe

**These are *serialisation* bugs, not data-destruction bugs.** The values are intact in your `.fmp12`. What breaks is the **clipboard** — the XML FileMaker writes when you copy a script step, and reads when you paste one. Nothing on this page has corrupted your solution on disk. You only meet these bugs when you copy a step and move it somewhere — which is exactly what ai2fm does, and why we found them.

---

## Perform Find by Natural Language (step 221) — the Prompt Template Name is dropped in 2025

**The bug.** In FileMaker **2025**, copying a Perform Find by Natural Language step **drops the Prompt Template Name** from the clipboard. FileMaker **2026** fixed it. So a step copied in 2025 arrives with the Template Name already gone — before any tool sees it.

### The files

Open **`Perform_Find_by_Natural_Language_2025.fmp12`** in FileMaker 2025, and **`Perform_Find_by_Natural_Language_2026.fmp12`** in FileMaker 2026. Both contain the same Perform Find step, with a Prompt Template Name set. Copy that step in each and compare.

**One setting matters: set the ai2fm _Target FileMaker Version_ to match the file you are working in.** Working in the 2025 file → set it to **2025**; working in the 2026 file → set it to **2026**. It lives in the extension settings under *FileMaker Clipboard Bridge → Target FileMaker Version*. Each capture below states which version to use.

### What FileMaker gives us

With the **Target FileMaker Version set to 2025**, copy the step from **`Perform_Find_by_Natural_Language_2025.fmp12`** in FileMaker 2025 → `Source_2025.xml`. The `<LLMCreateFind>` block ends like this:

```xml
      <Parameters>
        <Calculation><![CDATA["theParameters"]]></Calculation>
      </Parameters>
      <Action>None</Action>
    </LLMCreateFind>
```

There is **no `<TemplateName>` element.** If a Template Name was set, it is not in the clipboard.

Now switch the **Target FileMaker Version to 2026** and copy the same step from **`Perform_Find_by_Natural_Language_2026.fmp12`** in FileMaker 2026 → `Source_2026.xml`. The same block now contains it:

```xml
      <Parameters>
        <Calculation><![CDATA["theParameters"]]></Calculation>
      </Parameters>
      <TemplateName>
        <Calculation><![CDATA["templateName"]]></Calculation>
      </TemplateName>
      <Action>None</Action>
```

The difference between those two files **is the bug.**

### What ai2fm does with the 2025 clipboard

ai2fm reads `Source_2025.xml` and produces `Result_2025.fmscript`:

```fmscript
# ⚠️ Warning: FileMaker 2025 dropped the Prompt Template Name when this step was copied (FM bug, fixed in 2026) — if one was set, it is already lost from this text.
# To recover it: either re-enter it here, or re-copy the step from FileMaker 2026 (with the ai2fm version set to 2026), where the copy keeps it.
Perform Find by Natural Language [ Account Name:"theAccount"; Model:"theModel"; Prompt:"thePrompt"; Get: Find Request as JSON; Parameters:"theParameters"; Response Target:myTable::myField ]
```

We do not invent the missing value — it isn't there to invent. We **flag it, on the step**, and tell you exactly how to get it back. There are two ways.

### Recovery — Path A: re-enter it in the editor

If you know the Template Name, type it back into the `.fmscript` line (`Corrected_at_IDE_Result_2025.fmscript`):

```fmscript
Perform Find by Natural Language [ Account Name:"theAccount"; Model:"theModel"; Prompt:"thePrompt"; Get: Find Request as JSON; Parameters:"theParameters"; Response Target:myTable::myField; Template Name:"templateName" ]
```

With the **Target FileMaker Version set to 2025** (the version you will paste back into), convert it with ai2fm and it rebuilds the element FileMaker dropped (`Corrected_AT_IDE_Result_2025.xml`):

```xml
      <Parameters>
        <Calculation><![CDATA["theParameters"]]></Calculation>
      </Parameters>
      <TemplateName>
        <Calculation><![CDATA["templateName"]]></Calculation>
      </TemplateName>
      <Action>None</Action>
```

That clipboard **pastes into FileMaker 2025 with the Template Name intact.** ai2fm has healed what FileMaker's own copy/paste could not carry.

### Recovery — Path B: re-copy from FileMaker 2026

If the file is available in FileMaker **2026** (here, `Perform_Find_by_Natural_Language_2026.fmp12`), the simpler route is to copy the step there instead — set the ai2fm **Target FileMaker Version** to 2026 — because 2026's clipboard keeps the Template Name. ai2fm reads `Source_2026.xml` and produces `Result_2026.fmscript` with **no warning and the name preserved**:

```fmscript
Perform Find by Natural Language [ Account Name:"theAccount"; Model:"theModel"; Prompt:"thePrompt"; Get: Find Request as JSON; Parameters:"theParameters"; Response Target:myTable::myField; Template Name:"templateName" ]
```

### The point

The bug is FileMaker's; the loss is real; and ai2fm's job is to make the loss **visible and recoverable** rather than silent. Both paths above are shipped as files you can run for yourself.

*Reported to Claris — [Data loss bug: Prompt Template Name is removed when copying/pasting Perform Find by Natural Language script steps in Script Workspace](https://community.claris.com/en/s/question/0D5Vy00002BjYHfKAN/data-loss-bug-prompt-template-name-is-removed-when-copyingpasting-perform-find-by-natural-language-script-steps-in-script-workspace).*

---

## Configure AI Account (step 212) — the XML tag was renamed, so the two versions can't share a step

**The bug.** FileMaker 2025 misspelled its own element names. FileMaker 2026 corrected the spelling — and gave neither version a fallback for the other. The result is a wall in *both* directions: a Configure AI Account step copied in one version, pasted into the other, comes in with **Account Name, Endpoint and API key silently blanked.** The paste appears to succeed; your credentials are just gone.

### The files

Open **`Configure_AI_Account_2025.fmp12`** in FileMaker 2025 and **`Configure_AI_Account_2026.fmp12`** in FileMaker 2026. Each holds the same Configure AI Account step, with an account name, endpoint and API key set. As before, set the ai2fm **Target FileMaker Version** (in the ai2fm sidebar, or in *FileMaker Clipboard Bridge → Target FileMaker Version*) to match wherever you are pasting.

### The two clipboards differ in one thing: the spelling

Copy the step in **FileMaker 2025** → `Source_2025.xml`. Note the missing **n**:

```xml
    <SetLLMAccout>
      <AccoutName>
        <Calculation><![CDATA["my_Local_account"]]></Calculation>
      </AccoutName>
      ...
    </SetLLMAccout>
```

Copy the same step in **FileMaker 2026** → `Source_2026.xml`. FileMaker 2026 fixed the spelling:

```xml
    <SetLLMAccount>
      <AccountName>
        <Calculation><![CDATA["my_Local_account"]]></Calculation>
      </AccountName>
      ...
    </SetLLMAccount>
```

`SetLLMAccou`**`t`** / `Accou`**`t`**`Name` in 2025 versus `SetLLMAccou`**`nt`** / `Accou`**`nt`**`Name` in 2026. The value inside is identical — only the tag name changed.

### What FileMaker does when you paste across versions

Paste the **2025** clipboard into **FileMaker 2026** (or the 2026 clipboard into 2025) and FileMaker does not reject it — it pastes a step with the fields **emptied**, because it doesn't recognise the other version's tag (`Configure_AI_Account_Fails to paste at FM2026 copied from FM2025.fmscript`):

```fmscript
Configure AI Account [ Account Name:  ; Model Provider: Custom ; Endpoint:  ; API key:  ]
```

The account name, endpoint and API key are gone — even though they are still sitting in the pasted clipboard's XML. FileMaker read the wrong tag and blanked the fields. This is the dangerous kind of failure: it looks like it worked.

### What ai2fm does — it reads both spellings

Point ai2fm at either clipboard and you get the same, complete, correct script. From the 2025 clipboard (`Result_2025.fmscript`) and from the 2026 clipboard (`Result_2026.fmscript`) — **byte-for-byte identical**:

```fmscript
Configure AI Account [ Account Name: "my_Local_account" ; Model Provider: Custom ; Endpoint: "https://myserver.example.com:8080/" ; API key: "sk-RZCtpWT..." ]
```

ai2fm knows both the 2025 and 2026 spelling and reads whichever it is handed. Nothing is blanked.

### And it bridges — in both directions

The recovery is the same move both ways: read the step into ai2fm, set the **Target FileMaker Version** to wherever you are pasting, convert back. ai2fm writes the spelling that version expects.

- Read either clipboard → set target **2026** → the result pastes into FileMaker 2026 with every field intact (`Pastes correctly copied from IDE -> FM2026.fmscript`).
- Read either clipboard → set target **2025** → the result pastes into FileMaker 2025 with every field intact (`Pastes correctly copied from IDE -> FM2025.fmscript`).

Both round-trips produce the full step:

```fmscript
Configure AI Account [ Account Name: "my_Local_account" ; Model Provider: Custom ; Endpoint: "https://myserver.example.com:8080/" ; API key: "sk-RZCtpWT..." ]
```

### The point

FileMaker 2025 and 2026 cannot exchange a Configure AI Account step — in either direction the credentials come across blank. ai2fm makes the two versions **interoperable**: it reads both spellings and, using the Target FileMaker Version setting, writes whichever the destination needs. This is not a repair of lost data — the data was never lost, only mis-tagged — it is a translation FileMaker itself does not perform.

*Reported to Claris — [Backward-compatibility bug: FileMaker Pro 2026 fails to paste FileMaker Pro 2025 Configure AI Account script steps due to renamed XML tags](https://community.claris.com/en/s/question/0D5Vy00002pVV9VKAW/backward-compatibility-bug-filemaker-pro-2026-fails-to-paste-filemaker-pro-2025-configure-ai-account-script-steps-due-to-renamed-xml-tags).*

---

## Configure Machine Learning Model (step 202) — the structure changed, and a bad paste becomes a different command

**The bug.** FileMaker 2025 and FileMaker 2026 write this step with different XML *structures*, and neither version's importer accepts the other's. Copy the step across versions and it does not error — it pastes a step that is quietly **wrong in two ways**: the **From** source field is dropped, and the **Operation** resets to `Unload`. A `Vision` model step becomes an `Unload` step. This is the most dangerous failure on this page, because the result looks like a perfectly valid command — just not the one you had.

### The files

Open **`Configure_Machine_Learning_Model_2025.fmp12`** in FileMaker 2025 and **`Configure_Machine_Learning_Model_2026.fmp12`** in FileMaker 2026. Each holds the same two steps — a `Vision` and a `General` model configuration, each with a model name and a `From` field. Set the ai2fm **Target FileMaker Version** (in the ai2fm sidebar, or *FileMaker Clipboard Bridge → Target FileMaker Version*) to match wherever you are pasting.

### The two versions store the operation differently

Copy the steps in **FileMaker 2025** → `Source_2025.xml`. The operation is plain **text** inside `<ConfigureCoreML>`, and the field is emitted **twice**:

```xml
    <Field table="myTable" id="7" name="myField"/>
    <ConfigureCoreML>Vision<Name><Calculation><![CDATA["visionModel"]]></Calculation></Name></ConfigureCoreML>
    <Field table="myTable" id="7" name="myField"/>
```

Copy the same steps in **FileMaker 2026** → `Source_2026.xml`. The operation moved into an `<Operation>` child element, and the field is emitted **once**:

```xml
      <ConfigureCoreML>
        <Operation>Vision</Operation>
        <Name>
          <Calculation><![CDATA["visionModel"]]></Calculation>
        </Name>
      </ConfigureCoreML>
      <Field table="myTable" id="7" name="myField"/>
```

Same step, same values — a completely different XML shape.

### What FileMaker does when you paste across versions

Paste the **2025** clipboard into **FileMaker 2026** (or the 2026 clipboard into 2025) and FileMaker cannot read the other version's structure. It does not reject the paste — it produces a step with **both the operation and the source wrong** (`Configure_Machine_Learning_Model_Fails to paste at FM2026 copied from FM2025.fmscript`):

```fmscript
Configure Machine Learning Model [ Operation: Unload ; Name: "visionModel" ]
Configure Machine Learning Model [ Operation: Unload ; Name: "visionModel" ]
```

Compare to what you had — `Operation: Vision` / `Operation: General`, each `From: myTable::myField`. After the cross-version paste, **every operation has collapsed to `Unload`** and the **`From` source is gone.** The failure is deterministic and it happens in **both** directions. A model step silently becomes an unload.

### What ai2fm does — it reads both structures

Point ai2fm at either clipboard and you get the same, complete, correct script. From the 2025 clipboard (`Result_2025.fmscript`) and from the 2026 clipboard (`Result_2026.fmscript`) — **byte-for-byte identical**:

```fmscript
Configure Machine Learning Model [ Operation: Vision ; Name: "visionModel" ; From: myTable::myField ]
Configure Machine Learning Model [ Operation: General ; Name: "visionModel" ; From: myTable::myField ]
```

The real operations survive, and the `From` field survives. ai2fm understands both the 2025 text-in-`<ConfigureCoreML>` shape and the 2026 `<Operation>`-child shape.

### And it bridges — in both directions

Read the step into ai2fm, set the **Target FileMaker Version** to wherever you are pasting, convert back — ai2fm writes the structure that version expects, operation and source intact. Read either clipboard → set target **2026** → pastes correctly into FileMaker 2026. Read either → set target **2025** → pastes correctly into FileMaker 2025.

### The point

FileMaker 2025 and 2026 cannot exchange a Configure Machine Learning Model step: across versions the operation resets to `Unload` and the source field vanishes — a valid-looking step that does the wrong thing. ai2fm reads both structures, keeps the operation and the source, and writes whichever shape the destination needs. Nothing is lost — the values were always in the XML; FileMaker just could not read the other version's layout.

*Reported to Claris — [Backward-compatibility bug: FileMaker Pro 2026 fails to paste FileMaker Pro 2025 Configure Machine Learning Model script steps](https://community.claris.com/en/s/question/0D5Vy00002pahA0KAI/backward-compatibility-bug-filemaker-pro-2026-fails-to-paste-filemaker-pro-2025-configure-machine-learning-model-script-steps).*

---

## Set Data File Position (step 195) — the New position value is dropped on copy in 2026

**The bug.** FileMaker **2026** drops the **New position** value (the byte offset to seek to) from the clipboard when you copy a Set Data File Position step. The value is fine in your file and fine in the Script Workspace — it is lost only in the clipboard, at the moment of copy. FileMaker **2025** copies the same step correctly. Because the loss is in the clipboard, it travels with it: paste the 2026-copied step back into FileMaker — 2026 **or** 2025 — and the New position is gone in both.

### The files

Open **`Set_Data_File_Position_2026.fmp12`** in FileMaker 2026 and **`Set_Data_File_Position_2025.fmp12`** in FileMaker 2025. Each holds the same three steps — a New position given as a variable (`$thePosition`), as a literal (`"thePosition"`), and as a field (`myTable::myNumber`). Copy them in each version and compare.

### What FileMaker gives us

Copy the three steps in **FileMaker 2025** → `Source_2025.xml`. Every step carries its `<position>`:

```xml
  <Step enable="True" id="195" name="Set Data File Position">
    <Calculation><![CDATA[myTable::myField]]></Calculation>
    <position>
      <Calculation><![CDATA[$thePosition]]></Calculation>
    </position>
  </Step>
```

Copy the same three steps in **FileMaker 2026** → `Source_2026.xml`. The `<position>` element is gone from every one — only the File ID survives:

```xml
  <Step enable="True" id="195" name="Set Data File Position">
    <DisableStepCollapsed state="False"/>
    <Calculation><![CDATA[myTable::myField]]></Calculation>
  </Step>
```

Same step, same value in the file — but the 2026 clipboard no longer contains the New position. That absence **is the bug**, and it is why pasting the 2026 clipboard into either version produces a step with New position blank.

### What ai2fm does with the 2025 clipboard

ai2fm reads `Source_2025.xml` and produces `Result_2025.fmscript`, every value intact:

```fmscript
Set Data File Position [ File ID: myTable::myField ; New position: $thePosition ]
Set Data File Position [ File ID: myTable::myField ; New position: "thePosition" ]
Set Data File Position [ File ID: myTable::myField ; New position: myTable::myNumber ]
```

### What ai2fm does with the 2026 clipboard — it flags the loss

The 2026 clipboard has no New position to read, so ai2fm cannot invent one. What it does instead is refuse to let the loss pass silently: it marks every affected step with a warning (`Result_2026.fmscript`):

```fmscript
# ⚠️ Warning: check the New position value — FileMaker 2026 may have dropped it on copy; re-enter it here if it was set.
Set Data File Position [ File ID: myTable::myField ; New position:  ]
# ⚠️ Warning: check the New position value — FileMaker 2026 may have dropped it on copy; re-enter it here if it was set.
Set Data File Position [ File ID: myTable::myField ; New position:  ]
# ⚠️ Warning: check the New position value — FileMaker 2026 may have dropped it on copy; re-enter it here if it was set.
Set Data File Position [ File ID: myTable::myField ; New position:  ]
```

Without ai2fm the empty New position is indistinguishable from a step that never had one — FileMaker gives no sign anything was lost. The warning turns a silent drop into a visible one.

### Recovery — re-enter it, and ai2fm rebuilds it

Type the New position back onto each flagged line — a variable, a literal, or a field, whichever it was. This is the whole repair, and it is done in the text you are already reading:

```fmscript
Set Data File Position [ File ID: myTable::myField ; New position: $thePosition ]
Set Data File Position [ File ID: myTable::myField ; New position: "thePosition" ]
Set Data File Position [ File ID: myTable::myField ; New position: myTable::myNumber ]
```

Convert that with ai2fm and it rebuilds the `<position>` element FileMaker dropped (`Result_2025.xml`) — the part you never have to look at, shown here only as proof the value really is back in the clipboard:

```xml
  <Step enable="True" id="195" name="Set Data File Position">
    <Calculation><![CDATA[myTable::myField]]></Calculation>
    <position>
      <Calculation><![CDATA[$thePosition]]></Calculation>
    </position>
  </Step>
```

That clipboard pastes into FileMaker with the New position intact.

### The point

FileMaker 2026 loses the New position the moment you copy the step, in a way nothing on screen reveals. ai2fm cannot recover a value that never reached the clipboard — but it makes the loss **visible**, flags exactly which steps are affected, and rebuilds the value the instant you supply it. A silent drop becomes a caught one.

*Reported to Claris — [Bug report: FileMaker Pro 2026 drops the New position value from Set Data File Position on copy to the clipboard](https://community.claris.com/en/s/question/0D5Vy00002veMl7KAE/bug-report-filemaker-pro-2026-drops-the-new-position-value-from-set-data-file-position-on-copy-to-the-clipboard).*

---

## Perform RAG Action — Add Data (step 219) — the Response Target is dropped, but only for the (Async) sources

**The bug.** In FileMaker **2026**, a Perform RAG Action step with **Action: Add Data** can store a **Response Target** — the field or variable that receives the document ID the RAG server returns. Copying that step keeps the Response Target when the source is **From Container** or **From File**, but **drops it when the source is the *(Async)* variant** (From Container (Async) / From File (Async)). Same step, same option — the loss depends entirely on which data source you picked. This is a 2026-only step, so there is no earlier version to compare against; the bug is FileMaker 2026 losing part of its own new feature on copy.

### The files

Open **`Perform_RAG_Action_2026.fmp12`** in FileMaker 2026. It holds four Add-Data steps, each with a Response Target set: two using **From Container** (labelled *"This works"*) and two using **From Container (Async)** (labelled *"This fails at copy-paste"*). Copy all four and inspect the clipboard.

### What FileMaker gives us

Copy the steps → `Source_2026.xml`. The Response Target is stored as `<Field type="AddDataResponse">` inside `<RAGSpace>`. For the two **From Container** steps it is present:

```xml
      <DataSource>FromContainer</DataSource>
      <Field type="AddDataResponse">$theResponse</Field>
```

```xml
      <DataSource>FromContainer</DataSource>
      <Field type="AddDataResponse" table="myTable" id="19" name="TypeID"/>
```

For the two **From Container (Async)** steps, the `<DataSource>` is there but the `AddDataResponse` field is simply gone — FileMaker dropped it:

```xml
      <DataSource>FromContainerAsync</DataSource>
      <RAGSpaceTokensPerTextChunk>
        <Calculation><![CDATA[$tokens]]></Calculation>
      </RAGSpaceTokensPerTextChunk>
```

The difference between the two blocks — same option, present for one source, absent for the other — **is the bug.**

### What ai2fm does — keep what's there, flag what's gone

ai2fm reads `Source_2026.xml` and produces `Result_2026.fmscript`. The **From Container** steps come through complete — Response Target and all:

```fmscript
Perform RAG Action [ RAG Account Name: "theAccount" ; Space ID: "theID" ; Action: Add Data ; RAG Data: From Container ; Container Field: myTable::myContainer ; Detect vertical text ; Tokens per Text Chunk: $tokens ; Response Target: $theResponse ]
Perform RAG Action [ RAG Account Name: "theAccount" ; Space ID: "theID" ; Action: Add Data ; RAG Data: From Container ; Container Field: myTable::myContainer ; Detect vertical text ; Tokens per Text Chunk: $tokens ; Response Target: myTable::TypeID ]
```

The **From Container (Async)** steps have no Response Target to read, so ai2fm flags each one instead of letting the loss pass unseen:

```fmscript
# ⚠️ Warning: for Action: Add Data with an (Async) source, FileMaker 2026 drops the Response Target (the returned document ID) from the clipboard on copy — an FM2026 platform defect (reported to Claris). Re-enter it here if one was set and ai2fm will rebuild it on the way back into FileMaker.
Perform RAG Action [ RAG Account Name: "theAccount" ; Space ID: "theID" ; Action: Add Data ; RAG Data: From Container (Async) ; Container Field: myTable::myContainer ; Detect vertical text ; Tokens per Text Chunk: $tokens ]
```

This is the important half of the fix: ai2fm does **not** blindly drop the Response Target for every Add-Data step. It keeps the value FileMaker kept, and warns only on the *(Async)* steps where FileMaker actually lost it.

### Recovery — re-enter it, and ai2fm rebuilds it

Type the Response Target back onto the flagged *(Async)* line and convert with ai2fm. It rebuilds the `<Field type="AddDataResponse">` element FileMaker dropped, in the right place inside `<RAGSpace>` (`Source_Corrected_at_IDE_2026.xml`):

```xml
      <DataSource>FromContainerAsync</DataSource>
      <Field type="AddDataResponse">$theResponse</Field>
```

Read that healed clipboard back and every step — sync and async — carries its Response Target, with no warning left:

```fmscript
Perform RAG Action [ RAG Account Name: "theAccount" ; Space ID: "theID" ; Action: Add Data ; RAG Data: From Container (Async) ; Container Field: myTable::myContainer ; Detect vertical text ; Tokens per Text Chunk: $tokens ; Response Target: $theResponse ]
```

### The point

FileMaker 2026 keeps the Add-Data Response Target for the synchronous sources and silently drops it for the *(Async)* ones. ai2fm mirrors the truth exactly: it preserves the value where FileMaker preserves it, flags the precise steps where FileMaker lost it, and rebuilds it the moment you re-enter it. Nothing correct is thrown away, and nothing lost is left silent.

*Reported to Claris — [Data loss bug: "Response Target" is removed when copying/pasting Perform RAG Action (Add Data) script steps in Script Workspace](https://community.claris.com/en/s/question/0D5Vy00002p5t84KAA/data-loss-bug-response-target-is-removed-when-copyingpasting-perform-rag-action-add-data-script-steps-in-script-workspace).*

---

## Read from Data File (step 193) — the Amount is dropped on copy, and in 2025 two very different scripts look identical

**The bug.** In FileMaker **2026**, copying a Read from Data File step **drops the Amount (bytes)** value — the number of bytes to read — from the clipboard. The step in your file still holds it. Only the copy loses it. What makes this one worth reading twice is what happens next in FileMaker 2025: depending on how the step got there, the Amount is either **hidden but alive** or **gone for good** — and the two are indistinguishable on screen.

### The files

Open **`Read_from_Data_File_2026.fmp12`** in FileMaker 2026. It holds six Read from Data File steps: three File ID forms (a field, a `$variable`, a literal) across the three Read-as encodings (Bytes, UTF-16, UTF-8), each with an Amount set. Copy all six.

### What FileMaker gives us

Copy the steps in **FileMaker 2026** → `Source_2026.xml`. Every step arrives without its Amount — there is no `<Count>` element anywhere in the file:

```xml
  <Step enable="True" id="193" name="Read from Data File">
    <DisableStepCollapsed state="False"/>
    <DataSourceType value="3"/>
    <Calculation><![CDATA[myTable::TypeID]]></Calculation>
  </Step>
```

A correct clipboard carries the value like this — the shape FileMaker 2025 writes, and the shape ai2fm rebuilds:

```xml
    <Count>
      <Calculation><![CDATA[10]]></Calculation>
    </Count>
```

### What ai2fm does — it flags every affected step

ai2fm reads `Source_2026.xml` and produces `Result_2026.fmscript`. All six steps come through with the Amount blank, and each one is marked:

```fmscript
# ⚠️ Warning: the Amount (bytes) value is not in this copy — FileMaker left it out when the step was copied, even though the step still holds it.
# Re-enter the Amount here and paste the step back into FileMaker: that repairs the step for good — copy it again afterwards and the value stays.
Read from Data File [ File ID: myTable::TypeID ; Amount (bytes):  ; Target:  ; Read as: Bytes ]
```

### Recovery — re-enter it, and ai2fm repairs the step permanently

Type the Amounts back onto the flagged lines (`Corrected_at_IDE_2026.fmscript`):

```fmscript
Read from Data File [ File ID: myTable::TypeID ; Amount (bytes): 10 ; Target:  ; Read as: Bytes ]
Read from Data File [ File ID: myTable::TypeID ; Amount (bytes): $theAmount ; Target: myTable::myField ; Read as: Bytes ]
```

Convert that with ai2fm and it rebuilds the `<Count>` element FileMaker left out, on all six steps (`Corrected_at_IDE_2026.xml`):

```xml
    <Count>
      <Calculation><![CDATA[$theAmount]]></Calculation>
    </Count>
```

**Paste that back into FileMaker and the step is repaired for good** — copy it again afterwards and the Amount comes with it. This is the one bug on this page where ai2fm does not merely surface the loss: it puts the value back into your solution permanently.

### The part that should worry you: in 2025, two different scripts look the same

Take that same 2026 file to FileMaker **2025**, by the two routes a developer would actually use, and the Script Workspace renders both the same way — no Amount shown at all:

```fmscript
Read from Data File [File ID:myTable::TypeID; Target:; Read as:Bytes]
```

They are not the same. Open the step's gear, click **Amount → Specify…**, and:

- **The file simply opened in 2025** — the Specify dialog shows **`10`**. The value is intact and *will execute*. It is only the step rendering that hides it.
- **The step copy-pasted from 2026** — the Specify dialog is **empty**. The value is gone.

One script silently enforces a read limit; the other silently has none; and nothing on screen tells them apart. That, more than the dropped element, is the real hazard here.

### Three ways to get the Amount back

- **Author in 2025 to begin with.** FileMaker 2025 writes the Amount into the clipboard correctly, so the problem never starts.
- **If the file was opened in 2025:** open the Amount gear on the step and save. The value is already there — saving makes FileMaker write it out properly again. No tooling needed. (This works *only* on this route, because the value survived; there is nothing to reveal on a pasted step.)
- **In any version, via ai2fm:** re-enter the Amount in the editor and paste the step back. ai2fm rebuilds the element and the repair sticks in 2025 and 2026 alike.

One honest caveat: a step copied out of a 2025 file gives no sign of trouble, because in 2025 an empty Amount is a perfectly normal thing to have — ai2fm cannot tell "never set" from "lost on the way here". If a 2025 file began life in 2026, check the Amount gear on these steps before trusting a blank.

*Reported to Claris — [Bug Report: FileMaker Pro 2026 drops the "Amount (bytes)" value from Read from Data File on copy to the clipboard](https://community.claris.com/en/s/question/0D5Vy00002veHlvKAE/bug-report-filemaker-pro-2026-drops-the-amount-bytes-value-from-read-from-data-file-on-copy-to-the-clipboard).*

---

## Configure Prompt Template (step 226) — a Google step pastes back as OpenAI

**The bug.** In FileMaker **2026**, a Configure Prompt Template step set to **Model Provider: Google** does not survive a copy and paste. The pasted step comes back as **OpenAI**. Every other provider — ChatGPT, Anthropic, Cohere, Custom — is preserved correctly. Only Google is affected, and the step then runs against a different AI provider than the one the developer chose.

### The files

Open **`Configure_Prompt_Template_2026.fmp12`** in FileMaker 2026. It holds Configure Prompt Template steps covering all five providers, in both enabled and disabled form. Copy them and inspect the clipboard.

### What FileMaker gives us

Copy the steps → `Source_2026.xml`. Four of the five providers serialize their value as you would expect:

```xml
      <ModelProvider>Anthropic</ModelProvider>
```

Google does not. It serializes as an **empty element** — the tag is there, the value is not:

```xml
      <ModelProvider/>
```

That is the whole bug, and everything follows from it. When FileMaker pastes this step back, it finds an empty provider, falls back to its default — **OpenAI** — and writes that in. The developer's choice is gone, replaced by a valid-looking setting that happens to be the wrong one. Nothing on screen reports a problem.

### What ai2fm does — it reads the empty element as Google

ai2fm knows that in this step an empty `<ModelProvider/>` **means Google**, because no other provider serializes empty. Reading the same clipboard, it produces `Result_2026.fmscript` with the provider intact:

```fmscript
Configure Prompt Template [ Template Name: "Name" ; Model Provider: Anthropic ; Template Type: SQL Query ; … ]
Configure Prompt Template [ Template Name: "Name" ; Model Provider: Google ; Template Type: SQL Query ; … ]
```

Convert that back and paste it into FileMaker, and the step arrives as Google — the setting the developer actually made. **The choice survives the ai2fm round trip where it does not survive FileMaker's own copy and paste.**

This holds for disabled steps too. We checked all five providers in both enabled and disabled form — ten steps — and the serialization is identical in both states: only Google comes across empty, and ai2fm recovers it in both cases.

```fmscript
// Configure Prompt Template [ Template Name: "Name" ; Model Provider: Google ; Template Type: SQL Query ; … ]
```

### The point

FileMaker writes Google as an absence and then reads that absence as OpenAI. The information needed to get it right is present in the clipboard — an empty provider element is unambiguous, because no other provider produces one — so this is a case where the correct value was recoverable all along. ai2fm recovers it. FileMaker, reading its own file, does not.

*Reported to Claris — [Data loss bug: "Model Provider: Google" is lost on copy/paste of Configure Prompt Template script steps in Script Workspace (pastes back as OpenAI)](https://community.claris.com/en/s/question/0D5Vy00002pIkEVKA0/data-loss-bug-model-provider-google-is-lost-on-copypaste-of-configure-prompt-template-script-steps-in-script-workspace-pastes-back-as-openai).*

---

## Refresh Portal (step 180) — a parameter that exists, displays, and cannot be set

**The bug.** Refresh Portal carries a **Repetition** parameter that no developer can reach. FileMaker's Script Workspace displays it — `Refresh Portal [Object Name: "thePortal"; Repetition: 1]` — and the copied clipboard serializes it. But the step's options panel offers no field for it, so it cannot be entered, edited, or removed. It appears on its own when an Object Name is set, its value is always `1`, and it is absent from both the documentation and the step's own SaXML.

### What FileMaker gives us

Copy the steps → `Source_2026.xml`. Each Refresh Portal step with an Object Name carries the element:

```xml
  <Step enable="True" id="180" name="Refresh Portal">
    <DisableStepCollapsed state="False"/>
    <ObjectName>
      <Calculation><![CDATA["thePortal"]]></Calculation>
    </ObjectName>
    <Repetition>
      <Calculation><![CDATA[1]]></Calculation>
    </Repetition>
  </Step>
```

In our capture, **six of the seven steps carry `<Repetition>`, and the value is `1` every time.** The one step without it is the one with no Object Name — the tell that it materializes as a side effect of filling in the Object Name, rather than as something anybody chose.

### Why we treat it as noise rather than a parameter

- **It cannot be set.** The step's options panel has no repetition field. There is no way for a developer to enter, change, or clear it.
- **It never varies.** Every occurrence is `1`. No other value has ever been produced.
- **It is not documented.** The Claris help page for Refresh Portal lists exactly one option: Object Name.
- **It is not in the step's own SaXML.** FileMaker's canonical serialization of the same step reports `membercount="1"` with a single `<Parameter type="Object">`. There is no Repetition member.

So the value is real enough to display and to serialize, and at the same time inert: nobody put it there, nobody can change it, and FileMaker's own canonical format does not record it.

### What ai2fm does — it leaves the phantom out

We could reproduce what the clipboard says. We deliberately do not, because writing `Repetition: 1` into your script would present a control that does not exist — a parameter a developer might reasonably try to edit, in a step that offers no way to do so. Reading the clipboard above, ai2fm emits the step as a developer can actually work with it:

```fmscript
Refresh Portal [ Object Name: "thePortal" ]
Refresh Portal [ Object Name: $thePortal ]
Refresh Portal [ Object Name: myTable::myField ]
```

No Repetition — in enabled and disabled steps alike. This is a deliberate editorial choice, not an oversight: we follow the documented step and its own SaXML, which agree with each other.

### The point

Most entries on this page are about information going missing. This one is about information that should never have been surfaced. A parameter you cannot set is not a setting — and two clipboards that differ only by its presence describe exactly the same step, so carrying it through would produce spurious differences when you diff or version your scripts.

*Reported to Claris — [Bug Report: Refresh Portal emits a phantom "Repetition" parameter](https://community.claris.com/en/s/question/0D5Vy00002ulmO5KAI/bug-report-refresh-portal-emits-a-phantom-repetition-parameter).*

---

## Set Dictionary (step 209) — on WinSoft localized builds the spelling language becomes dialog text

**The bug.** This one is not Claris's. On the **WinSoft Middle East** localized build of FileMaker, a Set Dictionary step loses its spelling language the moment you copy, print, or export it. Copy and paste the step and every localized dictionary comes back as **UK English**. Print it or Save as XML and the language is replaced by **unrelated interface text** — `Expire password`, `Account Name:`, `Pages:`. The step in the file is fine; all three serializations read the same corrupted table.

### The files

Open **`DictionaryBug.fmp12`** — but note the prerequisite: this reproduces on the **WinSoft ME build**. Install FileMaker from the Middle East installer, open the file there, and follow the three states below. The extra dictionaries do not exist in the Central European or Claris/USA builds, so those cannot show the failure.

### Why it happens

Set Dictionary stores the chosen language as a small enum id, then resolves that id to a display name through the build's localization string table. Claris ships thirteen languages at values **1 to 13**, and every build has names for them:

```xml
Português (Brasil) = 1        US English (Medical) = 8
Português (Portugal) = 2      Deutsch (Neue Regeln) = 9
Nederlands = 3                Schweizerdeutsch = 10
Deutsch (Alte Regeln) = 4     US English = 11
Español = 5                   Svenska = 12
Italiano = 6                  UK English = 13
Français = 7
```

The WinSoft ME installer adds its own dictionaries on top — a `WinsoftDictionaries` folder inside the FileMaker application directory holding Greek, Russian, Hebrew, Slovenian and others. Selecting one stores an enum id **outside 1–13**, and WinSoft never added matching names to the string table. The lookup falls through and returns whatever string happens to sit at that offset:

```xml
US English = 11                       ← the only value inside 1-13; resolves correctly
Expire password = 101                 Source field 0 import to = 113
Account Name: = 102                   Data contains column names = 117
Password: = 103                       All Pages = 118
Old Password: = 105                   Pages: = 119
New Account = 110                     Number pages from: = 121
```

Every one of those is a string from the Change Password dialog, the Import field-mapping screen, or the Print page-range controls. None is a spelling language.

### One file, three states — and one line that proves it

The test file holds the same forty-two localized dictionary steps plus, on the last line, a step set to **US English**. Watch that last line:

- **Opened on the ME build**, the script renders correctly: `Български`, `Ελληνικά`, `עברית`, `Русский`, `Türkçe`, `ไทย` and the rest, each showing its real language. Line 43 shows `US English`.
- **Copy the script and paste it**, and all forty-two collapse to `UK English`. Line 43 still shows `US English`.
- **Open the same file on a CE or USA build**, and all forty-two render empty — `Set Dictionary [Spelling Language:]` with nothing at all. Line 43 still shows `US English`.

`US English` is enum **11**, inside the standard range, so it has a real name in every build's table. It is the one value that survives all three states — which is the root cause demonstrated rather than argued. The languages that break are exactly the ones whose enum id has no name entry.

### What this means for any tool

There is no clean format to recover from. The clipboard, the printed output and the Save-as-XML export all read the same table, so all three carry the same corruption. A tool cannot repair this from the outside, and neither can we: the correct language name simply does not exist anywhere in the build's resources. We build our Set Dictionary support from the official Claris build, where the table is correct, so the step ships clean.

The fix belongs to WinSoft: add the missing value-to-name entries for the dictionaries they ship beyond the standard thirteen. The 1–13 table is already correct.

*Reported to **WinSoft** — ticket [rt2.winsoft.fr #1683], where WinSoft reproduced and confirmed all three failure modes on the ME build, with their own screenshots. Also posted to the Claris community so other users of the localized builds can find it: [Bug Report: WinSoft (ME/CE localized) FileMaker builds corrupt Set Dictionary's language on copy/print/SaXML](https://community.claris.com/en/s/question/0D5Vy00002uuapSKAQ/bug-report-winsoft-mece-localized-filemaker-builds-corrupt-set-dictionarys-language-on-copyprintsaxml).*

---

## Execute SQL (step 117) — two ways FileMaker 2026 breaks an ODBC connection

**The bug.** An Execute SQL step that connects to an ODBC data source has two settings FileMaker 2026 mishandles: the **Save credentials** checkbox and the **user name**. Both are corrupted the moment you save the step in 2026, and the damage travels with the step wherever you paste it. ai2fm cannot undo what FileMaker already wrote — but it can tell you, on the exact step, what happened and what to fix.

### The files

Open **`Execute_SQL_Bug_Report_2026.fmp12`** in FileMaker 2026. It holds two ODBC Execute SQL steps: one set to **not** save credentials, and one with a user name and password saved. Copy them and look at what the clipboard actually contains.

### Bug one — you say "don't save my credentials", FileMaker 2026 saves them anyway

Set the ODBC Connect dialog's "Save user name and password" checkbox to **off**, with no user name or password, and save the step. Copy it, and the clipboard says the opposite:

```xml
<Profile QueryType="Query" flags="1624" password="" UserName="" dsn="gemini" DataType="ODBC"/>
```

The `flags` integer encodes that checkbox, and `1624` means **on** — even though you set it off, and even though there is nothing to save (user name and password are both empty). FileMaker 2026 re-checks the box for you and keeps it checked. The error is the flag itself: your deliberate choice **not** to store credentials has been silently reversed to "store them". Because the wrong value is baked into the copied step, it stays wrong wherever the step goes — pasted into 2026 or 2025 alike.

ai2fm reads that clipboard and flags it, on the step:

```fmscript
# ⚠️ You set "Save credentials" to Off, but FileMaker 2026 turned it back On and saved no credentials — this step will prompt for a user name and password when it runs.
Execute SQL [ With dialog: Off ; ODBC Data Source: gemini ; Save credentials: On ]
```

### Bug two — FileMaker 2026 wraps the user name in stray quotes

Now the step with a saved user name. You typed `root`. Copy the step, and the clipboard has this:

```xml
<Profile QueryType="Calculation" flags="1624" password="12345678" UserName="&quot;root&quot;" dsn="gemini" DataType="ODBC"/>
```

The user name is stored as `"root"` — with literal double quotes wrapped around it. FileMaker 2026 added them at save time. In FileMaker 2026 the step still runs, because 2026 accepts its own quoted name. But **paste it into FileMaker 2025 and the step silently will not run** — 2025 does not recognise `"root"` as a user name, the connection fails, and nothing on screen tells you why. The step is there, it displays, its values look present — it just does not work. The fix is to remove the quotes so the name reads `root` again.

ai2fm flags this too, and shows you the corrected name:

```fmscript
# ⚠️ The ODBC User Name has stray quotes added by FileMaker 2026 — remove them so it reads root or the step will not run in 2025.
Execute SQL [ With dialog: Off ; ODBC Data Source: gemini ; User Name: "root" ; Password: 12345678 ; Save credentials: On ]
```

### The point

Both problems are FileMaker 2026's, and both are written into the step before any tool sees it — ai2fm cannot silently repair a value FileMaker deliberately wrote. What it does instead is refuse to let either pass unnoticed: it warns you on the exact step, in plain terms, that the credential flag was flipped against your choice and that the quoted user name will break the step in 2025. A silent failure becomes a caught one.

*Reported to Claris — [Bug Report: FileMaker Pro Execute SQL / Import Records ODBC "Save user name and password" flag is not preserved across versions](https://community.claris.com/en/s/question/0D5Vy00002szQ2NKAU/bug-report-filemaker-pro-execute-sql-import-records-odbc-save-user-name-and-password-flag-is-not-preserved-across-versions-a-2025-step-with-credentials-not-saved-pastes-into-2026-with-the-checkbox-wrongly-checked).*

*(The same Claris report also covers Import Records with an ODBC source. That step is under separate investigation and will get its own entry once its behaviour is captured directly.)*

---

## The bugs we found and did NOT report

Not everything we found is worth Claris's time, and a catalogue that lists every defect regardless of consequence is less useful, not more. Two of the bugs we hit are real — FileMaker genuinely does the wrong thing — but they cannot harm a user. We are documenting them here rather than filing them, and it is worth explaining why.

**FileMaker 2025's clipboard leaks 2026 features it does not understand.** Open a file authored in FileMaker 2026 with FileMaker 2025, copy a step, and in some cases the 2026-only data rides along into the clipboard — even though 2025 has no idea what it is. We saw it on **Set Zoom Level (step 97)**, where 2026's Custom zoom calculation survives into the 2025 copy, and on **Re-Login (step 138)**, where a 2026 file reference does the same.

The reason it happens is structural, and it explains why some steps leak and others do not:

- When the 2026 feature is a **new value inside an element 2025 already knows** — Set Zoom Level's Custom is a new option on the existing `<Zoom>` element — the data passes through 2025's parser as an opaque string and lands in the clipboard.
- When the 2026 feature is a **brand-new element name** — Show Custom Dialog's window size, Save a Copy as XML's new options — 2025 has no slot for it, correctly drops it, and the clipboard is clean.

So FileMaker 2025 is capable of doing this right, and does, most of the time. The leak is inconsistent with its own correct behaviour, which is what makes it a bug rather than a design choice.

**Why we are not filing it: nobody is affected.** A 2025 user never sees the leaked data — the option does not exist in their version, the interface shows nothing, and pasting the polluted clipboard back into 2025 does nothing at all. The data is not lost either, because it is still in the file: open that same file in 2026 again and the feature is intact. The only software that ever notices is a tool like ai2fm, which reads the clipboard directly and would otherwise show a 2025 developer a control their FileMaker does not have. We handle it on our side and move on.

That is the distinction worth holding on to. Everything else on this page **destroys or corrupts something a developer deliberately set** — a template name, a credential, an operation, a read size. This one shuffles bytes nobody will ever look at. Both are bugs; only one is worth a report.

---

## Community workaround

Takahata-san ([@stbison](https://github.com/stbison)) took the time to work through these same FileMaker 2026 clipboard bugs and write up a manual workaround — a practical option for anyone not using ai2fm. Worth a read, and our thanks for the effort:

- [Silent-drop bugs in FileMaker 2026 — workaround strategy](https://gist.github.com/stbison/1d9b46ec906c600fc3c02d0746f95078)

---
