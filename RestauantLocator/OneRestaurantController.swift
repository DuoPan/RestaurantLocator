//
//  OneRestaurantController.swift
//  RestauantLocator
//
//  Created by duo pan on 8/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

/* A restaurant detial view
 * Navigation bar image title: logo
 * User can edit it by clicking button on top right.
 * User can view detial by clicking each cell.
 * With a map: use geocoder to transfer string address to latitude and longtitude
 */

import UIKit
import MapKit
import CoreData
import CoreLocation

class OneRestaurantController: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    var restaurant: Restaurant? // this restaurant to be shown
    var existRestaurants: [Restaurant]? // when click edit button, it will pass to that controller
    
    
    @IBOutlet var mapView: MKMapView!
    
    var titleImageView:UIImageView?
    
    let locationManager:CLLocationManager = CLLocationManager()
    var geoLocation:CLCircularRegion?
    var currentLocation:CLLocationCoordinate2D?
    var location:FencedAnnotation?
    var circle:MKCircle?

    override func viewDidLoad() {
        super.viewDidLoad()

        
        // set image title
        // reference : https://stackoverflow.com/questions/24803178/swift-navigation-bar-image-title
        let titleImage = UIImage(data: restaurant!.logo! as Data)
        self.titleImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 37.5))
        self.titleImageView?.contentMode = .scaleAspectFit
        self.titleImageView?.image = titleImage
        self.navigationItem.titleView = titleImageView
        
        // Set dynamic line height and numbers of lines
        tableView.estimatedRowHeight = 40
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // show self location
        mapView.showsUserLocation = true;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        mapView.delegate = self
        
        self.showMap()
    }
 
    func showMap(){
        // set annotation
        self.location = FencedAnnotation(newTitle: self.restaurant!.name!, newSubtitle: "Distance: " + self.computeDistance(), lat: restaurant!.latitude, long: restaurant!.longitude)
        self.mapView.addAnnotation(self.location!)
        // set notification circle
        self.circle = MKCircle(center: (self.location?.coordinate)!, radius: Double((self.restaurant?.radius)!))
        self.geoLocation = CLCircularRegion(center: self.location!.coordinate, radius: Double((self.restaurant?.radius)!), identifier: (self.location?.title!)!)
        
        // hightlight the radius of notification
        if(self.restaurant?.isNotify)!{
            print("Open GeoFeching")
            self.mapView.add(self.circle!)
            self.locationManager.startMonitoring(for: self.geoLocation!)
            self.geoLocation!.notifyOnEntry = true
        }
        else{
            print("Close GeoFeching")
            self.geoLocation!.notifyOnEntry = false
            // get monitored regions and stop them one by one
            for var region in self.locationManager.monitoredRegions
            {
                self.locationManager.stopMonitoring(for: region)
            }
        }
        // set perspective
        self.mapView.setRegion(MKCoordinateRegionMakeWithDistance(self.location!.coordinate,2000,2000), animated: true)
        
    }
    
    // compute distance between current location and the restaurant
    func computeDistance() -> String{
        // transfer coordinate to point location
        let point1 = MKMapPointForCoordinate(CLLocationCoordinate2D(latitude: (restaurant?.latitude)!, longitude: (restaurant?.longitude)!))
        
        if currentLocation == nil {
            return "Unknown"
        }
        else{
            let point2 = MKMapPointForCoordinate(currentLocation!)
            // get distance
            let distance = MKMetersBetweenMapPoints(point1,point2);
            let format = String(format:"%.2f",distance)
            return format + "m"
        }
        
    }
    
    // geofence
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let alert = UIAlertController(title: "You are now near", message: self.location?.title, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // update realtime user location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.last
        currentLocation = loc?.coordinate
        
        location?.subtitle = "Distance: " + computeDistance()
    }
    
    // add highlight circle
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        assert(overlay is MKCircle, "overlay must be circle")
        
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.lineWidth = 1.0
        circleRenderer.strokeColor = UIColor.purple
        circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
        return circleRenderer
    }
    
    // each time comes to this page, it will run
    // when edit this restaurant, the changes will be shown immediately
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        titleImageView?.image = UIImage(data: restaurant!.logo! as Data)
        self.tableView.reloadData()

        let allAnnotations = self.mapView.annotations
        if allAnnotations.count != 0 {
            self.mapView.removeAnnotations(allAnnotations)
        }
        
        let allOverlays = self.mapView.overlays
        if allOverlays.count != 0 {
            self.mapView.removeOverlays(allOverlays)
        }
        showMap()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 6
    }

    // how each cell looks like
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RestaurantCell", for: indexPath) as! OneRestaurantCell

        // Configure the cell...
        switch indexPath.row {
        case 0:
            cell.labelName.text = "Name: "
            cell.labelValue.text = restaurant!.name
        case 1:
            cell.labelName.text = "Location: "
            cell.labelValue.text = restaurant!.address
        case 2:
            cell.labelName.text = "Category: "
            cell.labelValue.text = restaurant!.category?.name
        case 3:
            cell.labelName.text = "Rating: "
            cell.labelValue.text = String(restaurant!.rating) + " Stars"
        case 4:
            cell.labelName.text = "Date Added: "
            let formatter :DateFormatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            let dateString = formatter.string(from: restaurant!.dateadded! as Date)
            cell.labelValue.text = dateString
        case 5:
            cell.labelName.text = "Notification: "
            if restaurant?.isNotify == true {
                cell.labelValue.text = "On.   Radius: " + String(restaurant!.radius) + "m"
            }else{
                cell.labelValue.text = "Off"
            }
        default:
            break
        }
        
        
        return cell
    }
 


    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "editRestaurant") {
            let controller = segue.destination as! EditRestaurantViewController
            controller.existRestaurants = self.existRestaurants
            controller.restaurant = self.restaurant
            
        }
    }
 
 
}
