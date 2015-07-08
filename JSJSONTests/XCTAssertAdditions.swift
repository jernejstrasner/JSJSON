//
//  XCTAssertAdditions.swift
//  JSJSON
//
//  Created by Jernej Strasner on 7/8/15.
//  Copyright © 2015 Jernej Strasner. All rights reserved.
//

import XCTest

func XCTAssertThrows<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        try expression()
        XCTFail("No error to catch! - \(message)", file: file, line: line)
    } catch {
    }
}

func XCTAssertNoThrow<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        try expression()
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}

//func XCTAssertThrowsSpecific<T>(@autoclosure expression: () throws -> T, _ type: ErrorType, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
//    do {
//        try expression()
//        XCTFail("No error to catch! - \(message)", file: file, line: line)
//    } catch type {
//        print("Yay")
//    } catch {
//        XCTFail("Caught an error but it's not equal to \(type) - \(message)")
//    }
//}

// TODO: XCTAssertThrowsSpecific
// TODO: XCTAssertNoThrowSpecific

func XCTAssertNoThrowEqual<T : Equatable>(@autoclosure expression1: () -> T, @autoclosure _ expression2: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        let result2 = try expression2()
        XCTAssertEqual(expression1, result2, message, file: file, line: line)
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}

func XCTAssertNoThrowValidateValue<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__, _ validator: (T) -> Bool) {
    do {
        let result = try expression()
        XCTAssert(validator(result), "Value validation failed - \(message)", file: file, line: line)
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}
