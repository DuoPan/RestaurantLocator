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
    @NSManaged public var color: String?
    @NSManaged public var members: NSSet?

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
