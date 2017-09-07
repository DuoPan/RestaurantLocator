//
//  EditRestaurantViewController.swift
//  RestauantLocator
//
//  Created by duo pan on 11/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

/* Edit Restaurant View
 * Validation with prompt: User need to enter all information.
   restaurant name is limit to 30 chars
   rating can only be 1-5
   different restaurants can not be the same location
 * User can choose whether to notification or not, and set radius.
 * All the changes will show when page open
 * Automatically save latitude and longitude
 * Different constrains in landscape
 */

import UIKit
import CoreData
import CoreLocation

class EditRestaurantViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate {

    @IBOutlet weak var labelName: UITextField!
    @IBOutlet weak var labelLocation: UITextView!
    @IBOutlet weak var labelRating: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var notificationSwich: UISwitch!
    @IBOutlet var radiusLabel: UILabel!
 
    var existRestaurants: [Restaurant]?
    var restaurant: Restaurant? // the restaurant to be edit
    
    var managedContext: NSManagedObjectContext?
    var appDelegate: AppDelegate?
    
    // make sure address string has been translate to lat and lon
    // because geocoder method seems doing asyn
    var findLocation:Bool?
    
    var latitude:Double?
    var longitude:Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Change words on Navigation bar back item
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(backToPrevious))
        
        // set textview
        self.labelLocation.layer.borderWidth = 1.0;
        self.labelLocation.layer.borderColor = UIColor.gray.cgColor;
        self.labelLocation.layer.cornerRadius = 5.0;
        self.labelName.layer.borderWidth = 1.0;
        self.labelName.layer.borderColor = UIColor.gray.cgColor;
        self.labelRating.layer.borderWidth = 1.0;
        self.labelRating.layer.borderColor = UIColor.gray.cgColor;
        self.labelLocation.delegate = self
        self.labelName.delegate = self
        self.labelRating.delegate = self
        
        // display the restaurant attributes which to be edited
        labelName.text = restaurant?.name
        labelLocation.text = restaurant?.address
        labelRating.text = String(restaurant!.rating)
        imageView.image = UIImage(data: restaurant?.logo! as! Data)
        radiusLabel.text = String(restaurant!.radius)
        self.latitude = restaurant!.latitude
        self.longitude = restaurant!.longitude
        notificationSwich.isOn = (restaurant?.isNotify)!
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate!.persistentContainer.viewContext

        // address doesnt translate to lon and lat now
        self.findLocation = false
    }

    
    @IBAction func radiusSlider(_ sender: UISlider) {
        radiusLabel.text = String(Int(sender.value))
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
     // MARK: - textfield limit words
     */
    // validations
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
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
        if labelRating == textField {
            let proposeLength = (textField.text?.characters.count)! - range.length + string.characters.count
            // rating can only 1 char
            if proposeLength > 1 {
                return false
            }
            // rating can only be 1-5
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
        // get lat and lon by location String
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(self.labelLocation.text, completionHandler:{
            (placemarks, error) in
            if error != nil {
                self.findLocation = false
                self.showMessage(msg: "Can not find this place!")
                return
            }
            if let p = placemarks?[0]{
                self.latitude = p.location!.coordinate.latitude
                self.longitude = p.location!.coordinate.longitude
                // handle asyn, make sure this method finish before save
                self.findLocation = true
                self.saveEditRestaurant("")
            } else {
                print("No placemarks!")
                return
            }
        })
    }
    
    // click save button
    @IBAction func saveEditRestaurant(_ sender: Any) {
        // check if input all exist
        if labelName.text == "" {
            showMessage(msg: "Please enter a restaurant name")
            return
        }
        if labelLocation.text == "" {
            showMessage(msg: "Please enter a restaurant address")
            return
        }
        else{
            if findLocation == false {
                // translation to lat and lon first
                self.getLatLon() // this method will call saveEditRestaurant method again, and goto other path
                return
            }
        }
        if labelRating.text == "" {
            showMessage(msg: "Please enter a restaurant rating")
            return
        }
        // check if the location is exist or not
        for i in 0...(existRestaurants?.count)!-1{
            if ((existRestaurants?[i].name)!.lowercased() == labelLocation.text?.lowercased()) {
                if labelLocation.text?.lowercased() != labelName.text {
                    showMessage(msg: "The location is already exist!")
                    return
                }
                
            }
        }
        // update restaurant into core data
        let restaurantFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Restaurant")
        // restaurant address is unique in core data
        restaurantFetch.predicate = NSPredicate(format: "address = %@", (self.restaurant?.address!)!)
        var editRestaurant :[Restaurant]?
        do {
            editRestaurant = try managedContext?.fetch(restaurantFetch) as? [Restaurant]
            editRestaurant?[0].name = labelName.text
            editRestaurant?[0].address = labelLocation.text
            editRestaurant?[0].logo = UIImagePNGRepresentation(self.imageView.image!) as! NSData
            editRestaurant?[0].rating = Int32(labelRating.text!)!
            editRestaurant?[0].radius = Int32(radiusLabel.text!)!
            editRestaurant?[0].isNotify = notificationSwich.isOn
            editRestaurant?[0].latitude = self.latitude!
            editRestaurant?[0].longitude = self.longitude!
        } catch {
            fatalError("Failed to fetch category list: \(error)")
        }
        
         appDelegate?.saveContext()
         
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
