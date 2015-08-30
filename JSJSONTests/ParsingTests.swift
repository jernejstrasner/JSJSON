//
//  JSONTests.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/29/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

import XCTest
import JSON

class ParsingTests: XCTestCase {

    func testSimpleParsing() {
        let jsonString = AssertNoThrow(try loadJSON("movies"))!

        var error: NSError?
        let jsonObj: AnyObject?
        do {
            jsonObj = try NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
        } catch let error1 as NSError {
            error = error1
            jsonObj = nil
        }
        XCTAssert(jsonObj != nil)
        XCTAssert(error == nil)

        let data = AssertNoThrow(try JSON.parse(jsonString))
        XCTAssert(data != nil)

        // Check some data integrity
        if let data = data {
            AssertEqual(data[0]?["country"]?.string, "Francija")
            AssertEqual(data[2]?["duration"]?.number, 151)
            AssertEqual(data.last?["shows"]?.last?["showID"]?.string, "e810b3a91a07aab8ddf92c50c5c93fc541afcfdc6132ce66965d4ee231506a42")
        }
    }

    func testCrazyParsing() {
        let jsonString = AssertNoThrow(try loadJSON("crazy"))!

        // NSJSONSerialization is not able to parse this thing
        AssertThrows(try NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: []))

        // We can!
        let data = AssertNoThrow(try JSON.parse(jsonString))
        XCTAssert(data != nil)
    }

}