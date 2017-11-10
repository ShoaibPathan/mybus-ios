//
//  User.swift
//  MyBus
//
//  Created by Lisandro Falconi on 4/18/16.
//  Copyright © 2016 Spark Digital. All rights reserved.
//

import Foundation
import RealmSwift

class User: Object
{
    @objc dynamic var name = "DeviceiOS"
    var favourites = List<RoutePoint> ()
    var recents = List<RoutePoint>()
}
