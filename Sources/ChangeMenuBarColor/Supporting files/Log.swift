//
//  Log.swift
//  ChangeMenuBarColor
//
//  Created by Igor Kulman on 14.12.2020.
//

import Foundation
import Rainbow

enum Log: Sendable {
    static func error(_ message: String) {
        print(message.red.bold)
    }

    static func info(_ message: String) {
        print(message.green)
    }

    static func debug(_ message: String) {
        print(message.dim)
    }

    static func warning(_ message: String) {
        print(message.yellow)
    }
}
