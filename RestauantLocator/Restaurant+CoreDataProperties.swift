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
    @NSManaged public var address: String?
    @NSManaged public var dateadded: NSDate?
    @NSManaged public var rating: Int32
    @NSManaged public var logo: NSData?
    @NSManaged public var category: Category?

}
