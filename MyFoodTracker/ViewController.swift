//
//  ViewController.swift
//  MyFoodTracker
//
//  Created by Frederico Schnekenberg on 11/06/15.
//  Copyright (c) 2015 Frederico Schnekenberg. All rights reserved.
//

import UIKit
import CoreData

// UISearchController requires conforming to these protocols: UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    @IBOutlet weak var tableView: UITableView!
    
    // App ID and Key information
    let kAppID = "16bf5c00"
    let kAppKey = "937591db4eaaa1e3527fcc9a4dd85f03"
    
    // Property for UISearchController
    var searchController: UISearchController!
    
    // Array to hold all the food list
    var suggestedSearchFoods: [String] = []
    // Array to hold filtered food list
    var filteredSuggestedSearchFoods: [String] = []
    
    // Array of Tuples to get food pair values
    var apiSearchForFoods: [(name: String, idValue: String)] = []
    
    // Array of USDAItems for favorited items
    var favoritedUSDAItems: [USDAItem] = []

    // Array of USDAItems for filtered favorited items
    var filteredFavoritedUSDAItems: [USDAItem] = []
    
    // Array for button titles
    var scopeButtonTitles = ["Recommended", "Search Results", "Saved"]
    
    // Stores information about JSON errors
    var jsonResponse:NSDictionary!
    
    // Instanciate DataController to get access to its functions
    var dataController = DataController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Initialize searchController
        self.searchController = UISearchController(searchResultsController: nil)
        // SearchResults
        self.searchController.searchResultsUpdater = self
        // Does not dim the underlying content while searching
        self.searchController.dimsBackgroundDuringPresentation = false
        // Does not hide the nav bar while searching
        self.searchController.hidesNavigationBarDuringPresentation = false
        
        // Draws the search bar onto the screen
        self.searchController.searchBar.frame = CGRectMake(self.searchController.searchBar.frame.origin.x, self.searchController.searchBar.frame.origin.y, self.searchController.searchBar.frame.size.width, 44.0)
        // Add the searchBar to the TableHeaderView
        self.tableView.tableHeaderView = self.searchController.searchBar
        
        // Sets up scope buttons for search
        self.searchController.searchBar.scopeButtonTitles = scopeButtonTitles
        
        // Get access to callbacks that occurs in the search bar
        self.searchController.searchBar.delegate = self
        
        // Esures that the searchBar gets added to the view
        self.definesPresentationContext = true
        
        // Initialize the food list
        self.suggestedSearchFoods = ["apple", "bagel", "banana", "beer", "bread", "carrots", "cheddar cheese", "chicken breast", "chili with beans", "chocolate chip cookie", "coffee", "cola", "corn", "egg", "graham cracker", "granola bar", "green beans", "ground beef patty", "hot dog", "ice cream", "jelly doughnut", "ketchup", "milk", "mixed nuts", "mustard", "oatmeal", "orange juice", "peanut butter", "pizza", "pork chop", "potato", "potato chips", "pretzels", "raisins", "ranch salad dressing", "red wine", "rice", "salsa", "shrimp", "spaghetti", "spaghetti sauce", "tuna", "white wine", "yellow cake"]
        
        // Observer that listens and starts when viewDidLoad loads up
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "usdaItemDidComplete:", name: kUSDAItemCompleted, object: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "toDetailVCSegue" {
            if sender != nil {
                var detailVC = segue.destinationViewController as! DetailViewController
                detailVC.usdaItem = sender as? USDAItem
            }
        }
    }
    
    // deinit is necessary cause NSNotificationCenter is not managed by ARC
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Captures the selected scope button
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        if selectedScopeButtonIndex == 0 {
            
            // Check if the searchController is active, if so presents only suggested food if not presents all food
            if self.searchController.active {
                return self.filteredSuggestedSearchFoods.count
            }
            else {
                return self.filteredSuggestedSearchFoods.count
            }
        } // Recommended
        else if selectedScopeButtonIndex == 1 {
            // Determines the number of rows in the section
            return self.apiSearchForFoods.count
        } // Search Results
        else {
            if self.searchController.active {
                return self.filteredFavoritedUSDAItems.count
            }
            else {
                return self.favoritedUSDAItems.count
            }
        } // Saved
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! UITableViewCell
        
        var foodName: String
        
        // Captures the selected scope button
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        if selectedScopeButtonIndex == 0 {
            
            if self.searchController.active {
                foodName = filteredSuggestedSearchFoods[indexPath.row]
            }
            else {
                foodName = suggestedSearchFoods[indexPath.row]
            }
        } // Recommended
        else if selectedScopeButtonIndex == 1 {
            foodName = apiSearchForFoods[indexPath.row].name
        } // Search Results
        else {
            if self.searchController.active {
                foodName = self.filteredFavoritedUSDAItems[indexPath.row].name
            }
            else {
                foodName = self.favoritedUSDAItems[indexPath.row].name
            }
        } // Saved
        
        cell.textLabel?.text = foodName
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
        
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Captures the selected scope button
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        if selectedScopeButtonIndex == 0 {
            
            var searchFoodName: String
            
            if self.searchController.active {
                searchFoodName = filteredSuggestedSearchFoods[indexPath.row]
            }
            else {
                searchFoodName = suggestedSearchFoods[indexPath.row]
            }
            self.searchController.searchBar.selectedScopeButtonIndex = 1
            makeRequest(searchFoodName)
        }
        else if selectedScopeButtonIndex == 1 {
            self.performSegueWithIdentifier("toDetailVCSegue", sender: nil)
            let idValue = apiSearchForFoods[indexPath.row].idValue
            self.dataController.saveUSDAItemForId(idValue, json: self.jsonResponse)
        }
        else if selectedScopeButtonIndex == 2 {
            if self.searchController.active {
                let usdaItem = filteredFavoritedUSDAItems[indexPath.row]
                self.performSegueWithIdentifier("toDetailVCSegue", sender: usdaItem)
            }
            else {
                let usdaItem = favoritedUSDAItems[indexPath.row]
                self.performSegueWithIdentifier("toDetailVCSegue", sender: usdaItem)
            }
        }
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        // Get the string (food) from the search bar
        let searchString = self.searchController.searchBar.text
        
        // Sets up scope buttons for search (i.e. organizztion tabs)
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        // Passes the search string to filterContent and updated the table wit the result
        if searchString == "" {
            self.filteredSuggestedSearchFoods = self.suggestedSearchFoods
        }
        else {
            self.filterContentForSearch(searchString, scope: selectedScopeButtonIndex)
        }
        // Update the tableView
        self.tableView.reloadData()
    }
    
    func filterContentForSearch(searchText: String, scope: Int) {
        
        if scope == 0 {
            // Update filteredSuggested with the result of the searchText passed, when looking inside suggested food array
            self.filteredSuggestedSearchFoods = self.suggestedSearchFoods.filter({ (food: String) -> Bool in
                var foodMatch = food.rangeOfString(searchText)
                return foodMatch != nil
            })
        }
        else if scope == 2 {
            // Iterates through the filteredFavoritedUSDAItems to check if the string matched, if so it will be added
            self.filteredFavoritedUSDAItems = self.favoritedUSDAItems.filter({ (item: USDAItem) -> Bool in
                var stringMatch = item.name.rangeOfString(searchText)
                return stringMatch != nil
            })
        }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        // Updates the Scope Button to show Search results
        self.searchController.searchBar.selectedScopeButtonIndex = 1
        // Gets the string from search bar and passess it to the makeRequest function
        makeRequest(searchBar.text)
    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        // Calling requestFavariteScope
        if selectedScope == 2 {
            self.requestFavoritedUSDAItems()
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Helper Functions
    
    func makeRequest(searchString: String) {
        
        /* Commented out
        // Gets the URL from the source
        let url = NSURL(string: "https://api.nutritionix.com/v1_1/search/\(searchString)?results=0%3A20&cal_min=0&cal_max=50000&fields=item_name%2Cbrand_name%2Citem_id%2Cbrand_id&appId=\(kAppID)&appKey=\(kAppKey)")
        
        // Opens an HTTP session
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
        
            // converts the data to a readable string
            var stringData = NSString(data: data, encoding: NSUTF8StringEncoding)
            println(stringData)
            println(response)
        
            if error != nil {
                println(error)
            }
        })
        
        // Executes the request (task)
        task.resume()
        */
        
        // Create a mutable NSURL request that allows changing the search criteria
        var request = NSMutableURLRequest(URL: NSURL(string: "https://api.nutritionix.com/v1_1/search/")!)
        // Opens an HTTP request and sets it to POST
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        // Defines the search parameters
        var params = [
            "appId"     : kAppID,
            "appKey"    : kAppKey,
            "fields"    : ["item_name", "brand_name", "keywords", "usda_fields"],
            "limit"     : "50",
            "query"     : searchString,
            "filters"   : ["exists": ["usda_fields" : true]]
        ]
        
        // Holds the error code from JSON
        var error: NSError?
        
        // Converts the params into searcheable filds for JSON request
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &error)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Initializes the HTTP session
        var task = session.dataTaskWithRequest(request, completionHandler: { (data, response, err) -> Void in

            //var stringData = NSString(data: data, encoding: NSUTF8StringEncoding)
            //println(stringData)
            
            var conversionError: NSError?
            var jsonDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves, error: &conversionError) as? NSDictionary
//            println(jsonDictionary)
            
            // Error handling
            if conversionError != nil {
                println(conversionError!.localizedDescription)
                let errorString = NSString(data: data, encoding: NSUTF8StringEncoding)
                println("Error in parsing \(errorString)")
            }
            else {
                if jsonDictionary != nil {
                    // Stores the JSON Dictionary into a property
                    self.jsonResponse = jsonDictionary!
                    
                    // Saves the name and id for foods searched
                    self.apiSearchForFoods = DataController.jsonAsUSDAIdAndNameSearchResults(jsonDictionary!)
                    // Creates an Async request
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                    })
                }
                else {
                    let errorString = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Error, could not parse \(errorString)")
                }
            }
        })
        task.resume()
    }
    
    // MARK: - CoreData
    
    func requestFavoritedUSDAItems() {
        // Get access to USDAItem
        let fetchRequest = NSFetchRequest(entityName: "USDAItem")
        let appDelegate = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
        self.favoritedUSDAItems = appDelegate.executeFetchRequest(fetchRequest, error: nil) as! [USDAItem]
    }
    
    // MARK: - NSNotificationCenter
    
    func usdaItemDidComplete(notification: NSNotification) {
        
        println("usdaItemDidComplete in ViewController")
        
        requestFavoritedUSDAItems()
        // Grabs the current Scope Button Index
        let selectedScopeButtonIndex = self.searchController.searchBar.selectedScopeButtonIndex
        
        // Check if it is the Saved Scope, then reloads the data
        if selectedScopeButtonIndex == 2 {
            self.tableView.reloadData()
        }
    }
    
}

