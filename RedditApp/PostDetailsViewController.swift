//
//  PostDetailsViewController.swift
//  Salamon03
//
//  Created by mac on 26.02.2024.
//

import Foundation
import UIKit

class PostDetailsViewController:UIViewController{
    static let indentifier="PostDetailsViewController"
    
    @IBOutlet weak var authorFullname: UILabel!
    @IBOutlet weak var timePassed: UILabel!
    @IBOutlet weak var domain: UILabel!
    @IBOutlet weak var postTitle: UILabel!
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var rating: UIButton!
    @IBOutlet weak var comments: UIButton!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    var post:UnsafeMutablePointer<RedditPost>?=nil
    var configure:()->Void={}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bookmarkButton.addTarget(self, action: #selector(onSaveClicked), for: .touchDown)
        shareButton.addTarget(self, action: #selector(onShareClicked), for: .touchDown)
        configure()
    }
    
    func configurePost( receivedPost: UnsafeMutablePointer<RedditPost>){
        post = receivedPost
        if(post?.pointee.saved ?? false){
            bookmarkButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        }else{
            bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        }
        authorFullname.text=receivedPost.pointee.author_fullname
        timePassed.text=receivedPost.pointee.time_passed.TimePassedStyleFormatted()
        domain.text=receivedPost.pointee.domain
        postTitle.text=receivedPost.pointee.title
        if let imageURL=URL(string:receivedPost.pointee.imageURL){
            postImage.sd_setImage(with:imageURL, completed: nil)
        }
        rating.setTitle(receivedPost.pointee.rating.KStyleFormatted(), for: .normal)
        comments.setTitle(receivedPost.pointee.num_comments.KStyleFormatted(), for: .normal)
    }
    
    @IBAction func onSaveClicked(_ sender: Any) {
        self.post?.pointee.saved.toggle()
        if(post?.pointee.saved ?? false){
            savePost()
            bookmarkButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        }else{
            deletePost()
            bookmarkButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        }
    }
    
    func savePost() {
        if let unwrPost=post?.pointee{
        let fileManager=FileManager.default
        if let documentDir=try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false){
            let fileURL=documentDir.appendingPathComponent("RedditPosts")
            var postsToSave:[RedditPost]?
            if let jsonData=try? Data(contentsOf: fileURL){
                if let decodedData=try? JSONDecoder().decode([RedditPost].self, from: jsonData){
                    try? fileManager.removeItem(at: fileURL)
                    postsToSave=decodedData
                    postsToSave?.append(unwrPost)
                }
            }else{
                postsToSave=[unwrPost]
            }
            if let jsonData=try? JSONEncoder().encode(postsToSave){
                try? jsonData.write(to: fileURL)
            }
        }
        }
    }
    
    func deletePost(){
        if let unwrPost=post?.pointee{
            let fileManager=FileManager.default
            if let documentDir=try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false){
                let fileURL=documentDir.appendingPathComponent("RedditPosts")
                if let jsonData=try? Data(contentsOf: fileURL){
                    if var decodedData=try? JSONDecoder().decode([RedditPost].self, from: jsonData){
                        try? fileManager.removeItem(at: fileURL)
                        decodedData.removeAll{
                            $0==unwrPost
                        }
                        if let jsonData=try? JSONEncoder().encode(decodedData){
                            try? jsonData.write(to: fileURL)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func onShareClicked(_ sender: Any){
        if let stringLink=post?.pointee.link{
            if let link=URL(string:stringLink){
                let activityController=UIActivityViewController(activityItems: [link], applicationActivities: nil)
                present(activityController, animated: true, completion: nil)
            }
        }
    }
    
}
