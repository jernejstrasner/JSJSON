//
//  JSONParserTests.swift
//  JSJSON
//
//  Created by Jernej Strasner on 12/29/14.
//  Copyright (c) 2014 Jernej Strasner. All rights reserved.
//

import XCTest

class JSONParserTests: XCTestCase {

    func testDecoding() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let url = bundle.URLForResource("movies", withExtension: "json")
        let jsonString = String(contentsOfURL: url!, encoding: NSUTF8StringEncoding, error: nil)
        XCTAssert(jsonString != nil)

        let json = JSONParser(jsonString!).parse()
        if let a = json as? JArray {
            println(a)
        }
    }

}