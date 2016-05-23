//
//  FeedVC.swift
//  iClass
//
//  Created by Chandrasegaran Senthil Kumaran on 5/7/16.
//  Copyright © 2016 SenthilKumaran. All rights reserved.
//

import UIKit
import Firebase
import Alamofire

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postField: MaterialTextField!
    
    @IBOutlet weak var imageSelectorImage: UIImageView!
    
    
    
    var posts = [Post]()
    var imageSelected = false
    var imagePicker: UIImagePickerController!
    
    static var imageCache = NSCache()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedRowHeight = 394  // 358
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        DataService.ds.REF_POSTS.observeEventType(.Value, withBlock: { snapshot in    // swift closure
            print(snapshot.value)
            
            self.posts = []
            if let snapshots = snapshot.children.allObjects as? [FDataSnapshot] {
                
                for snap in snapshots {
                    print("SNAP: \(snap)")
                    
                    if let postDict = snap.value as? Dictionary<String, AnyObject> {  // fetching/converting firebase data as dictionary
                        let key = snap.key
                        let post = Post(postKey: key, dictionary: postDict)
                        self.posts.append(post)
                    }
                    
                }
                
            }
            
            self.tableView.reloadData()
        })
        

    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
       
        let post = posts[indexPath.row]
        // print(post.postDescription) // wrote this for testing purposes
        
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as? PostCell {
            
            cell.request?.cancel() // otherwise a wrong image could be grabbed, ie - old request could bring an image to the new cell, new cell should run a new request if it needs to.
            
            var img: UIImage?
            
            if let url = post.imageUrl {
                img = FeedVC.imageCache.objectForKey(url) as? UIImage // publically available static data is called in this manner (alla singleton) //grabbing                the image from cache
                print("!!!!!!!")
                print(img)
            }
            
            cell.configureCell(post, img: img)
            return cell
        } else {
            return PostCell()
        }
        
        //return tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostCell // wrote this code for testing purposes
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {                              // to resize / shrink the cell when there is no image
        
        let post = posts[indexPath.row]
        
        if post.imageUrl == nil {
            return 150
        } else {
            return tableView.estimatedRowHeight
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {                                                                // can use the other imagepickercontroller to deal with videos
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        imageSelectorImage.image = image
        imageSelected = true
    }
    
    @IBAction func selectImage(sender: UITapGestureRecognizer) {
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    
    
    @IBAction func makePost(sender: AnyObject) {
        if let txt = postField.text where txt != "" {
            
            if let img = imageSelectorImage.image where imageSelected == true { // need to complete this later so that the camera icon doesn't get uploaded when there is no image
                let urlStr = "https://post.imageshack.us/upload_api.php"
                let url = NSURL(string: urlStr)!
                let imgData = UIImageJPEGRepresentation(img, 0.2)! //alamofire requires data format, image converted to data
                let keyData = "12DJKPSU5fc3afbd01b1630cc718cae3043220f3".dataUsingEncoding(NSUTF8StringEncoding)! // standard method to convert string to data
                let keyJSON = "json".dataUsingEncoding(NSUTF8StringEncoding)!/*convertinig the word "jason" to data. all these(above) 3 are required field by imageshack */
                
                Alamofire.upload(.POST, url, multipartFormData: { multipartFormData in //below are swift closures
                   
                    multipartFormData.appendBodyPart(data: imgData, name: "fileupload", fileName: "image", mimeType: "image/jpg")
                    multipartFormData.appendBodyPart(data: keyData, name: "key")
                    multipartFormData.appendBodyPart(data: keyJSON, name: "format")
                    
                }) { encodingResults in
                        
                        switch encodingResults {
                        case .Success(let upload, _, _):
                            upload.responseJSON(completionHandler: { response in
                                    if let info = response.result.value as? Dictionary<String, AnyObject> {
                                        
                                        if let links = info["links"] as? Dictionary<String, AnyObject> { /*dictionary inside a dictionary, matching the documentation of imageshack */
                                            if let imgLink = links ["image_link"] as? String {
                                                print("LINK: \(imgLink)")
                                                self.postToFireBase(imgLink)
                                                
                                            }
                                            
                                        }
                                        
                                    }
                                    
                        })
                            case .Failure(let error):
                                print(error)
                        }
            }
            
            } else {
                self.postToFireBase(nil)
            }
    }
  }
    func postToFireBase(imgUrl: String?) {
        var post: Dictionary<String, AnyObject> = [
            "description": postField.text!,
            "likes": 0
        ]
        
        if imgUrl != nil {
            post["imageUrl"] = imgUrl!
        }
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId()
        firebasePost.setValue(post)
        
        postField.text = ""
        imageSelectorImage.image = UIImage(named: "camera")
        imageSelected = false
        
        tableView.reloadData()
        
    }

}
