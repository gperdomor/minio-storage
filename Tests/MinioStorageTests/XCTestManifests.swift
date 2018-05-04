//
//  XCTestManifests.swift
//  MinioStorage
//
//  Created by Gustavo Perdomo on 5/3/18.
//  Copyright © 2018 Gustavo Perdomo. All rights reserved.
//

import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MinioStorageTests.allTests)
    ]
}
#endif
