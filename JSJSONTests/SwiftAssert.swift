//
//  SwiftAssert.swift
//  JSJSON
//
//  Created by Jernej Strasner on 7/8/15.
//  Copyright © 2015 Jernej Strasner. All rights reserved.
//

import XCTest

public func AssertThrows<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        try expression()
        XCTFail("No error to catch! - \(message)", file: file, line: line)
    } catch {
    }
}

public func AssertThrows<T, E: ErrorType>(expectedError: E, @autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        try expression()
        XCTFail("No error to catch! - \(message)", file: file, line: line)
    } catch expectedError {
    } catch {
        XCTFail("Error caught, but of non-matching type: \(error)")
    }
}

public func AssertNoThrow<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) -> T? {
    do {
        return try expression()
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
        return nil
    }
}

public func AssertNoThrowEqual<T : Equatable>(@autoclosure expression1: () -> T, @autoclosure _ expression2: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        let result1 = expression1()
        let result2 = try expression2()
        XCTAssert(result1 == result2, "\"\(result1)\" is not equal to \"\(result2)\" - \(message)")
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}

public func AssertNoThrowValidateValue<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__, _ validator: (T) -> Bool) {
    do {
        let result = try expression()
        XCTAssert(validator(result), "Value validation failed - \(message)", file: file, line: line)
    } catch let error {
        XCTFail("Caught error: \(error) - \(message)", file: file, line: line)
    }
}

public func AssertEqual<T: Equatable>(@autoclosure f: () -> T?, @autoclosure _ g: () -> T?, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    let resultF = f()
    let resultG = g()
    XCTAssert(resultF == resultG, "\"\(resultF)\" is not equal to \"\(resultG)\" - \(message)")
}

// By Marious Rackwitz
// https://realm.io/news/testing-swift-error-type/

func ~=(lhs: ErrorType, rhs: ErrorType) -> Bool {
    return lhs._domain == rhs._domain && rhs._code == rhs._code
}
