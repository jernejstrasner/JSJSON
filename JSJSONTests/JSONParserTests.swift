//
//  JSONParserTests.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/29/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

import XCTest

class JSONParserTests: XCTestCase {

    func testSimpleParsing() {
        let jsonString = loadJSON("movies")
        XCTAssert(jsonString != nil)

        var error: NSError?
        let jsonObj: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: &error)
        XCTAssert(jsonObj != nil)
        XCTAssert(error == nil)

        let json = JSONParser(jsonString!).parse()
        XCTAssert(json != nil)

        // Check integrity
        if let a = json as? JArray {
            XCTAssert((a[0] as? JObject) != nil, "Not a valid title!")
        }
    }

    func testCrazyParsing() {
        let jsonString = loadJSON("crazy")
        XCTAssert(jsonString.utf16Count > 0)

        // NSJSONSerialization is not able to parse this thing
        var error: NSError?
        let jsonObj: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: &error)
        XCTAssert(jsonObj == nil)
        XCTAssert(error != nil)

        // We can!
        let json = JSONParser(jsonString!).parse()
        XCTAssert(json != nil)
    }

    func testCocoaSpeed() {
        let jsonString = loadJSON("movies")

        measureBlock {
            let jsonObj: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: nil, error: nil)
        }
    }

    func testInitSpeed() {
        let jsonString = loadJSON("crazy")
        measureBlock {
            let parser = JSONParser(jsonString!)
        }
    }

    func testParsingSpeed() {
        let jsonString = loadJSON("movies")
        measureMetrics([XCTPerformanceMetric_WallClockTime], automaticallyStartMeasuring: false) {
            let parser = JSONParser(jsonString!)
            self.startMeasuring()
            let json = parser.parse()
            self.stopMeasuring()
        }
    }

    func testCompleteSpeed() {
        let jsonString = loadJSON("movies")
        measureBlock {
            let json = JSONParser(jsonString!).parse()
        }
    }

    func testCompleteSpeedCrazy() {
        let jsonString = loadJSON("crazy")
        measureBlock {
            let json = JSONParser(jsonString!).parse()
        }
    }

    func loadJSON(fileName: String) -> String! {
        let bundle = NSBundle(forClass: self.dynamicType)
        let url = bundle.URLForResource(fileName, withExtension: "json")
        return String(contentsOfURL: url!, encoding: NSUTF8StringEncoding, error: nil)
    }

}