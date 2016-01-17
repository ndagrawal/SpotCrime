//
//  DataObject.swift
//  SpotCrime
//
//  Created by Nilesh on 1/16/16.
//  Copyright © 2016 CA. All rights reserved.
//

import Foundation

class DataObject: NSObject {
     static let sharedInstance = DataObject()
     var districtData:NSMutableDictionary = NSMutableDictionary()
}