//
//  OneCategoryController.swift
//  RestauantLocator
//
//  Created by duo pan on 8/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

/* A category view
 * Fetch and display data by the order which user set last time
 * User can order list by name (both ascending and descending), free drag, data added, and stars.
 * Once sorted, the order will save into core data
 * User can search
 * Left slip each item, user can delete the item
 * User can add new item by clicking button on top right.
 * User can view detial by clicking each cell.
 * Edit choice is in the restaurant detail view
 */

import UIKit
import CoreData

class OneCategoryController: UITableViewController, UISearchBarDelegate, addRestaurantDelegate {
   
    var categoryName: String?
    var restaurants: [Restaurant]?
    var filteredRestaurants: [Restaurant]?
    var managedContext: NSManagedObjectContext?
    var appDelegate: AppDelegate?
    
    var btnColor :UIColor?
    @IBOutlet weak var sortBtn: UIBarButtonItem!
    
    @IBOutlet var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = categoryName!
        self.btnColor = sortBtn.tintColor
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate!.persistentContainer.viewContext
        
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        
        if(categoryName != nil) {
            fetchRestaurants()
        }
    }

    // save and back to this view, it will refresh
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.tableView.reloadData()
    }
    
    func fetchRestaurants() {
        let restaurantFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Restaurant")
        restaurantFetch.predicate = NSPredicate(format: "category.name = %@", categoryName!)
        let sortDescriptor = NSSortDescriptor(key: "order", ascending:true)
        restaurantFetch.sortDescriptors = [sortDescriptor]
        do {
            restaurants = try managedContext?.fetch(restaurantFetch) as? [Restaurant]
            filteredRestaurants = restaurants
        } catch {
            fatalError("Failed to fetch restaurants: \(error)")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Search Bar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if(searchText == "") {
            filteredRestaurants = restaurants
            // hide keyboard
            searchBar.perform(#selector(self.resignFirstResponder), with: nil, afterDelay: 0.1)
        }
        else {
            filteredRestaurants = restaurants?.filter({ ($0.name?.lowercased().contains(searchText.lowercased()))!})
        }
        
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = filteredRestaurants?.count {
            return count
        }
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OneCategoryCell", for: indexPath) as! OneCategoryCell
        let restaurant = filteredRestaurants![indexPath.row]
        cell.labelName.text = restaurant.name
        let formatter :DateFormatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dateString = formatter.string(from: restaurant.dateadded! as Date)
        cell.labelDate.text = dateString
        cell.labelRating.text = String(restaurant.rating) + " Stars"
        cell.labelLocation.text = restaurant.address
        cell.imageRestaurant.image = UIImage(data: restaurant.logo! as Data)

        return cell
    }
 

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // remove a category from core data
            let delRestaurant = self.filteredRestaurants![indexPath.row]
            self.managedContext?.delete(delRestaurant as NSManagedObject)
            self.appDelegate?.saveContext()
            
            // remove from two lists
            self.filteredRestaurants?.remove(at: indexPath.row)
            for i in 0...(self.restaurants?.count)! - 1{
                if self.restaurants?[i].address == delRestaurant.address{
                    self.restaurants?.remove(at: i)
                    break
                }
            }
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
  
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        if fromIndexPath == to{
            return
        }
        
        //sort filter list and restaurant list
        var begin = fromIndexPath.row
        let end = to.row
        let temp = filteredRestaurants?[begin]
        if begin < end {
            while begin < end{
                filteredRestaurants?[begin] = (filteredRestaurants?[begin + 1])!
                begin += 1
            }
        }
        else if begin > end {
            while begin > end{
                filteredRestaurants?[begin] = (filteredRestaurants?[begin - 1])!
                begin -= 1
            }
        }
        filteredRestaurants?[end] = temp!
        restaurants = filteredRestaurants
        
        self.tableView.reloadData()
    }
    

    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
 
    @IBAction func chooseSort(_ sender: Any) {
        if self.sortBtn.tintColor == UIColor.red  {
            self.sortBtn.tintColor = btnColor
            self.tableView.setEditing(!self.tableView.isEditing, animated: true)
            self.saveOrders()
            return
        }
        let menu = UIAlertController(title: "Sort The List", message: "Please choose any one", preferredStyle: .actionSheet)
        let option1 = UIAlertAction(title: "Name from A", style: .default){ (_) in self.sortFromA(flag: true)}
        let option2 = UIAlertAction(title: "Name from Z", style: .default){ (_) in self.sortFromA(flag: false)}
        let option3 = UIAlertAction(title: "Stars from highest", style: .default){ (_) in self.sortByStars()}
        let option4 = UIAlertAction(title: "Date added from lastest", style: .default){ (_) in self.sortByDate()}
        let option5 = UIAlertAction(title: "Free Drag", style: .default){ (_) in self.sortDrag()}
        let optionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        menu.addAction(option1)
        menu.addAction(option2)
        menu.addAction(option3)
        menu.addAction(option4)
        menu.addAction(option5)
        menu.addAction(optionCancel)
        self.present(menu, animated: true, completion: nil)
        
    }

    func sortFromA(flag: Bool){
        restaurants = []
        filteredRestaurants = []
        let restaurantFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Restaurant")
        restaurantFetch.predicate = NSPredicate(format: "category.name = %@", categoryName!)
        // sort from number to letters, and letters are AaBb..Zz
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: flag, selector:#selector(NSString.localizedStandardCompare(_:)))
        restaurantFetch.sortDescriptors = [sortDescriptor]
        do {
            restaurants = try managedContext?.fetch(restaurantFetch) as? [Restaurant]
            filteredRestaurants = restaurants
        } catch {
            fatalError("Failed to fetch category list: \(error)")
        }
        self.tableView.reloadData()
        self.saveOrders()
    }
    
    func sortByStars(){
        restaurants = []
        filteredRestaurants = []
        let restaurantFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Restaurant")
        restaurantFetch.predicate = NSPredicate(format: "category.name = %@", categoryName!)
        let sortDescriptor = NSSortDescriptor(key: "rating", ascending:false)
        let sortDescriptor2 = NSSortDescriptor(key: "name", ascending:true,  selector:#selector(NSString.localizedStandardCompare(_:)))
        restaurantFetch.sortDescriptors = [sortDescriptor, sortDescriptor2]
        do {
            restaurants = try managedContext?.fetch(restaurantFetch) as? [Restaurant]
            filteredRestaurants = restaurants
        } catch {
            fatalError("Failed to fetch category list: \(error)")
        }
        self.tableView.reloadData()
        self.saveOrders()
    }
    
    func sortByDate(){
        restaurants = []
        filteredRestaurants = []
        let restaurantFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Restaurant")
        restaurantFetch.predicate = NSPredicate(format: "category.name = %@", categoryName!)
        let sortDescriptor = NSSortDescriptor(key: "dateadded", ascending:false)
        let sortDescriptor2 = NSSortDescriptor(key: "name", ascending:true,  selector:#selector(NSString.localizedStandardCompare(_:)))
        restaurantFetch.sortDescriptors = [sortDescriptor, sortDescriptor2]
        do {
            restaurants = try managedContext?.fetch(restaurantFetch) as? [Restaurant]
            filteredRestaurants = restaurants
        } catch {
            fatalError("Failed to fetch category list: \(error)")
        }
        self.tableView.reloadData()
        self.saveOrders()
    }
    
    func sortDrag(){
        // not allow darg sort when search
        searchBar.text = ""
        filteredRestaurants = restaurants
        self.tableView.reloadData()
        
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
        if self.sortBtn.tintColor != UIColor.red {
            self.sortBtn.tintColor = UIColor.red
        }
    }
    
    func saveOrders(){
        var index = 0
        for rest in self.restaurants! {
            rest.order = Int32(index)
            index += 1
        }
        appDelegate?.saveContext()
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "showRestaurant") {
            let controller = segue.destination as! OneRestaurantController
            let selectedRestaurant = filteredRestaurants![(tableView.indexPathForSelectedRow?.row)!]
            controller.restaurant = selectedRestaurant
            controller.categoryName = self.categoryName
            controller.existRestaurants = self.restaurants
        }
        if (segue.identifier == "addRestaurant") {
            let controller = segue.destination as! AddRestaurantController
            controller.category = self.categoryName
            controller.mydelegate = self
            controller.existRestaurants = self.restaurants
        }
        
    }
 
    // add value to two lists
    func addRestaurant(restaurant : Restaurant) {
        self.filteredRestaurants?.append(restaurant)
        self.restaurants?.append(restaurant)
    }
    

}
