//
//  ViewController.swift
//  SpotCrime
//
//  Created by Nilesh on 1/16/16.
//  Copyright © 2016 CA. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController,NSURLSessionDelegate,MKMapViewDelegate{

    //IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    var dataPoints:[DataPoints] = [DataPoints]()
    var districts:[DistrictPoints] = [DistrictPoints]()
    var districtNameAsPerCrimeFrequency:[String] = [String]()

    //MARK: Initialization
    //Center point of the starting location.
    let startLocation = CLLocation(latitude: 37.773972, longitude: -122.431297	)
    //The distance mentioned is in meters.
    let initialRadius:CLLocationDistance = 10000

    //MARK: View Controller Methods.
    override func viewDidLoad() {
        super.viewDidLoad()
        centerMapOnLocation(startLocation)
        checkLocationAuthorizationStatus()
        mapView.delegate = self
        loadDataFromSODAApi()
    }

    //MARK: Setup Methods
    func centerMapOnLocation(location:CLLocation){
        let coordinateRegion:MKCoordinateRegion! = MKCoordinateRegionMakeWithDistance(location.coordinate, initialRadius * 2.0, initialRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func loadDataFromSODAApi(){
        let session:NSURLSession! = NSURLSession.sharedSession()
        let url:NSURL! = NSURL(string: "https://data.sfgov.org/resource/ritf-b9ki.json")
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error in
        guard let actualData = data else{
            return
        }
        do{
            let jsonResult:NSArray = try NSJSONSerialization.JSONObjectWithData(actualData, options: NSJSONReadingOptions.MutableLeaves) as! NSArray
            print("\(jsonResult.count)")
             dispatch_async(dispatch_get_main_queue(), {
             for item in jsonResult {
                let dataDictionary = item as! NSDictionary
                let datapoint:DataPoints! = DataPoints.fromDataArray(dataDictionary)
                self.dataPoints.append(datapoint)
                }
                self.districtNameAsPerCrimeFrequency = self.sortDistrictAsPerCrimeCount()
                self.getAllDistricts()
                self.mapView.addAnnotations(self.dataPoints)
            })
        }catch let parseError{
                print("Response Status\(parseError)")
            }
        })
        task.resume()
    }


    func getAllDistricts() {
        //Fetch the file
        let thePath:String! = NSBundle.mainBundle().pathForResource("sfpddistricts", ofType: "geojson")
        //Check if the file exists
        let fileExists:Bool = NSFileManager.defaultManager().fileExistsAtPath(thePath)
        if fileExists {
            print("File exists ")
        }else{
            print("Files does not exists")
            return
        }

        let data:NSData!
        var pointsDictionary:NSDictionary!
        do{
          data =   try NSData.init(contentsOfFile: thePath, options: .DataReadingMappedIfSafe)
          pointsDictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
        }catch{
            return
        }
        let districtsArray:NSArray = pointsDictionary.objectForKey("features") as! NSArray
        for item in districtsArray {
            let districtDictionary:NSDictionary! = item as! NSDictionary
            let properties:NSDictionary! = districtDictionary.objectForKey("properties") as! NSDictionary
            let districtName:String! = properties.objectForKey("DISTRICT") as! String
            let geomertry:NSDictionary! = districtDictionary.objectForKey("geometry") as! NSDictionary
            let type:String! = geomertry.objectForKey("type") as! String
            if type == "Polygon"{
            let coordinates:NSArray! = geomertry.objectForKey("coordinates") as! NSArray
            var pointsToUse:[CLLocationCoordinate2D] = []
            var districtPoint:DistrictPoints! = nil;
            for coordinates_elements in coordinates {
                let coordinate_array:NSArray!  = coordinates_elements as! NSArray
                for coordinates_object in coordinate_array {
                    let x_y_coordinatesArray:NSArray! = coordinates_object as! NSArray
                    let x:Double = Double(x_y_coordinatesArray[0] as! NSNumber)
                    let y:Double = Double(x_y_coordinatesArray[1] as! NSNumber)
                    pointsToUse += [(CLLocationCoordinate2DMake(CLLocationDegrees(y), CLLocationDegrees(x)))]
                }
            }
            districtPoint = DistrictPoints.init(districtName: districtName, coordinate: pointsToUse)
            self.districts.append(districtPoint)
            let polygon = MKPolygon(coordinates: &districtPoint.coordinate, count: districtPoint.coordinate.count)
            polygon.title = districtName
            self.mapView.addOverlay(polygon)
            }
        }
    }

    func sortDistrictAsPerCrimeCount()->[String]{
        DataObject.sharedInstance.districtData.allKeys
        var crimeCount:[Int] = DataObject.sharedInstance.districtData.allValues as! [Int]
        //Sorting in descending order.
        crimeCount = crimeCount.sort{ $0 > $1 }
        var sortedDistrict:[String] = [String]()
        for item in crimeCount {
            let tempItem:[String] = DataObject.sharedInstance.districtData.allKeysForObject(item) as! [String]
            sortedDistrict.appendContentsOf(tempItem)
        }
        return sortedDistrict
    }



    func addAllDistricts(){
        for item in districts {
            let districtpoints:DistrictPoints = item
            let polygon = MKPolygon(coordinates: &districtpoints.coordinate, count: districtpoints.coordinate.count)
            self.mapView.addOverlay(polygon)
        }
    }


    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?{
        if let annotation:DataPoints! = annotation as! DataPoints{
            let identifier = "pin"
            var view:MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier("pin") as? MKPinAnnotationView{
                dequeuedView.annotation = annotation
                view = dequeuedView
                view.pinTintColor = colorForDistricts(annotation.district)
                return view;
            }else{
                 view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                 view.pinTintColor = colorForDistricts(annotation.district)
                return view;
            }
        }
        return nil;
    }

    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let polygonView = MKPolygonRenderer(overlay: overlay)
        polygonView.strokeColor = colorForDistricts(overlay.title!)
        return polygonView
    }


    func colorForDistricts(title:String!)->UIColor{
        switch title {
            case self.districtNameAsPerCrimeFrequency[0]:
                return UIColor(red: 1, green: 0, blue: 0, alpha: 1)

            case self.districtNameAsPerCrimeFrequency[1]:
                return UIColor(red: 0.922, green: 0.212, blue: 0, alpha: 1)

            case self.districtNameAsPerCrimeFrequency[2]:
                return UIColor(red: 0.898, green: 0.282, blue: 0, alpha: 1)

            case self.districtNameAsPerCrimeFrequency[3]:
                return UIColor(red: 0.847, green: 0.427, blue: 0, alpha: 1)

            case self.districtNameAsPerCrimeFrequency[4]:
                return UIColor(red: 0.824, green: 0.428, blue: 0, alpha: 1)

            case self.districtNameAsPerCrimeFrequency[5]:
                return UIColor(red: 0.773, green: 0.639, blue: 0, alpha: 1)

            case self.districtNameAsPerCrimeFrequency[6]:
                return UIColor(red: 0.725, green: 0.784, blue: 0, alpha: 1)
            default:
                return UIColor(red: 0.651, green: 1, blue: 0, alpha: 1)
        }
    }
}

