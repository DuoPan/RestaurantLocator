//
//  EditCategoryViewController.swift
//  RestauantLocator
//
//  Created by duo pan on 10/8/17.
//  Copyright © 2017 duo pan. All rights reserved.
//

/* Edit Category View
 * Original value of this category is shown
 * User can choose image from photo library, enter name in text filed, and select color by sliders (RGB)
 * Preview of text color.
 * Change navigation bar default text. ("back" to "cancel")
 * Validation with prompt: Name must not be entered and not existed. Image must be choosen. Default color.
 * Running in real phone, keyboard can show and hide.
 * All the changes will show immediately when click save button
* Different constrains in landscape
 */


import UIKit
import CoreData

class EditCategoryViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelName: UITextField!
    @IBOutlet var labelR: UILabel!
    @IBOutlet var labelG: UILabel!
    @IBOutlet var labelB: UILabel!
    
    @IBOutlet var sliderB: UISlider!
    @IBOutlet var sliderG: UISlider!
    @IBOutlet var sliderR: UISlider!

    @IBOutlet var labelColor: UILabel!
    var category : Category? //the category which to be edited
    var categories:[Category]? // all existed categories
    var managedContext: NSManagedObjectContext?
    var appDelegate: AppDelegate?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Change words on Navigation bar back item
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(backToPrevious))
        
        // show the category's values before editing
        labelName.text = category?.name
        imageView.image = UIImage(data:  category?.logo! as! Data)
        
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedContext = appDelegate?.persistentContainer.viewContext
        
        sliderR.value = (category?.colorR)!
        sliderG.value = (category?.colorG)!
        sliderB.value = (category?.colorB)!
        
        labelR.text = String(Int(sliderR.value))
        labelG.text = String(Int(sliderG.value))
        labelB.text = String(Int(sliderB.value))
        
        labelColor.textColor = UIColor(red: CGFloat(sliderR.value / 255), green: CGFloat(sliderG.value / 255), blue: CGFloat(sliderB.value / 255), alpha: 1)
    }
    
    // set leftBarButtonItem to have a go back function
    func backToPrevious(){
        self.navigationController!.popViewController(animated: true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // in real phone use camera, otherwise use photo
    @IBAction func chooseImage(_ sender: Any) {
        let picker = UIImagePickerController()
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            picker.sourceType = UIImagePickerControllerSourceType.camera
        }
        else {
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        picker.allowsEditing = false
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
    
    // when click save button
    @IBAction func saveEdit(_ sender: Any) {
        // check if input all exist
        if labelName.text == "" {
            showMessage(msg: "Please enter a category name")
            return
        }
        // can change the name, but the name can not be the same as others
        for i in 0...(categories?.count)!-1{
            // name exist in all names of cateogries
            if ((categories?[i].name)!.lowercased() == labelName.text?.lowercased()) {
                // name is not the same as the category we changed
                if labelName.text?.lowercased() != category?.name?.lowercased() {
                    showMessage(msg: "The Name is already exist!")
                    return
                }
            }
        }
        
        // update category into core data
        let categoryFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Category")
        categoryFetch.predicate = NSPredicate(format: "name = %@", (category?.name!)!)
        var editCategory :[Category]?
        do {
            editCategory = try managedContext?.fetch(categoryFetch) as? [Category]
            editCategory?[0].name = labelName.text
            editCategory?[0].logo = UIImagePNGRepresentation(self.imageView.image!) as! NSData
            editCategory?[0].colorR = sliderR.value
            editCategory?[0].colorG = sliderG.value
            editCategory?[0].colorB = sliderB.value
            
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

    
    // reference: range of rgb is 0-1, not 0-255. https://stackoverflow.com/questions/8023916/how-to-initialize-uicolor-from-rgb-values-properly
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
