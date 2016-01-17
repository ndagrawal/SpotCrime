//
//  DistrictPoints.swift
//  SpotCrime
//
//  Created by Nilesh on 1/16/16.
//  Copyright © 2016 CA. All rights reserved.
//

import UIKit
import MapKit

class DistrictPoints: NSObject {

    var districtName:String
    var coordinate:[CLLocationCoordinate2D]

    init(districtName:String,coordinate:[CLLocationCoordinate2D]){
        self.districtName = districtName
        self.coordinate = coordinate
        super.init()
    }

}
