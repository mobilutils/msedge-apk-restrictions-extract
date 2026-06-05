#!/usr/bin/env python3
"""Parse app_restrictions.xml and strings.xml to produce JSON + CSV of MDM restrictions."""

import csv
import json
import os
import sys
import xml.etree.ElementTree as ET

NS_ATTR = "{http://schemas.android.com/apk/res/android}"


def parse_strings_xml(strings_path):
    """Parse strings.xml and return a dict mapping string name -> text content."""
    strings = {}
    try:
        tree = ET.parse(strings_path)
        root = tree.getroot()
        for elem in root.findall("string"):
            name = elem.get("name")
            text = (elem.text or "").replace("\n", " ").strip()
            if name:
                strings[name] = text
    except ET.ParseError:
        pass
    return strings


def resolve_string_ref(ref, strings):
    """Resolve a @string/REFERENCE to its actual text."""
    if ref and ref.startswith("@string/"):
        key = ref[len("@string/"):]
        return strings.get(key, ref)
    return ref


def parse_restrictions(xml_path, strings):
    """Parse app_restrictions.xml and return a list of restriction dicts."""
    restrictions = []
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        for elem in root.findall("restriction"):
            restriction = {
                "key": elem.get(f"{NS_ATTR}key", ""),
                "title": resolve_string_ref(elem.get(f"{NS_ATTR}title"), strings),
                "default_value": elem.get(f"{NS_ATTR}defaultValue", ""),
                "type": elem.get(f"{NS_ATTR}restrictionType", ""),
                "description": resolve_string_ref(elem.get(f"{NS_ATTR}description"), strings),
            }
            restrictions.append(restriction)
    except ET.ParseError:
        print(f"Error: Failed to parse {xml_path}", file=sys.stderr)
        sys.exit(1)
    return restrictions


def main():
    apk_dir = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    xml_path = os.path.join(apk_dir, "app_restrictions.xml")
    strings_path = os.path.join(apk_dir, "strings.xml")
    json_path = os.path.join(apk_dir, "app_restrictions_consolidated.json")
    csv_path = os.path.join(apk_dir, "app_restrictions_consolidated.csv")

    if not os.path.isfile(xml_path):
        print(f"Error: {xml_path} not found.", file=sys.stderr)
        sys.exit(1)

    # Load string resources (optional - if missing, raw @string/ refs are kept)
    strings = {}
    if os.path.isfile(strings_path):
        strings = parse_strings_xml(strings_path)

    # Parse restrictions
    restrictions = parse_restrictions(xml_path, strings)

    # Write JSON
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(restrictions, f, indent=2, ensure_ascii=False)
    print(f"Written: {json_path} ({len(restrictions)} entries)")

    # Write CSV
    fieldnames = ["key", "title", "default_value", "type", "description"]
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        writer.writerows(restrictions)
    print(f"Written: {csv_path} ({len(restrictions)} entries)")


if __name__ == "__main__":
    main()
