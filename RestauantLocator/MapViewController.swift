//
//  MapViewController.swift
//  RestauantLocator
//
//  Created by duo pan on 27/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

/* Map View
 * There is a default user location, if forget setting user location.
 * changes in map will be shown automatically when choose dispaly radius or switch views
 * All annotations are 4 parts:
   name , logo, distance from current location, and button to segue.
 * Can geo fencing
 * Can choose in which radius restaurants to show (such as within 2000m)
 * Each restaurant notification highlight circles are on or off, they are the same as their settings.
 
 * leave the refresh button just for one condition: change user location, but do not goto other view or change radius picker. The distance will not update.
 */

import UIKit
import MapKit
import CoreData
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UIPickerViewDelegate  {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var showRadiusPicker: UIPickerView!
    var showRadius: [String] = ["Infinite","5000","2000","1000","500","50"]
    
    
    let locationManager:CLLocationManager = CLLocationManager()
    var currentLocation:CLLocationCoordinate2D?
    var restaurants: [Restaurant]?
    var managedContext: NSManagedObjectContext?
    var appDelegate: AppDelegate?
    
    
    func fetchRestaurants() {
        let restaurantFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Restaurant")
        
        do {
            restaurants = try managedContext?.fetch(restaurantFetch) as? [Restaurant]
          
        } catch {
            fatalError("Failed to fetch restaurants: \(error)")
        }
    }
    
    // init once
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Restaurants Map"
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate!.persistentContainer.viewContext
        
        showRadiusPicker.delegate = self
        
        
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        mapView.delegate = self
        
        self.drawMap()
    }

    // called by every refresh
    func drawMap()
    {
        // may be add or delete restaurants
        fetchRestaurants()
        // make sure has user location
        // default value is near Monahs Caulfield
        if(self.currentLocation == nil){
            self.currentLocation = CLLocationCoordinate2D(latitude: -37.8770054 , longitude: 145.0420786)
        }
        // set perspective
        self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(self.currentLocation!,10000,10000), animated: true)
        // draw each restaurant
        for restaurant in self.restaurants! {
            // get distance between the restaurant and user location
            let disForShow = self.computeDistance(lat: restaurant.latitude, lon: restaurant.longitude)
            // decide show or not, according to picker: radius value
            if(self.showRadius[self.showRadiusPicker.selectedRow(inComponent: 0)] == "Infinite"
                ||  Float(disForShow)! < Float(self.showRadius[self.showRadiusPicker.selectedRow(inComponent: 0)])!)
            {
                // if shown, add annotation
                let location = FencedAnnotation(newTitle: restaurant.name!, newSubtitle: "Distance: " + disForShow + "m", lat: restaurant.latitude, long: restaurant.longitude)
                self.mapView.addAnnotation(location)
            
                        
                // hightlight the radius of notification
                if(restaurant.isNotify){
                    let circle = MKCircle(center: location.coordinate, radius: Double(restaurant.radius))
                    let geoLocation = CLCircularRegion(center: location.coordinate, radius: Double(restaurant.radius), identifier: (location.title)!)
                    self.mapView.add(circle)
                    geoLocation.notifyOnEntry = true
                    self.locationManager.startMonitoring(for: geoLocation)
                }
            }
        }
    }
    
    
    // distance between the restaurant and user location
    func computeDistance(lat:Double,lon:Double) -> String{
        // transfer coordinate to point location
        let point1 = MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        // although it never be none...
        if currentLocation == nil {
            return "Unknown"
        }
        else{
            let point2 = MKMapPointForCoordinate(currentLocation!)
            // get distance
            let distance = MKMetersBetweenMapPoints(point1,point2);
            let format = String(format:"%.2f",distance)
            return format
        }
        
    }
    
    // geo fence
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let alert = UIAlertController(title: "You are now near", message: region.identifier, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // highlight circle
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        assert(overlay is MKCircle, "overlay must be circle")
        
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.lineWidth = 1.0
        circleRenderer.strokeColor = UIColor.purple
        circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
        return circleRenderer
    }
    
    // get user location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.last
        currentLocation = loc?.coordinate
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // clear all monitored regions, annotations and overlays
    // then draw map again
    @IBAction func refreshMap(_ sender: Any) {
        for var region in self.locationManager.monitoredRegions
        {
            self.locationManager.stopMonitoring(for: region)
        }
        let allAnnotations = self.mapView.annotations
        if allAnnotations.count != 0 {
            self.mapView.removeAnnotations(allAnnotations)
        }
        
        let allOverlays = self.mapView.overlays
        if allOverlays.count != 0 {
            self.mapView.removeOverlays(allOverlays)
        }
        
        self.drawMap()
    }
    
    // when comes to this page again, map will refresh automatically
    // useful when edit restaurant and come to this view
    override func viewWillAppear(_ animated: Bool) {
        refreshMap("DuoPan")
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return showRadius.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(showRadius[row])
    }
    
    // when choose radius, map will refresh automatically
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        refreshMap("change show radius")
    }
    
    // can goto other view when clicking annotation
    // Reference: https://stackoverflow.com/questions/33053832/swift-perform-segue-from-map-annotation
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            self.performSegue(withIdentifier: "showRestaurant", sender: view)
        }
    }
    
    // set outlook of the annotation
    // Reference: https://stackoverflow.com/questions/33053832/swift-perform-segue-from-map-annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "pin"
        
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            // set button
            anView?.canShowCallout = true
            anView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            anView?.image = #imageLiteral(resourceName: "pin")
        }
        else {
            anView?.annotation = annotation
        }
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let rest = findRestaurantByName(name: ((anView?.annotation?.title)!)!)
        let pinImage = UIImage(data: rest.logo! as Data)
        imageView.image = pinImage
        //set logo
        anView?.leftCalloutAccessoryView = imageView
        
        return anView
    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showRestaurant" )
        {
            let controller = segue.destination as! OneRestaurantController
            let name: String = (sender as! MKAnnotationView).annotation!.title!!
            let rest: Restaurant = self.findRestaurantByName(name: name)
            controller.restaurant = rest
            controller.existRestaurants = self.restaurants
        }
        
    }
    
    // get the restaurant infomation form annotation title
    func findRestaurantByName(name: String) -> Restaurant
    {
        for r in self.restaurants! {
            if r.name == name {
                return r
            }
        }
        return restaurants![0]
    }
    
    
}
