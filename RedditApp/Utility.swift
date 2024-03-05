//
//  Utility.swift
//  Salamon03
//
//  Created by mac on 24.02.2024.
//

import Foundation

struct RedditPost:Codable,Equatable{
    let domain:String
    let author_fullname:String
    let title:String
    let time_passed:Int
    var imageURL:String
    let rating:Int
    let num_comments:Int
    let link:String
    var saved:Bool=false
    
    static func ==(lhs:RedditPost,rhs:RedditPost)->Bool{
        return lhs.link==rhs.link
    }
}

enum RequestError:Error{
    case invalidData
}
class RequestComponent{
    
    private let mainUrl="https://www.reddit.com"
    var subreddit=["r","ios"]
    var parameters:[String:String]=["limit":"1","api_type":"json"]
    
    func processRequest(completion:@escaping ([RedditPost])->Void,failure:@escaping ()->Void){
        var finalURL=mainUrl+"/"+subreddit.joined(separator: "/")+"/top.json?"
        for (name,value) in parameters{
            finalURL+=name+"="+value+"&"
        }
        if let url=URL(string: finalURL){
         let task=URLSession.shared.dataTask(with: url){(data,response,error) in
            if let data = data {
                if let decodedResponse=try? JSONDecoder().decode(RedditJSON.self, from:  data){
                    self.parameters["after"]=decodedResponse.data.after
                    let posts=decodedResponse.data.children.map{children -> RedditPost in
                        let correctImageURL=children.data.url.replacingOccurrences(of: "&amp", with: "&")
                        let domain=children.data.domain
                        let author_fullname=children.data.author_fullname ?? "[deleted]"
                        let title=children.data.title
                        let time_passed=Int(Date().timeIntervalSince1970)-children.data.created
                        let rating=children.data.ups+children.data.downs
                        let num_comments=children.data.ups+children.data.num_comments
                        let link=self.mainUrl+children.data.permalink
                        return RedditPost(domain: domain, author_fullname: author_fullname, title: title, time_passed: time_passed, imageURL: correctImageURL, rating: rating, num_comments: num_comments,link: link)
                    }
                    completion(posts)
                }
                 
            }
             if let error = error {
                 failure()
             }
         }
            task.resume()
        }
    }
    
    
}

extension Int{
    func KStyleFormatted()->String{
        if self>=1000 && self<1_000_000{
            return String(format: "%.1fK", locale: Locale.current, self/1000)
        }else if self>=1_000_000{
            return String(format: "%.1fM", locale: Locale.current, self/1_000_000)
        }else{
            return String(self)
        }
    }
    func TimePassedStyleFormatted()->String{
        if self>=60 && self<3600{
            return String(format: "%.1dm", locale: Locale.current, self/60)
        }else if self>=3600 && self<(24*3600){
            return String(format: "%.1dh", locale: Locale.current, self/3600)
        }else if  self>=(24*3600){
            return String(format: "%.1dd", locale: Locale.current, self/(24*3600))
        }else{
            return String(format: "%.1ds", locale: Locale.current, self)
        }
    }
}

// MARK: - RedditJSON
struct RedditJSON: Codable {
    let kind: String
    let data: RedditData
}

// MARK: - WelcomeData
struct RedditData: Codable {
    let after: String
    let children: [Child]
}

// MARK: - Child
struct Child: Codable {
    let kind: String
    let data: ChildData
}

// MARK: - ChildData
struct ChildData: Codable {
    let author_fullname: String?
    let title: String
    let downs: Int
    let ups: Int
    let created: Int
    let domain: String
    let num_comments: Int
    let url: String
    let permalink:String
}
