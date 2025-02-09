//
//  Restaurant+CoreDataProperties.swift
//  RestauantLocator
//
//  Created by duo pan on 14/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//






import Foundation
import CoreData

extension Restaurant {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Restaurant> {
        return NSFetchRequest<Restaurant>(entityName: "Restaurant")
    }

    @NSManaged public var name: String?
    @NSManaged public var dateadded: NSDate?
    @NSManaged public var rating: Int32
    @NSManaged public var logo: NSData?
    @NSManaged public var radius: Int32
    @NSManaged public var isNotify: Bool
    // order is used for saving sorting results.
    @NSManaged public var order: Int32
    @NSManaged public var category: Category?
    // address is shown in string, but also sotre longitude and latitude,
    // because geocoder handle address to long&lat method can not be preformed many times in a short time
    // so in map view, it can not translate all addresses in a short time.
    // reference: https://stackoverflow.com/questions/36619134/strategy-to-perform-many-geocode-requests/36639569
    // reference: https://developer.apple.com/documentation/corelocation/clgeocoder
    @NSManaged public var address: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double

}
