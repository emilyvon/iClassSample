//
//  PostCell.swift
//  iClass
//
//  Created by Chandrasegaran Senthil Kumaran on 5/7/16.
//  Copyright © 2016 SenthilKumaran. All rights reserved.
//

import UIKit
import Alamofire
import Firebase

class PostCell: UITableViewCell {
    
    @IBOutlet weak var profileImg: UIImageView!
    @IBOutlet weak var showcaseImg: UIImageView!
    @IBOutlet weak var descriptionText: UITextView!
    @IBOutlet weak var likesLbl: UILabel!
    @IBOutlet weak var likeImage: UIImageView!
    
    var post: Post!
    var request: Request? // alamofire object
    var likeRef: Firebase!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(PostCell.likeTapped(_:))) // action: "likeTapped:" is deprecated so used the selector instead, it   was auto corrected by xcode
        tap.numberOfTapsRequired = 1
        likeImage.addGestureRecognizer(tap)
        likeImage.userInteractionEnabled = true
    }
    
    override func drawRect(rect: CGRect) {
        profileImg.layer.cornerRadius = profileImg.frame.size.width / 2
        profileImg.clipsToBounds = true   // prevents the image from going outside the bounce
        
        showcaseImg.clipsToBounds = true  // prevents the image from going outside the bounce
    }

    
    
    func configureCell(post: Post, img: UIImage?) {
        self.post = post
        likeRef = DataService.ds.REF_USER_CURRENT.childByAppendingPath("likes").childByAppendingPath(post.postKey)
        self.descriptionText.text = post.postDescription
        self.likesLbl.text = "\(post.likes)"    // converting int to string in swift
        
        if post.imageUrl != nil {
            
            self.showcaseImg.hidden = false
            
            if img != nil {
                self.showcaseImg.image = img  // assigning the image from cache
            } else {
                
                request = Alamofire.request(.GET, post.imageUrl!).validate(contentType: ["image/*"]).response(completionHandler: { request, response, data, err in
                    
                    if err == nil {
                        let img = UIImage(data: data!)!  // force wrapping and unwrapping, // can do a if let on this if there is enough time
                        self.showcaseImg.image = img
                        FeedVC.imageCache.setObject(img, forKey: self.post.imageUrl!)
                    } else {
                        print(err.debugDescription)
                    }
                    
                })  //Swift closure//( this is an alamofire thing)
                
            }
            
        } else {
            self.showcaseImg.hidden = true // hides the existing image if there is no image url / image added by user
        }
        
        //let likeRef = DataService.ds.REF_USER_CURRENT.childByAppendingPath("likes").childByAppendingPath(post.postKey) same has been moved to configureCell
        
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if let doesNotExist = snapshot.value as? NSNull { // if data does not exist in .value in firebase it will return NSNull so don't check against nil etc..
                // this means we have not liked this specific post
                self.likeImage.image = UIImage(named: "heart-empty")
            } else {
                self.likeImage.image = UIImage(named: "heart-full")
            }
            
        })
        
    }
    
    
    // linking the likes to that particular user
    func likeTapped(sender: UITapGestureRecognizer) {
        likeRef.observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            if let doesNotExist = snapshot.value as? NSNull { // if data does not exist in .value in firebase it will return NSNull
                // this means we have not liked this specific post
                self.likeImage.image = UIImage(named: "heart-full")
                self.post.adjustLikes(true)
                self.likeRef.setValue(true)
                
            } else {
                self.likeImage.image = UIImage(named: "heart-empty")
                self.post.adjustLikes(false)
                self.likeRef.removeValue()      // deletes the entire key (value)
            }
            
        })
    }
    

}
