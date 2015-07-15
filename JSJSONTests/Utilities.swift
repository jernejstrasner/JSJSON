//
//  Utilities.swift
//  JSJSON
//
//  Created by Jernej Strasner on 7/15/15.
//  Copyright © 2015 Jernej Strasner. All rights reserved.
//

import XCTest

extension XCTest {

    enum Error : ErrorType {
        case MissingFile
    }

    func loadJSON(fileName: String) throws -> String {
        let bundle = NSBundle(forClass: self.dynamicType)
        if let url = bundle.URLForResource(fileName, withExtension: "json") {
            return try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
        }
        throw Error.MissingFile
    }
    
}