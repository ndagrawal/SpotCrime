//
//  DataPoints.swift
//  SpotCrime
//
//  Created by Nilesh on 1/16/16.
//  Copyright © 2016 CA. All rights reserved.
//

import UIKit
import MapKit
import Contacts

class DataPoints: NSObject,MKAnnotation{

    let title:String?
    let locationName:String!
    let district:String!
    let coordinate:CLLocationCoordinate2D
    init(title:String,locationName:String,district:String,coordinate:CLLocationCoordinate2D){
        self.title = title
        self.locationName = locationName
        self.district = district
        self.coordinate = coordinate
        super.init()
    }

    class func fromDataArray(dataDictionary:NSDictionary!)->DataPoints?{
                let address:String! = dataDictionary["address"] as! String
                let category:String! = dataDictionary["category"] as! String
                //let date:String! = dataDictionary["date"] as! String
                let descript:String! = dataDictionary["descript"] as! String
                let location:NSDictionary! = dataDictionary["location"] as! NSDictionary
                let latitude:Double! = Double(location["latitude"] as! String)!
                let longitude:Double! = Double(location["longitude"] as! String)
                let pddDistrict = dataDictionary["pddistrict"] as! String
                if (DataObject.sharedInstance.districtData.objectForKey(pddDistrict) != nil) {
                    var count = DataObject.sharedInstance.districtData.objectForKey(pddDistrict) as! Int
                    count += 1
                    let num:NSNumber! = NSNumber(integer: count)
                    DataObject.sharedInstance.districtData.setValue(num, forKey: pddDistrict)
                }else{
                    let number:NSNumber! = NSNumber(integer: 1)
                    DataObject.sharedInstance.districtData.setValue(number, forKey: pddDistrict)
                }
                let titleForPoint:String! = "\(category):\(descript)"
                let subtitleForPoint:String! = "\(address):\(pddDistrict)"
                let location2d:CLLocationCoordinate2D = CLLocationCoordinate2D.init(latitude: latitude!, longitude: longitude!)
            return DataPoints.init(title: titleForPoint, locationName: subtitleForPoint, district: pddDistrict, coordinate: location2d)
    }

    // annotation callout info button opens this mapItem in Maps app
    func mapItem() -> MKMapItem {
        let addressDictionary:[String:String!] = [String(CNPostalAddressStreetKey): subtitle]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDictionary)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        return mapItem
    }

    var subtitle:String?{
        return locationName
    }
}
