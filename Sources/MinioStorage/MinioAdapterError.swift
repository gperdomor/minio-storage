//
//  MinioAdapterError.swift
//  MinioStorage
//
//  Created by Gustavo Perdomo on 5/3/18.
//  Copyright © 2018 Gustavo Perdomo. All rights reserved.
//

import Debugging

/// Errors that can be thrown while working with Local Adapter.
public struct MinioAdapterError: Debuggable {
    public static let readableName = "Minio Adapter Error"
    public let identifier: String
    public var reason: String
    public var sourceLocation: SourceLocation?
    public var stackTrace: [String]
    public var suggestedFixes: [String]
    public var possibleCauses: [String]

    init(identifier: String, reason: String, suggestedFixes: [String] = [], possibleCauses: [String] = [], source: SourceLocation) {
        self.identifier = identifier
        self.reason = reason
        self.sourceLocation = source
        self.stackTrace = MinioAdapterError.makeStackTrace()
        self.suggestedFixes = suggestedFixes
        self.possibleCauses = possibleCauses
    }
}
