//
//  Category+CoreDataProperties.swift
//  RestauantLocator
//
//  Created by duo pan on 14/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//


import Foundation
import CoreData


extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var name: String?
    @NSManaged public var logo: NSData?
    // colorR, G, B are used for the textcolor of category name
    @NSManaged public var colorR: Float
    @NSManaged public var colorG: Float
    @NSManaged public var colorB: Float
    @NSManaged public var members: NSSet?
    // order is used for saving sorting results.
    @NSManaged public var order: Int32

}

// MARK: Generated accessors for members
extension Category {

    @objc(addMembersObject:)
    @NSManaged public func addToMembers(_ value: Restaurant)

    @objc(removeMembersObject:)
    @NSManaged public func removeFromMembers(_ value: Restaurant)

    @objc(addMembers:)
    @NSManaged public func addToMembers(_ values: NSSet)

    @objc(removeMembers:)
    @NSManaged public func removeFromMembers(_ values: NSSet)

}
