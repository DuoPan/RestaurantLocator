//
//  AddRestaurantController.swift
//  RestauantLocator
//
//  Created by duo pan on 11/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

/* Add Restaurant View
 * Validation with prompt: User need to enter all information.
   restaurant name is limit to 30 chars
   rating can only be 1-5
   different restaurants can not be the same location
 * User can choose whether to notification or not
 * Automatically save latitude and longitude
 * Different constrains in landscape
 */


import UIKit
import CoreData
import CoreLocation

// call by OneCategoryController
protocol addRestaurantDelegate {
    func addRestaurant(restaurant : Restaurant)
}


class AddRestaurantController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate {
    @IBOutlet weak var labelName: UITextField!
    @IBOutlet weak var labelLocation: UITextView!
    @IBOutlet weak var labelRating: UITextField!
    @IBOutlet weak var labelCategory: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet var radiusLabel: UILabel!

    var category:String? // the category can not choose, because I design add restaurant in a specific catogory
    var managedContext: NSManagedObjectContext?
    var appDelegate: AppDelegate?
    var mydelegate : addRestaurantDelegate?
    var existRestaurants: [Restaurant]?
    var latitude:Double?
    var longitude:Double?
    
    // make sure address string has been translate to lat and lon
    // because geocoder method seems doing asyn
    var findLocation:Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change words on Navigation bar back item
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(backToPrevious))
        
        // set textview
        self.labelLocation.layer.borderWidth = 1.0;
        self.labelLocation.layer.borderColor = UIColor.gray.cgColor;
        self.labelLocation.layer.cornerRadius = 5.0;
        self.labelLocation.delegate = self
        self.labelLocation.textColor = UIColor.gray
        self.labelLocation.text = "Please Enter Address"
        
        self.labelRating.layer.borderColor = UIColor.gray.cgColor;
        self.labelName.layer.borderColor = UIColor.gray.cgColor;
        self.labelName.layer.borderWidth = 1.0;
        self.labelRating.layer.borderWidth = 1.0;
        
        self.labelName.delegate = self
        self.labelRating.delegate = self
        
        labelCategory.text = category
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate?.persistentContainer.viewContext
        
        findLocation = false
        
    }

    // set leftBarButtonItem to have a go back function
    func backToPrevious(){
        self.navigationController!.popViewController(animated: true)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    // MARK: - textview set placeholder
    */
    
    // set palceholder of textview
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Please Enter Address" {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Please Enter Address"
            textView.textColor = UIColor.gray
        }
    }
 
    /*
     // MARK: - textfield limit words
    */
    // reference http://www.hangge.com/blog/cache/detail_718.html
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // restaurant name is limit to 30 chars
        if labelName == textField {
            // calculate name length no matter input or delete a char
            let proposeLength = (textField.text?.characters.count)! - range.length + string.characters.count
            // name length can not over 30, otherwise a prompt dialog will pop up
            if proposeLength > 30 {
                let alertController = UIAlertController(title: "30 Words Limit!",message: nil, preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                    self.presentedViewController?.dismiss(animated: false, completion: nil)
                }
                return false
            }
        }
        // restaurant rating can only be 1-5
        if labelRating == textField {
            let proposeLength = (textField.text?.characters.count)! - range.length + string.characters.count
            // rating can only 1 char
            if proposeLength > 1 {
                return false
            }
            if string != "5" && string != "4" && string != "3" && string != "2" && string != "1" && string != "" {
                // prompt the input format
                let alertController = UIAlertController(title: "Only accept 1-5!",message: nil, preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
                }
                return false
            }
        }
        return true
        
    }
        
    @IBAction func chooseLogo(_ sender: Any) {
        // make sure access to photo library
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            let warnInfo = UIAlertController(title: "Warning", message: "Can not access photo library!", preferredStyle: UIAlertControllerStyle.alert)
            let okAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            warnInfo.addAction(okAlertAction)
            self.present(warnInfo,animated:true, completion:nil)
            
            return
        }
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.delegate = self
        self.present(picker, animated:true, completion:nil)
        
    }
    
    // when user choose a picture, the function will be called
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        dismiss(animated: true, completion: nil)
    }
    
    func getLatLon() {
        // get lat and long by location String
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(self.labelLocation.text, completionHandler:{
            (placemarks, error) in
                if error != nil {
                    self.findLocation = false
                    self.showMessage(msg: "Can not find this place!")
                    return
                }
                if let p = placemarks?[0]{
                    self.findLocation = true
                    self.latitude = p.location!.coordinate.latitude
                    self.longitude = p.location!.coordinate.longitude
                    // handle asyn, make sure this method finish then save
                    self.findLocation = true
                    self.saveNewRestaurant("")
                    } else {
                        print("No placemarks!")
                        return
                    }
                })
    }
    
    
    @IBAction func saveNewRestaurant(_ sender: Any) {
        // check if input all exist
        if labelName.text == "" {
            showMessage(msg: "Please enter a restaurant name")
            return
        }
        if labelLocation.text == ""{
            showMessage(msg: "Please enter a restaurant address")
            return
        }
        else{
            if findLocation == false {
                // translation to lat and lon first
                self.getLatLon()// this method will call saveEditRestaurant method again, and goto other path
                return
            }
        }
        if labelRating.text == ""{
            showMessage(msg: "Please enter a restaurant rating")
            return
        }
        if imageView.image == #imageLiteral(resourceName: "photolibrary") {
            showMessage(msg: "Please choose a restaurant image")
            return
        }
        // check if the location is exist or not
        if existRestaurants?.count != 0 {
            for i in 0...(existRestaurants?.count)!-1{
                if ((existRestaurants?[i].address)!.lowercased() == labelLocation.text?.lowercased()) {
                    showMessage(msg: "The location is already exist!")
                    return
                }
            }
        }
        
        // save new restaurant into core data
        let restaurant = NSEntityDescription.insertNewObject(forEntityName: "Restaurant", into: managedContext!) as! Restaurant
        restaurant.name = labelName.text
        restaurant.address = labelLocation.text
        restaurant.rating = Int32(labelRating.text!)!
        restaurant.logo = UIImagePNGRepresentation(imageView.image!) as! NSData
        restaurant.dateadded = NSDate()
        restaurant.isNotify = notificationSwitch.isOn
        restaurant.radius = Int32(radiusLabel.text!)!
        restaurant.order = Int32(existRestaurants!.count)
        restaurant.latitude = self.latitude!
        restaurant.longitude = self.longitude!
        // add to the catogory
        let categoryFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        categoryFetch.predicate = NSPredicate(format: "name = %@", category!)
        do {
            let result = try managedContext?.fetch(categoryFetch) as? [Category]
            result?[0].addToMembers(restaurant)
        } catch {
            fatalError("Failed to fetch restaurants: \(error)")
        }
        
        appDelegate?.saveContext()
        
        // add value to two lists
        self.mydelegate?.addRestaurant(restaurant: restaurant)
        
        // return to category page and reload
        self.navigationController?.popViewController(animated: true)
    }
    
    // pop up a dialog to show message
    func showMessage(msg:String){
        let alertController = UIAlertController(title: msg, message: nil, preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    // touch background to hide keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // show slider value on the label beside
    @IBAction func radiusSlider(_ sender: UISlider) {
        radiusLabel.text = String(Int(sender.value))
    }
    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
