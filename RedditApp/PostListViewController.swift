//
//  PostListViewController.swift
//  Salamon03
//
//  Created by mac on 21.02.2024.
//

import UIKit
import Network

class PostListViewController: UITableViewController {

    private var posts:[RedditPost]=[]
    private var localSavedPosts:[RedditPost]=[]
    private var filteredSavedPosts:[RedditPost]=[]
    private var postRequestComponent:RequestComponent = RequestComponent()
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var filterButton: UIButton!
    private var searchController:UISearchController=UISearchController(searchResultsController: nil)
    private var isLoading:Bool=false
    private var isTransition=false
    private let netMonitor:NWPathMonitor=NWPathMonitor()
    private var savedLoaded=false
    private var isConnected=false
    private var onlySaved=false
    
    func initSearchController(){
        searchController.searchResultsUpdater=self
        searchController.obscuresBackgroundDuringPresentation=false
        searchController.hidesNavigationBarDuringPresentation=false
        searchController.searchBar.placeholder="Search post..."
        definesPresentationContext=false
        navigationItem.hidesSearchBarWhenScrolling=false
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isTransition{
            table.reloadData()
        }else{
            localSavedPosts=loadSavedPosts()
        }
        isTransition=false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        table.delegate=self
        table.dataSource=self
        table.register(PostListViewCell.nib(), forCellReuseIdentifier: PostListViewCell.indentifier)
        table.translatesAutoresizingMaskIntoConstraints=false
        table.rowHeight=UITableView.automaticDimension
        table.estimatedRowHeight=457
        postRequestComponent.parameters["limit"]=String(10)
        navigationItem.title="/"+postRequestComponent.subreddit.joined(separator: "/")
        netMonitor.pathUpdateHandler={path in            self.isConnected = path.status == .satisfied
        }
        netMonitor.start(queue: DispatchQueue.global())
        filterButton.addTarget(self, action: #selector(onFilterSavedClicked), for: .touchDown)
        initSearchController()
    }
    
    func setSearchBarVisibility(isVisible:Bool){
        navigationItem.searchController=isVisible ? searchController : nil
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if onlySaved{
            if isSearchMode(){
                return filteredSavedPosts.count
            }
           return localSavedPosts.count
        }
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell=table.dequeueReusableCell(withIdentifier: PostListViewCell.indentifier, for: indexPath) as! PostListViewCell
        cell.viewController=self
        if onlySaved{
            if isSearchMode(){
                cell.configurePost(receivedPost: &filteredSavedPosts[indexPath.row])
            }else{
                cell.configurePost(receivedPost: &localSavedPosts[indexPath.row])
            }
        }else{
            cell.configurePost(receivedPost: &posts[indexPath.row])
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let postDetailsViewController=storyboard?.instantiateViewController(withIdentifier: PostDetailsViewController.indentifier) as! PostDetailsViewController
        navigationController?.pushViewController(postDetailsViewController, animated: true)
        postDetailsViewController.configure={
            if self.onlySaved{
                if self.isSearchMode(){
                    postDetailsViewController.configurePost(receivedPost: &self.filteredSavedPosts[indexPath.row])
                }else{
                    postDetailsViewController.configurePost(receivedPost: &self.localSavedPosts[indexPath.row])
                }
            }else{
                postDetailsViewController.configurePost(receivedPost: &self.posts[indexPath.row])
            }        }
        isTransition=true
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func createLoadingFooter()-> UIView{
        let loadingFooter=UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 100))
        let spinner=UIActivityIndicatorView()
        spinner.center=loadingFooter.center
        loadingFooter.addSubview(spinner)
        spinner.startAnimating()
        return loadingFooter
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !onlySaved{
            let positionOffset=scrollView.contentOffset.y
            let bottomBorder=scrollView.contentSize.height-scrollView.frame.height
            if positionOffset>bottomBorder{
                if !isLoading{
                    isLoading=true
                    table.tableFooterView=createLoadingFooter()
                    if isConnected{
                    postRequestComponent.processRequest(completion: {posts in
                        var copyPosts=posts
                        for (index,post) in copyPosts.enumerated(){
                            if self.localSavedPosts.contains(post)  {
                                if self.savedLoaded{
                                    copyPosts.remove(at: index)
                                }else{
                                    copyPosts[index].saved=true
                                }
                            }
                        }
                        self.posts.append(contentsOf: copyPosts)
                        self.isLoading=false
                        DispatchQueue.main.async {
                            self.table.reloadData()
                            self.table.tableFooterView=nil
                        }
                    } , failure: failureConnection)
                    }else{
                        failureConnection()
                    }
                        
                }
            }
        }
    }
    
    func failureConnection(){// including a sudden disconnecting
        if !self.savedLoaded{
            self.posts.append(contentsOf: self.localSavedPosts.filter{!posts.contains($0)})
            self.isLoading=false
            self.savedLoaded=true
            DispatchQueue.main.async {
                self.table.reloadData()
                self.table.tableFooterView=nil
            }
        }
    }
    
    func loadSavedPosts() ->[RedditPost]{
        let fileManager=FileManager.default
        if let documentDir=try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false){
            let fileURL=documentDir.appendingPathComponent("RedditPosts")
            if let jsonData=try? Data(contentsOf: fileURL) {
                if let decodedData=try? JSONDecoder().decode([RedditPost].self, from: jsonData){
                    return decodedData
                }
            }
        }
        return []
    }
    
    @IBAction func onFilterSavedClicked(_ sender: Any) {
        onlySaved.toggle()
        if onlySaved{
            setSearchBarVisibility(isVisible: true)
            localSavedPosts=loadSavedPosts()
            filterButton.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        }else{
            setSearchBarVisibility(isVisible: false)
            filterButton.setImage(UIImage(systemName: "bookmark"), for: .normal)
        }
        table.reloadData()
    }

}

extension PostListViewController:UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText=searchController.searchBar.text?.lowercased(){
            filteredSavedPosts=loadSavedPosts().filter{
                $0.title.lowercased().contains(searchText)
            }
        }
        table.reloadData()
    }
    
    func isSearchMode() ->Bool{
        let isActiveSearch=searchController.isActive
        let searchBarText=searchController.searchBar.text ?? ""
        return isActiveSearch && !searchBarText.isEmpty
    }
    
    
}

