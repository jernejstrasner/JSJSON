//
//  SwiftAssert.swift
//  JSJSON
//
//  Created by Jernej Strasner on 7/8/15.
//  Copyright © 2015 Jernej Strasner. All rights reserved.
//

import XCTest

func SWIFTAssertThrows<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) -> T? {
    do {
        let result = try expression()
        XCTFail("No error to catch! - \(message)", file: file, line: line)
        return result
    } catch {
        return nil
    }
}

func SWIFTAssertNoThrow<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) -> T? {
    do {
        return try expression()
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
        return nil
    }
}

func SWIFTAssertNoThrowEqual<T : Equatable>(@autoclosure expression1: () -> T, @autoclosure _ expression2: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        let result2 = try expression2()
        XCTAssertEqual(expression1, result2, message, file: file, line: line)
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}

func SWIFTAssertNoThrowValidateValue<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__, _ validator: (T) -> Bool) {
    do {
        let result = try expression()
        XCTAssert(validator(result), "Value validation failed - \(message)", file: file, line: line)
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}

func SWIFTAssertEqual<T: Equatable>(@autoclosure f: () -> T?, @autoclosure _ g: () -> T?, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    let resultF = f()
    let resultG = g()
    XCTAssert(resultF == resultG, "\"\(resultF)\" is not equal to \"\(resultG)\"")
}
