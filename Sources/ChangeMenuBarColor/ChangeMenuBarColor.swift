//
//  ChangeMenuBarColor.swift
//  ChangeMenuBarColor
//
//  Created by Igor Kulman on 19.11.2020.
//

import ArgumentParser
import Foundation
import Cocoa

struct ChangeMenuBarColor: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ChangeMenuBarColor",
        abstract: "A Swift command-line tool to create a custom menu bar color wallpaper for macOS",
        discussion: """
            This tool modifies wallpapers to change the menu bar color in macOS Big Sur and later.
            It works by appending a solid color or gradient rectangle to the top of a wallpaper image.

            For displays with notches (MacBook Pro 14"/16"), the tool automatically detects and uses
            the correct menu bar height.
            """,
        version: "2.0.0",
        subcommands: [SolidColor.self, Gradient.self, DiagnosticCommand.self],
        defaultSubcommand: SolidColor.self
    )
}
