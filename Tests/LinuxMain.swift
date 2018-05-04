//
//  LinuxMain.swift
//  MinioStorage
//
//  Created by Gustavo Perdomo on 5/3/18.
//  Copyright © 2018 Gustavo Perdomo. All rights reserved.
//

import XCTest

import MinioStorageTests

var tests = [XCTestCaseEntry]()
tests += MinioStorageTests.allTests()
XCTMain(tests)
