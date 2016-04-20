//
//  SearchViewController.swift
//  MyBus
//
//  Created by Marcos Vivar on 4/13/16.
//  Copyright © 2016 Spark Digital. All rights reserved.
//

import UIKit
import Mapbox
import RealmSwift

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
    
    @IBOutlet var resultsTableView: UITableView!
    @IBOutlet var originTextfield: UITextField!
    @IBOutlet var destinationTextfield: UITextField!
    
    var bestMatches : [String] = []
    var favourites : List<Location>!
    
    @IBOutlet var favoriteOriginButton: UIButton!
    @IBOutlet var favoriteDestinationButton: UIButton!
    
    // MARK: - View Lifecycle Methods
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.originTextfield.addTarget(self, action: #selector(SearchViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
        self.destinationTextfield.addTarget(self, action: #selector(SearchViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        // Create realm pointing to default file
        let realm = try! Realm()
        // Retrive favs locations for user
        favourites = realm.objects(User).first?.favourites
    }
    
    // MARK: - IBAction Methods
    
    @IBAction func favoriteOriginTapped(sender: AnyObject)
    {}
    
    @IBAction func favoriteDestinationTapped(sender: AnyObject)
    {}
    
    // MARK: - UITableViewDataSource Methods
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        switch indexPath.section
        {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier("FavoritesIdentifier", forIndexPath: indexPath) as UITableViewCell
            let fav = favourites[indexPath.row]
            let cellLabel : String
            if(fav.name.isEmpty){
                cellLabel = fav.address
            } else
            {
                cellLabel = fav.name
                cell.detailTextLabel?.text = fav.address
            }
            cell.textLabel?.text = cellLabel
            return cell
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier("BestMatchesIdentifier", forIndexPath: indexPath) as! BestMatchTableViewCell
            cell.name.text = self.bestMatches[indexPath.row]
            return cell
            
        default:
            let cell = tableView.dequeueReusableCellWithIdentifier("BestMatchesIdentifier", forIndexPath: indexPath) as UITableViewCell
            
            return cell
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch section
        {
        case 0:
            if let listFavs = favourites{
                return listFavs.count
            }
            return 0
        case 1:
            return bestMatches.count
            
        default:
            return bestMatches.count
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        switch section
        {
        case 0:
            return "Favorites"
        case 1:
            return "Best Matches"
            
        default:
            return "Best Matches"
        }
    }
    
    // MARK: - UITableViewDelegate Methods
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {}
    
    // MARK: - Textfields Methods
    
    func textFieldDidChange(sender: UITextField){
        Connectivity.sharedInstance.getStreetNames(forName: sender.text!) { (streets, error) in
            if error == nil {
                self.bestMatches = []
                for street in streets! {
                    self.bestMatches.append(street.name)
                }
                self.resultsTableView.reloadData()
            }
        }
    }
    
    // MARK: - Memory Management Methods
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}