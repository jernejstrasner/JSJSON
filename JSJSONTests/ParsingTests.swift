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
        let jsonString = SWIFTAssertNoThrow(try loadJSON("movies"))!

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

        let data = SWIFTAssertNoThrow(try JSON.parse(jsonString))
        XCTAssert(data != nil)

        // Check some data integrity
        if let data = data {
            SWIFTAssertEqual(data[0]?["country"]?.string, "Francija")
            SWIFTAssertEqual(data[2]?["duration"]?.number, 151)
            SWIFTAssertEqual(data.last?["shows"]?.last?["showID"]?.string, "e810b3a91a07aab8ddf92c50c5c93fc541afcfdc6132ce66965d4ee231506a42")
        }
    }

    func testCrazyParsing() {
        let jsonString = SWIFTAssertNoThrow(try loadJSON("crazy"))!

        // NSJSONSerialization is not able to parse this thing
        SWIFTAssertThrows(try NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: []))

        // We can!
        let data = SWIFTAssertNoThrow(try JSON.parse(jsonString))
        XCTAssert(data != nil)
    }

    func testCocoaSpeed() {
        let jsonString = SWIFTAssertNoThrow(try loadJSON("movies"))!

        measureBlock {
            do {
                try NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
            } catch {}
        }
    }

    func testSpeed() {
        let jsonString = SWIFTAssertNoThrow(try loadJSON("movies"))!

        measureBlock {
            do {
                try JSON.parse(jsonString)
            } catch {}
        }
    }

    func testBigSpeedCocoa() {
        let jsonString = SWIFTAssertNoThrow(try loadJSON("1meg"))!

        measureBlock {
            do {
                try NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
            } catch {}
        }
    }

    func testBigSpeed() {
        let jsonString = SWIFTAssertNoThrow(try loadJSON("1meg"))!

        measureBlock {
            do {
                try JSON.parse(jsonString)
            } catch {}
        }
    }

}