//
//  SkyletHarness.swift
//  SkyletHarness
//
//  The harness executable for local preview and automated headless screenshot capture.
//  Run with:
//      swift run SkyletHarness
//  Or headless capture:
//      swift run SkyletHarness -- --shots ./shots --report ./shots/report.json
//

import DroppyKit
import DroppyKitHarness
import Skylet

@main
struct SkyletHarness: DropletHarnessApp {
    static func makeDroplet() -> any Droplet { SkyletDroplet() }
}

