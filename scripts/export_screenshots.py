#!/usr/bin/env python3
"""Export screenshot attachments from an .xcresult bundle produced by `xcodebuild test`.

`xcresulttool get` without --id only returns the shallow top-level summary;
the actual per-test attachments are reached by following nested Reference
objects (testsRef -> summaries -> test -> summaryRef -> activitySummaries ->
attachments). This walks the tree and resolves every Reference it finds, then
collects any ActionTestAttachment nodes (the screenshots attached via
XCTAttachment in the UI test) and exports each one as a PNG.

Safe to run even if the result bundle is missing or has no attachments.
"""
import json
import os
import subprocess
import sys

RESULT_BUNDLE = "TestResults.xcresult"
OUTPUT_DIR = "UITestScreenshots"


def xcresulttool_get(ref_id=None):
    args = ["xcrun", "xcresulttool", "get", "--legacy", "--path", RESULT_BUNDLE, "--format", "json"]
    if ref_id:
        args += ["--id", ref_id]
    out = subprocess.check_output(args)
    return json.loads(out)


def collect(node, attachments, visited):
    if isinstance(node, dict):
        type_name = node.get("_type", {}).get("_name")

        if type_name == "ActionTestAttachment":
            name = node.get("name", {}).get("_value", "screenshot")
            payload_id = node.get("payloadRef", {}).get("id", {}).get("_value")
            if payload_id:
                attachments.append((name, payload_id))

        if type_name == "Reference":
            ref_id = node.get("id", {}).get("_value")
            if ref_id and ref_id not in visited:
                visited.add(ref_id)
                try:
                    referenced = xcresulttool_get(ref_id)
                    collect(referenced, attachments, visited)
                except subprocess.CalledProcessError as exc:
                    print(f"Warning: could not resolve reference {ref_id}: {exc}", file=sys.stderr)

        for key, value in node.items():
            if key != "_type":
                collect(value, attachments, visited)
    elif isinstance(node, list):
        for item in node:
            collect(item, attachments, visited)


def main():
    if not os.path.isdir(RESULT_BUNDLE):
        print(f"No result bundle at {RESULT_BUNDLE}; nothing to export.")
        return

    root = xcresulttool_get()
    attachments = []
    collect(root, attachments, visited=set())

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
