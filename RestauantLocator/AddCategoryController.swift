//
//  AddCategoryController.swift
//  RestauantLocator
//
//  Created by duo pan on 10/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

/* Add Category View
 * User can choose image from photo library, enter name in text filed, and select color by sliders (RGB)
 * Preview of text color.
 * Change navigation bar default text. ("back" to "cancel")
 * Validation with prompt: Name must not be entered and not existed. Image must be choosen. Have Default color.
 * Running in real phone, keyboard can show and hide.
 * Different constrains in landscape
 */

import UIKit
import CoreData

// called by CategoryController
protocol addCategoryDelegate {
    func addCategory(category : Category)
}

class AddCategoryController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // all categories in the app
    var categories:[Category]?
    var managedContext: NSManagedObjectContext?
    var appDelegate: AppDelegate?
    var mydelegate : addCategoryDelegate?
    @IBOutlet var labelColor: UILabel!
    @IBOutlet weak var labelName: UITextField!
    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet var sliderR: UISlider!
    @IBOutlet var sliderG: UISlider!
    @IBOutlet var sliderB: UISlider!
    @IBOutlet var labelR: UILabel!
    @IBOutlet var labelB: UILabel!
    @IBOutlet var labelG: UILabel!
    
    // init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change words on Navigation bar back item
        // reference:http://www.jianshu.com/p/11eafef52e0d
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(backToPrevious))
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate?.persistentContainer.viewContext
        
        // set default value
        labelColor.textColor = UIColor(red: 120/255, green: 120/255, blue: 120/255, alpha: 1)
        labelR.text = String(Int(sliderR.value))
        labelG.text = String(Int(sliderG.value))
        labelB.text = String(Int(sliderB.value))
    }
    
    // set leftBarButtonItem to have a go back function
    func backToPrevious(){
        self.navigationController!.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func choosePhoto(_ sender: Any) {
        // make sure access to photo library, if not, will pop up a dialog
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
    
    // when user choose a picture, the function will be called, set image view attributes that image can show appropriately
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        dismiss(animated: true, completion: nil)
    }
    
    
   // when click save button
    @IBAction func saveNewCategory(_ sender: Any) {
        // check if exist
        if labelName.text == "" {
            showMessage(msg: "Please enter a category name")
            return
        }
        if imageView.image == #imageLiteral(resourceName: "photolibrary") {
            showMessage(msg: "Please choose a category image")
            return
        }
       // check if the name is exist or not, can not be the same name
        for i in 0...(categories?.count)!-1{
            if ((categories?[i].name)!.lowercased() == labelName.text?.lowercased()) {
                showMessage(msg: "The Name is already exist!")
                return
            }
        }
        // save new category into core data
        let category = NSEntityDescription.insertNewObject(forEntityName: "Category", into: managedContext!) as! Category
        category.name = labelName.text
        category.logo = UIImagePNGRepresentation(imageView.image!) as! NSData
        category.colorR = sliderR.value
        category.colorG = sliderG.value
        category.colorB = sliderB.value
        category.order = Int32(categories!.count)
        appDelegate?.saveContext()
        
        // add value to two lists in CategoryController
        self.mydelegate?.addCategory(category: category)
        
        // return to category page and reload
        self.navigationController?.popViewController(animated: true)
        
    }

    // pop up a dialog to give message to user
    func showMessage(msg:String){
        let alertController = UIAlertController(title: msg, message: nil, preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    // touch background to hide keyboard in real phone
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func changeR(_ sender: UISlider) {
        labelR.text = String(Int(sender.value))
        labelColor.textColor = UIColor(red: CGFloat(sliderR.value / 255), green: CGFloat(sliderG.value / 255), blue: CGFloat(sliderB.value / 255), alpha: 1)
    }
    
    @IBAction func changeG(_ sender: UISlider) {
        labelG.text = String(Int(sender.value))
        labelColor.textColor = UIColor(red: CGFloat(sliderR.value / 255), green: CGFloat(sliderG.value / 255), blue: CGFloat(sliderB.value / 255), alpha: 1)
    }
    
    @IBAction func changeB(_ sender: UISlider) {
        labelB.text = String(Int(sender.value))
        labelColor.textColor = UIColor(red: CGFloat(sliderR.value / 255), green: CGFloat(sliderG.value / 255), blue: CGFloat(sliderB.value / 255), alpha: 1)
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
