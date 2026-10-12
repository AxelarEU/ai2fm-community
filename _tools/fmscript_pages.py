#!/usr/bin/env python3
"""Give every published .fmscript a coloured companion page.

For each fmscript-standard/**/X.fmscript this writes X.md next to it: the script in an
```fmscript block (coloured by the site's colouriser) and a Download link to the raw file.
Jekyll turns X.md into X.html, and layout `standard` points the step page's example links
there. Re-run after copying a step folder in from the ai2fm-auto bundle:

    python3 _tools/fmscript_pages.py
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "fmscript-standard"

def main() -> None:
    made = 0
    for script in sorted(ROOT.rglob("*.fmscript")):
        text = script.read_text(encoding="utf-8").replace("\r\n", "\n").rstrip("\n")
        fence = "````" if "```" in text else "```"
        back = ""
        for md in sorted(script.parent.glob("*.md")):
            if md.stem != script.stem and not (script.parent / f"{md.stem}.fmscript").exists():
                head = md.read_text(encoding="utf-8").split("\n---", 1)[0]
                title = next((l.split(":", 1)[1].strip().strip('"') for l in head.splitlines()
                              if l.startswith("title:")), md.stem)
                back = f"[← {title}]({md.stem}.html) · "
                break
        page = (
            "---\n"
            f"title: \"{script.stem}\"\n"
            "---\n\n"
            f"# {script.stem}\n\n"
            f"{back}<a href=\"{script.name}\" download>Download {script.name}</a>\n\n"
            f"{fence}fmscript\n{text}\n{fence}\n"
        )
        out = script.with_suffix(".md")
        if not out.exists() or out.read_text(encoding="utf-8") != page:
            out.write_text(page, encoding="utf-8")
            made += 1
    print(f"companion pages written: {made}")

if __name__ == "__main__":
    main()
