//
//  JSONSpeedTests.swift
//  JSONSpeedTests
//
//  Created by Jernej Strasner on 8/7/15.
//  Copyright © 2015 Jernej Strasner. All rights reserved.
//

import XCTest
import JSON

class ParsingSpeedTests: XCTestCase {
    
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
