//
//  CategoriesController.swift
//  RestauantLocator
//
//  Created by duo pan on 8/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

/* Main page
 * Fetch and display data by the order which user set last time
 * User can order list by name (both ascending and descending), free drag. Once sorted, the order will save into core data
 * User can search 
 * Left slip each item, user can choose edit or delete the item
 * User can add new item by clicking button on top right.
 * User can view detial by clicking each cell.
 * Default 3 categories and 9 restaurants.
 */

import UIKit
import CoreData

class CategoriesController: UITableViewController, UISearchBarDelegate, addCategoryDelegate {
    
    // all categories entities
    var categoryList: [Category]?
    // all categories to be shown, changed when search, sort
    var filteredCategoryList: [Category]?
    
    var managedContext: NSManagedObjectContext?
    var appDelegate: AppDelegate?
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet weak var sortBtn: UIBarButtonItem!
    
    // before free drag sort, the button is blue, when doing free drag sort, it become red, click again, back to blue and finish sort.
    var btnColor :UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //make the view beautiful
        self.tableView.separatorStyle = .singleLine
        self.tableView.separatorColor = UIColor.black
        self.tableView.separatorEffect = UIBlurEffect(style: .light)
        //self.tableView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "lufei"))
        
        btnColor = sortBtn.tintColor
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate?.persistentContainer.viewContext
        
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        
        fetchAllCategories()
        
