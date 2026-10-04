# Benchmark: fmIDE, one script, 5,452 steps

This is the main script of **[fmIDE](https://github.com/fmIDE/fmIDE)** by **Russell Watson** ([@mrwatson-de](https://github.com/mrwatson-de)). It has 5,452 steps. Most of that is **[fmJAML](https://github.com/fmIDE/fmJAML)**, Russell's language for describing JSON, written as one `Let` calculation of more than 800 lines.

It is a hard script for any tool: very large calculations, deep MBS integration, and comments and strings full of the brackets and quotes that a parser can trip over. That is why we use it as our benchmark.

## The four files

| File | Lines | What it is |
|---|---:|---|
| [`fmIDE_clipboard.xml`](fmIDE_clipboard.xml) | 37,162 | **The source of truth.** What FileMaker Pro puts on the clipboard when you copy the script's steps. |
| [`fmIDE_SaXML.xml`](fmIDE_SaXML.xml) | 71,945 | The same script as FileMaker's **Save a Copy as XML** writes it. It describes more, and is almost twice the size. |
| [`fmIDE.fmscript`](fmIDE.fmscript) | 9,721 | The `.fmscript` that ai2fm produces from the clipboard XML: readable by people and by AI, and it diffs cleanly in Git. |
| [`fmIDE_extension_formatted.fmscript`](fmIDE_extension_formatted.fmscript) | 11,375 | The same `.fmscript` after **Format Document** in the ai2fm editor extension: calculations laid out and nested, still on one script. |
| [`fmIDE.fmp12.zip`](fmIDE.fmp12.zip) | | The FileMaker file the script lives in, so you can check every number above yourself. MIT, see [`fmIDE_LICENSE`](fmIDE_LICENSE). |

37,162 lines of XML become 9,721 lines of text: about **a quarter of the size**, with nothing dropped. The conversion runs in both directions. Paste the `.fmscript` back and FileMaker gets the script again.

## How fast

The whole clipboard, from copying in FileMaker to having the `.fmscript` open in VS Code, takes **under 6 seconds**. That includes the network round trip to our server in Germany.

## Nothing is stored

**Zero retention. No one and nothing reads your script: no person, no AI.** The only thing it passes through is the converter, a fixed set of rules that turns FileMaker's XML into text and back. No AI service is called. Your script goes in, the text comes straight back to you, and nothing is kept. No file, no database, no log.

## Try it yourself

1. Install the ai2fm extension in VS Code or any VS Code-compatible editor.
2. Unzip [`fmIDE.fmp12.zip`](fmIDE.fmp12.zip) and open `fmIDE.fmp12` in FileMaker Pro.
3. Open the **fmIDE** script in the Script Workspace, select all of its steps, and copy.
4. In the editor, run **Translate** (Ctrl+Alt+T). Compare the result with [`fmIDE.fmscript`](fmIDE.fmscript).
5. Run **Format Document** on the result.

**A note on FileMaker Pro itself.** This script is beyond what FileMaker Pro's own copy and paste can handle on a normal desktop. Copy the fmIDE script's steps and paste them into another script, entirely inside FileMaker with no other tool involved, and FileMaker takes practically forever; it needs a very fast processor. (Duplicating the script with FileMaker's **Duplicate** command is fine.) ai2fm gives you the whole script as text in under 6 seconds. Pasting a script of this size into the Script Workspace is FileMaker's work, at FileMaker's speed.

## About fmIDE and fmJAML

fmIDE and fmJAML are open source (MIT) by Russell Watson. These files are published here **with his permission**, under the license in [`fmIDE_LICENSE`](fmIDE_LICENSE). Please visit and star his work:

- **fmIDE**: <https://github.com/fmIDE/fmIDE>
- **fmJAML**: <https://github.com/fmIDE/fmJAML>

In Russell's words, at the time of publishing:

- **fmJAML is stable.** The fmJAML function is solid and not expected to change.
- **fmIDE Action Scripts (fmIDEAS) are still in development.** The action JSON is alpha, and some parameters may still change.
- **The documentation is on its way.** Until then, the current syntax is in the **Tests layout in fmIDE**.
- **Beta testers are very welcome.** Russell would be grateful for anyone who helps test it.
