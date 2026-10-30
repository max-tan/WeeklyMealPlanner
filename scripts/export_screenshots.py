#!/usr/bin/env python3
"""Export screenshot attachments from an .xcresult bundle produced by `xcodebuild test`.

Walks the legacy xcresulttool JSON graph looking for ActionTestAttachment nodes
(the screenshots attached via XCTAttachment in the UI test) and exports each one
as a PNG. Safe to run even if the result bundle is missing or has no attachments.
"""
import json
import os
import subprocess
import sys

RESULT_BUNDLE = "TestResults.xcresult"
OUTPUT_DIR = "UITestScreenshots"


def run_json(args):
    out = subprocess.check_output(args)
    return json.loads(out)


def walk(node, attachments):
    if isinstance(node, dict):
        type_name = node.get("_type", {}).get("_name")
        if type_name == "ActionTestAttachment":
            name = node.get("name", {}).get("_value", "screenshot")
            payload_id = node.get("payloadRef", {}).get("id", {}).get("_value")
            if payload_id:
                attachments.append((name, payload_id))
        for key, value in node.items():
            if key != "_type":
                walk(value, attachments)
    elif isinstance(node, list):
        for item in node:
            walk(item, attachments)


def main():
    if not os.path.isdir(RESULT_BUNDLE):
        print(f"No result bundle at {RESULT_BUNDLE}; nothing to export.")
        return

    root = run_json(["xcrun", "xcresulttool", "get", "--legacy",
                      "--path", RESULT_BUNDLE, "--format", "json"])
    attachments = []
    walk(root, attachments)

    if not attachments:
        print("No screenshot attachments found in test results.")
        return

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    seen = {}
    for name, payload_id in attachments:
        seen[name] = seen.get(name, 0) + 1
        suffix = f"-{seen[name]}" if seen[name] > 1 else ""
        safe_name = "".join(c for c in name if c.isalnum() or c in "-_.") or "screenshot"
        dest = os.path.join(OUTPUT_DIR, f"{safe_name}{suffix}.png")
        subprocess.check_call([
            "xcrun", "xcresulttool", "export", "--legacy",
            "--path", RESULT_BUNDLE,
            "--id", payload_id,
            "--output-path", dest,
            "--type", "file",
        ])
        print(f"Exported {dest}")


if __name__ == "__main__":
    sys.exit(main())
