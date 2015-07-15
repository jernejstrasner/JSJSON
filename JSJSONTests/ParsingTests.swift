//
//  JSONParserTests.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/29/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

import XCTest

class ParsingTests: XCTestCase {

    func testSimpleParsing() {
        let jsonString = loadJSON("movies")
        XCTAssert(jsonString != nil)

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

        let parser = JSONParser(jsonString)
        XCTAssert(parser != nil)
        let data = SWIFTAssertNoThrow(try parser!.parse())
        XCTAssert(data != nil)

        // Check some data integrity
        if let data = data {
            SWIFTAssertEqual(data[0]?["country"]?.string, "Francija")
            SWIFTAssertEqual(data[2]?["duration"]?.number, 151)
            SWIFTAssertEqual(data.last?["shows"]?.last?["showID"]?.string, "e810b3a91a07aab8ddf92c50c5c93fc541afcfdc6132ce66965d4ee231506a42")
        }
    }

    func testCrazyParsing() {
        let jsonString = loadJSON("crazy")
        XCTAssert(jsonString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0)

        // NSJSONSerialization is not able to parse this thing
        SWIFTAssertThrows(try NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: []))

        // We can!
        let parser = JSONParser(jsonString)
        XCTAssert(parser != nil)
        let data = SWIFTAssertNoThrow(try parser!.parse())
        XCTAssert(data != nil)
    }

    func testCocoaSpeed() {
        let jsonString = loadJSON("movies")

        measureBlock {
            do {
                try NSJSONSerialization.JSONObjectWithData(jsonString.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
            } catch {}
        }
    }

    func testSpeed() {
        let jsonString = loadJSON("movies")
        measureBlock {
            do {
                try JSONParser(jsonString)!.parse()
            } catch {}
        }
    }

    func testSpeedCrazy() {
        let jsonString = loadJSON("crazy")
        measureBlock {
            do {
                try JSONParser(jsonString!)!.parse()
            } catch {}
        }
    }

//    func testNumberConversion() {
//        XCTAssert(toNumber("399") == 399)
//        XCTAssert(toNumber("1.53") == 1.53)
//        XCTAssert(toNumber("-0.344") == -0.344)
//        XCTAssert(toNumber("1.3e4") == 1.3e4)
//    }

    func loadJSON(fileName: String) -> String! {
        let bundle = NSBundle(forClass: self.dynamicType)
        let url = bundle.URLForResource(fileName, withExtension: "json")
        do {
            return try String(contentsOfURL: url!, encoding: NSUTF8StringEncoding)
        } catch {
            return nil
        }
    }

//    func toNumber(s: String) -> Double! {
//        let a = ((s as NSString).UTF8String, (s as NSString).lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
//        return JSONParser(s)!.convertToNumber(a)
//    }

}