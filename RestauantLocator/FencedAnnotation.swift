//
//  FencedAnnotation.swift
//  RestauantLocator
//
//  Created by duo pan on 21/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

/* Self-defined annotation
 * Subtitle is to display distance between the restaurant and current user locatoin.
 *
 */

import UIKit
import MapKit

class FencedAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(newTitle:String, newSubtitle:String,lat:Double,long:Double) {
        title = newTitle
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        subtitle = newSubtitle
    }
    
    
}
