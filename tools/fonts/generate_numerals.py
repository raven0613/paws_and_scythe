"""Build the BM HANNA Pro UI subset with fonttools==4.60.1."""

import json
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont


def main():
    root = Path(__file__).resolve().parents[2]
    config = json.loads((root / "src/configs/fonts/numeral_subset.json").read_text())
    font = TTFont(root / config["source"], recalcTimestamp=False)
    options = subset.Options()
    options.name_IDs = ["*"]
    options.name_languages = ["*"]
    options.name_legacy = True
    worker = subset.Subsetter(options=options)
    worker.populate(unicodes=[
        codepoint
        for start, end in config["unicode_ranges"]
        for codepoint in range(start, end + 1)
    ])
    worker.subset(font)
    # Give the derived font its own family while retaining copyright/license names.
    names = {
        1: config["family"],
        2: "Regular",
        3: config["postscript_name"] + ":1.0",
        4: config["family"],
        6: config["postscript_name"],
        16: config["family"],
        17: "Regular",
    }
    for record in font["name"].names:
        if record.nameID in names:
            record.string = names[record.nameID].encode(record.getEncoding())
    target = root / config["output"]
    target.parent.mkdir(parents=True, exist_ok=True)
    font.save(target)
    print(f"Generated {target.relative_to(root)} ({target.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
