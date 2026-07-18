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

## Configure Machine Learning Model (step 202) — the structure changed, and a bad paste becomes a *different* command

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

## Independent verification

You do not have to take our word for these bugs, and you do not need ai2fm to work around them. Takahata-san ([@stbison](https://github.com/stbison)) independently documented the same set of FileMaker 2026 clipboard bugs and published a manual workaround strategy — a bridge for anyone not using ai2fm:

- [Silent-drop bugs in FileMaker 2026 — workaround strategy](https://gist.github.com/stbison/1d9b46ec906c600fc3c02d0746f95078)

That an independent developer reproduced and catalogued the same defects is the strongest confirmation we can offer that they are real.

---
