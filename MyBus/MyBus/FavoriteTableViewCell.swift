//
//  FavoriteTableViewCell.swift
//  MyBus
//
//  Created by Julieta Gonzalez Poume on 9/15/16.
//  Copyright © 2016 Spark Digital. All rights reserved.
//

import UIKit

class FavoriteTableViewCell: UITableViewCell, UITextFieldDelegate {

    var favorite: RoutePoint?
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var address: UITextField!

    func loadItem(favorite: RoutePoint) {
        self.favorite = favorite
        setUpFields()
    }

    func setUpFields() {
        guard let fav = self.favorite else {
            return
        }
        self.name.text = fav.name
        self.address.text = fav.address
        self.name.userInteractionEnabled = false
        self.address.userInteractionEnabled = false
        self.address.delegate = self
        self.name.delegate = self
    }

    func editCell() {
        self.name.userInteractionEnabled = true
        self.name.becomeFirstResponder()
        self.address.userInteractionEnabled = true
    }

    func editFav() {
        self.address.userInteractionEnabled = false
        self.name.userInteractionEnabled = false
        if let fav = favorite, let newAddress = self.address.text, let newName = self.name.text where (newAddress != fav.address || newName != fav.name) {
            ProgressHUD().showLoadingNotification(nil)
            if newAddress != fav.address {
                Connectivity.sharedInstance.getCoordinateFromAddress(newAddress, completionHandler: { (point, error) in
                    if let newFav = point {
                        self.address.text = newFav.address
                        DBManager.sharedInstance.updateFavorite(fav, name: newName, newFavLocation: newFav)
                    } else {
                        self.address.text = fav.address
                        DBManager.sharedInstance.updateFavorite(fav, name: newName, newFavLocation: nil)
                    }
                    ProgressHUD().stopLoadingNotification(nil)
                })
            } else if newName != fav.name {
                DBManager.sharedInstance.updateFavorite(fav, name: newName, newFavLocation: nil)
                ProgressHUD().stopLoadingNotification(nil)
            }

        }
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (self.name == textField){
            self.address.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            self.editFav()
        }
        return true
    }

}