        if categoryList?.count == 0 {
            createDefaultItems()
            fetchAllCategories()
        }
    }

    // after adding/editing, save and back to this view, it will be called
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func fetchAllCategories() {
        let categoryFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        // fetch by attribute: order ascending
        let sortDescriptor = NSSortDescriptor(key: "order", ascending:true)
        categoryFetch.sortDescriptors = [sortDescriptor]
        do {
            categoryList = try managedContext?.fetch(categoryFetch) as? [Category]
            filteredCategoryList = categoryList
        } catch {
            fatalError("Failed to fetch category list: \(error)")
        }
    }
    
    // MARK: - Search Bar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchText == "") {
            filteredCategoryList = categoryList
            // another way to hide keyboard on real iPhone
            // reference: https://stackoverflow.com/questions/4190459/dismissing-keyboard-from-uisearchbar-when-the-x-button-is-tapped/43018816
            searchBar.perform(#selector(self.resignFirstResponder), with: nil, afterDelay: 0.1)
        }
        else {
            filteredCategoryList = categoryList?.filter({ ($0.name?.lowercased().contains(searchText.lowercased()))!})
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        //  the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // the number of rows
        if let count = filteredCategoryList?.count {
            return count
        }
        return 0;
    }

    // each cell to show name, color and image
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoriesCell", for: indexPath) as! CategoriesCell
        let category = filteredCategoryList![indexPath.row]
        cell.labelCategoryName.text = category.name
        cell.labelCategoryName.textColor = UIColor(red: CGFloat(category.colorR/255), green: CGFloat(category.colorG/255), blue: CGFloat(category.colorB/255), alpha: 1)
        cell.imageCategory.image = UIImage(data: category.logo! as Data)
        
        return cell
    }
 
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // reference : https://www.youtube.com/channel/UCYeN6lt7_RCTxKdTcFv_tSQ
    // when slip left, two button will be shown: delete and edit
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let actionDel = UITableViewRowAction(style: .destructive, title: "Delete") { (_, indexPath) in
            // get the category that user operating
            let deleteCategory = self.filteredCategoryList![indexPath.row]
            
            // get all restaurants belong to this category from core data
            let restaurantFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Restaurant")
            restaurantFetch.predicate = NSPredicate(format: "category.name = %@", deleteCategory.name!)
            var deleteRestaurants : [Restaurant] = []
            do {
                deleteRestaurants = try self.managedContext?.fetch(restaurantFetch) as! [Restaurant]
            } catch {
                fatalError("Failed to fetch restaurants: \(error)")
            }
            // then remove these restaurants
            while deleteRestaurants.count > 0 {
                let deleteRestaurant = deleteRestaurants[0]
                self.managedContext?.delete(deleteRestaurant as NSManagedObject)
                deleteRestaurants.remove(at: 0)
            }
            
            // remove this category from core data
            self.managedContext?.delete(deleteCategory as NSManagedObject)
            
            
            self.appDelegate?.saveContext()
            
            // remove this category from two lists
            self.filteredCategoryList?.remove(at: indexPath.row)
            for i in 0...(self.categoryList?.count)! - 1{
                if self.categoryList?[i].name == deleteCategory.name{
                    self.categoryList?.remove(at: i)
                    break
                }
            }
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        // when click edit button, go to the the other view
        let actionEdit = UITableViewRowAction(style: .default, title: "E d i t") { (_, _) in
            self.performSegue(withIdentifier: "editCategory", sender: indexPath.row )
        }
        actionEdit.backgroundColor = UIColor.orange
        
        return [actionDel, actionEdit]
    }
    
    // Override to support rearranging the table view.
    // free drag sort
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        if fromIndexPath == to{
            return
        }
        
        //sort filter list and category list
        var begin = fromIndexPath.row
        let end = to.row
        let temp = filteredCategoryList?[begin]
        
        // move a category from top to bottom
        if begin < end {
            while begin < end{
                filteredCategoryList?[begin] = (filteredCategoryList?[begin + 1])!
                begin += 1
            }
        }// move a category from bottom to top
        else if begin > end {
            while begin > end{
                filteredCategoryList?[begin] = (filteredCategoryList?[begin - 1])!
                begin -= 1
            }
        }
        filteredCategoryList?[end] = temp!
        
        // save new orders in two lists
        categoryList = filteredCategoryList
        
        self.tableView.reloadData()
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
 

    @IBAction func sortCategories(_ sender: Any) {
        // if free drag finish
        if self.sortBtn.tintColor == UIColor.red  {
            self.sortBtn.tintColor = btnColor
            self.tableView.setEditing(!self.tableView.isEditing, animated: true)
            // save orders
            saveOrders()
            return
        }
        // set menu
        let menu = UIAlertController(title: "Sort The List", message: "Please choose any one", preferredStyle: .actionSheet)
        let option1 = UIAlertAction(title: "Name from A", style: .default){ (_) in self.sortFromA(flag: true)}
        let option2 = UIAlertAction(title: "Name from Z", style: .default){ (_) in self.sortFromA(flag: false)}
        let option3 = UIAlertAction(title: "Free Drag", style: .default){ (_) in self.sortDrag()}
        let optionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        menu.addAction(option1)
        menu.addAction(option2)
        menu.addAction(option3)
        menu.addAction(optionCancel)
        self.present(menu, animated: true, completion: nil)
    }
    
    // save attribute order in core data
    func saveOrders(){
        var index = 0
        for category in self.categoryList! {
            category.order = Int32(index)
            index += 1
        }
        appDelegate?.saveContext()
    }
    
    
    func sortDrag(){
        // not allow darg sort when search
        searchBar.text = ""
        filteredCategoryList = categoryList
        self.tableView.reloadData()
        
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
        if self.sortBtn.tintColor != UIColor.red {
            self.sortBtn.tintColor = UIColor.red
        }
    }
    
    func sortFromA(flag: Bool){
        categoryList = []
        filteredCategoryList = []
        let categoryFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        // sort from number to letters, and letters are AaBb..Zz
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: flag, selector:#selector(NSString.localizedStandardCompare(_:)))
        categoryFetch.sortDescriptors = [sortDescriptor]
        do {
            categoryList = try managedContext?.fetch(categoryFetch) as? [Category]
            filteredCategoryList = categoryList
        } catch {
            fatalError("Failed to fetch category list: \(error)")
        }
        self.tableView.reloadData()
        self.saveOrders()
    }
    
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showCategory") {
            let controller = segue.destination as! OneCategoryController
            let selectedCategory = filteredCategoryList![(tableView.indexPathForSelectedRow?.row)!]
            controller.categoryName = selectedCategory.name
            
        }
        if (segue.identifier == "addCategory") {
            let controller = segue.destination as! AddCategoryController
            controller.categories = categoryList
            controller.mydelegate = self
        }
        if (segue.identifier == "editCategory") {
            let controller = segue.destination as! EditCategoryViewController
            let index = sender as! Int
            controller.categories = categoryList
            controller.category = filteredCategoryList![index]
        }
        
    }
    
    // MARK: - Populate Data
    // same methods as lecture notes
    func createDefaultItems() {
        
        let pizza = createManagedCategory(name: "Pizza", colorR: 0, colorG: 0, colorB: 0, logo: UIImagePNGRepresentation(#imageLiteral(resourceName: "pizza"))! as NSData, order: 2)
        let dessert = createManagedCategory(name: "Dessert", colorR: 255, colorG: 0, colorB: 0, logo: UIImagePNGRepresentation(#imageLiteral(resourceName: "dessert"))! as NSData, order: 1)
        let bbq = createManagedCategory(name: "BBQ", colorR: 0, colorG: 0, colorB: 255, logo:UIImagePNGRepresentation(#imageLiteral(resourceName: "bbq"))! as NSData, order: 0)
        
        pizza.addToMembers(createManagedRestaurant(name: "Duomino's", address: "Gate 22, Station St, Caulfield East VIC 3145", rating: 5, dateadded: NSDate(), logo:  UIImagePNGRepresentation(#imageLiteral(resourceName: "domino"))! as NSData, isNotify: true, radius: 500, order: 0, latitude:-37.877187,longitude:145.038415 ))
        pizza.addToMembers(createManagedRestaurant(name: "PizzaHut", address: "8 Deakin St Malvern East VIC 3145", rating: 4, dateadded: NSDate().addingTimeInterval(-3600*24), logo:  UIImagePNGRepresentation(#imageLiteral(resourceName: "pizzaHut"))! as NSData, isNotify: true, radius: 500, order: 1, latitude:-37.8647527,longitude:145.0391123 ))
        pizza.addToMembers(createManagedRestaurant(name: "Pano's", address: "24 Baldwin St Armadale VIC 3143", rating: 3, dateadded: NSDate().addingTimeInterval(-3600*48), logo: UIImagePNGRepresentation(#imageLiteral(resourceName: "pano"))! as NSData, isNotify: true, radius: 500, order: 2, latitude:-37.8544677,longitude:145.0195863 ))
        
        dessert.addToMembers(createManagedRestaurant(name: "Sweet Box", address: "401 Swanston St, Melbourne VIC 3000", rating: 5, dateadded: NSDate(), logo: UIImagePNGRepresentation(#imageLiteral(resourceName: "sweetbox"))! as NSData, isNotify: true, radius: 500, order: 0,latitude: -37.8090253,longitude: 144.9610503))
        dessert.addToMembers(createManagedRestaurant(name: "Dessert Garden", address: "28-32 Elizabeth St, Melbourne VIC 3000", rating: 4, dateadded: NSDate().addingTimeInterval(-3600*24), logo: UIImagePNGRepresentation(#imageLiteral(resourceName: "dessertgarden"))! as NSData, isNotify: true, radius: 500, order: 1,latitude: -37.8172693,longitude: 144.9626419))
        dessert.addToMembers(createManagedRestaurant(name: "Sweet Land", address: "381 Royal Parade, Parkville VIC 3052", rating: 3, dateadded: NSDate().addingTimeInterval(-3600*48), logo: UIImagePNGRepresentation(#imageLiteral(resourceName: "sweetland"))! as NSData, isNotify: true, radius: 500, order: 2,latitude: -37.7841394,longitude: 144.9567505))
        
        bbq.addToMembers(createManagedRestaurant(name: "Smoke BBQ", address: "179-201 Victoria Parade, Collingwood VIC 3066", rating: 5, dateadded: NSDate(), logo: UIImagePNGRepresentation(#imageLiteral(resourceName: "smoke"))! as NSData, isNotify: true, radius: 500, order: 0,latitude: -37.8267326,longitude: 144.990706))
        bbq.addToMembers(createManagedRestaurant(name: "Flameworthy BBQ", address: "South Yarra Victoria 3141", rating: 4, dateadded: NSDate().addingTimeInterval(-3600*24), logo: UIImagePNGRepresentation(#imageLiteral(resourceName: "flameworthy"))! as NSData, isNotify: true, radius: 500, order: 1, latitude:-37.8424462,longitude:144.982285 ))
        bbq.addToMembers(createManagedRestaurant(name: "Big Boys BBQ", address: "180 St Kilda Rd, Melbourne VIC 3006", rating: 3, dateadded: NSDate().addingTimeInterval(-3600*48), logo: UIImagePNGRepresentation(#imageLiteral(resourceName: "BigBoysBBQ"))! as NSData, isNotify: true, radius: 500, order: 2, latitude:-37.8273724,longitude:144.9603619 ))
        
        appDelegate?.saveContext()
        
    }
    
    func createManagedCategory(name: String, colorR: Float, colorG: Float, colorB: Float, logo: NSData, order: Int32) -> Category {
        let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedContext!) as! Category
        category.name = name
        category.colorR = colorR
        category.colorG = colorG
        category.colorB = colorB
        category.logo = logo
        category.order = order
        return category
    }
    
    func createManagedRestaurant(name: String, address: String, rating: Int32, dateadded: NSDate, logo: NSData, isNotify: Bool, radius: Int32, order: Int32, latitude:Double, longitude:Double) -> Restaurant {
        let restaurant = NSEntityDescription.insertNewObject(forEntityName: "Restaurant", into: managedContext!) as! Restaurant
        restaurant.name = name
        restaurant.address = address
        restaurant.rating = rating
        restaurant.dateadded = dateadded
        restaurant.logo = logo
        restaurant.isNotify = isNotify
        restaurant.radius = radius
        restaurant.order = order
        restaurant.latitude = latitude
        restaurant.longitude = longitude
        return restaurant
    }

    // add value to two lists
    func addCategory(category : Category) {
        self.filteredCategoryList?.append(category)
        self.categoryList?.append(category)
    }
    
}
