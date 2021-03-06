//
//  CompleteBusItineraryTest.swift
//  MyBus
//
//  Created by Marcos Jesus Vivar on 11/10/16.
//  Copyright © 2016 Spark Digital. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import MYBUS

class CompleteBusItineraryTest: XCTestCase
{
    var going511ACompleteRoute: CompleteBusRoute = CompleteBusRoute()
    var returning511ACompleteRoute: CompleteBusRoute = CompleteBusRoute()
    var complete511ARoute: CompleteBusRoute = CompleteBusRoute()
    
    var going571BCompleteRoute: CompleteBusRoute = CompleteBusRoute()
    var returning571BCompleteRoute: CompleteBusRoute = CompleteBusRoute()
    var complete571BRoute: CompleteBusRoute = CompleteBusRoute()
    
    var bus511AItinerary:CompleteBusItineray = CompleteBusItineray()
    var bus571BItinerary:CompleteBusItineray = CompleteBusItineray()
    
    override func setUp()
    {
        super.setUp()
    
        let going511ACompleteRouteFilePath = Bundle(for: BusSearchResultSingleTest.self).path(forResource: "511AGoingCompleteBusRoute", ofType: "json")
        let returning511ACompleteRouteFilePath = Bundle(for: BusSearchResultSingleTest.self).path(forResource: "511AReturningCompleteBusRoute", ofType: "json")
        
        let going571BCompleteRouteFilePath = Bundle(for: BusSearchResultSingleTest.self).path(forResource: "571BGoingCompleteBusRoute", ofType: "json")
        let returning571BCompleteRouteFilePath = Bundle(for: BusSearchResultSingleTest.self).path(forResource: "571BReturningCompleteBusRoute", ofType: "json")
        
        let going511ACompleteRouteJSONData = try! Data(contentsOf: URL(fileURLWithPath: going511ACompleteRouteFilePath!), options:.mappedIfSafe)
        let returning511ACompleteRouteJSONData = try! Data(contentsOf: URL(fileURLWithPath: returning511ACompleteRouteFilePath!), options:.mappedIfSafe)
        let going571BCompleteRouteJSONData = try! Data(contentsOf: URL(fileURLWithPath: going571BCompleteRouteFilePath!), options:.mappedIfSafe)
        let returning571BCompleteRouteJSONData = try! Data(contentsOf: URL(fileURLWithPath: returning571BCompleteRouteFilePath!), options:.mappedIfSafe)
        
        let going511ACompleteRouteJSON = try! JSONSerialization.jsonObject(with: going511ACompleteRouteJSONData, options: .mutableContainers)
        let returning511ACompleteRouteJSON = try! JSONSerialization.jsonObject(with: returning511ACompleteRouteJSONData, options: .mutableContainers)
        let going571BCompleteRouteJSON = try! JSONSerialization.jsonObject(with: going571BCompleteRouteJSONData, options: .mutableContainers)
        let returning571BCompleteRouteJSON = try! JSONSerialization.jsonObject(with: returning571BCompleteRouteJSONData, options: .mutableContainers)
        
        let going511ACompleteRouteDictionary = JSON(going511ACompleteRouteJSON)
        let returning511ACompleteRouteDictionary = JSON(returning511ACompleteRouteJSON)
        let going571BCompleteRouteDictionary = JSON(going571BCompleteRouteJSON)
        let returning571BCompleteRouteDictionary = JSON(returning571BCompleteRouteJSON)
        
        going511ACompleteRoute = CompleteBusRoute().parseOneWayBusRoute(going511ACompleteRouteDictionary, busLineName: "")
        returning511ACompleteRoute = CompleteBusRoute().parseOneWayBusRoute(returning511ACompleteRouteDictionary, busLineName: "")
        complete511ARoute.busLineName = "511a"
        complete511ARoute.goingPointList = going511ACompleteRoute.goingPointList
        complete511ARoute.returnPointList = returning511ACompleteRoute.goingPointList
        
        going571BCompleteRoute = CompleteBusRoute().parseOneWayBusRoute(going571BCompleteRouteDictionary, busLineName: "")
        returning571BCompleteRoute = CompleteBusRoute().parseOneWayBusRoute(returning571BCompleteRouteDictionary, busLineName: "")
        complete571BRoute.busLineName = "571b"
        complete571BRoute.goingPointList = going571BCompleteRoute.goingPointList
        complete571BRoute.returnPointList = returning571BCompleteRoute.goingPointList
        
        bus511AItinerary.busLineName = complete511ARoute.busLineName
        bus511AItinerary.goingItineraryPoint.append(objectsIn: complete511ARoute.goingPointList)
        bus511AItinerary.returnItineraryPoint.append(objectsIn: complete511ARoute.returnPointList)
        bus511AItinerary.savedDate = Date()
        
        bus571BItinerary.busLineName = complete571BRoute.busLineName
        bus571BItinerary.goingItineraryPoint.append(objectsIn: complete571BRoute.goingPointList)
        bus571BItinerary.returnItineraryPoint.append(objectsIn: complete571BRoute.returnPointList)
        bus571BItinerary.savedDate = Date()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testResultExistence()
    {
        XCTAssertNotNil(complete511ARoute)
        XCTAssertNotNil(complete571BRoute)
        
        XCTAssertNotNil(bus511AItinerary)
        XCTAssertNotNil(bus571BItinerary)
    }
    
    func testResultUniqueness()
    {
        XCTAssertNotEqual(bus511AItinerary.busLineName, bus571BItinerary.busLineName)
        XCTAssertEqual(bus511AItinerary.busLineName, complete511ARoute.busLineName)
        XCTAssertEqual(bus571BItinerary.busLineName, complete571BRoute.busLineName)
    }
    
    func testResultContents()
    {
        XCTAssertNotNil(bus511AItinerary.busLineName)
        XCTAssert(bus511AItinerary.goingItineraryPoint.count > 0)
        XCTAssert(bus511AItinerary.returnItineraryPoint.count > 0)
        XCTAssertNotNil(bus511AItinerary.savedDate)
        
        XCTAssertNotNil(bus571BItinerary.busLineName)
        XCTAssert(bus571BItinerary.goingItineraryPoint.count > 0)
        XCTAssert(bus571BItinerary.returnItineraryPoint.count > 0)
        XCTAssertNotNil(bus571BItinerary.savedDate)
    }
    
    func testResultForBus511AItineraryValidContents()
    {
        for case let item:RoutePoint in bus511AItinerary.goingItineraryPoint
        {
            XCTAssertNotNil(item.stopId)
            XCTAssertNotNil(item.latitude)
            XCTAssertNotNil(item.longitude)
            XCTAssertNotNil(item.address)
            XCTAssertNotNil(item.isWaypoint)
            XCTAssertNotNil(item.name)
        }
        
        for case let item:RoutePoint in bus511AItinerary.returnItineraryPoint
        {
            XCTAssertNotNil(item.stopId)
            XCTAssertNotNil(item.latitude)
            XCTAssertNotNil(item.longitude)
            XCTAssertNotNil(item.address)
            XCTAssertNotNil(item.isWaypoint)
            XCTAssertNotNil(item.name)
        }
        
    }
    
    func testResultForBus571BItineraryValidContents()
    {
        for case let item:RoutePoint in bus571BItinerary.goingItineraryPoint
        {
            XCTAssertNotNil(item.stopId)
            XCTAssertNotNil(item.latitude)
            XCTAssertNotNil(item.longitude)
            XCTAssertNotNil(item.address)
            XCTAssertNotNil(item.isWaypoint)
            XCTAssertNotNil(item.name)
        }
        
        for case let item:RoutePoint in bus571BItinerary.returnItineraryPoint
        {
            XCTAssertNotNil(item.stopId)
            XCTAssertNotNil(item.latitude)
            XCTAssertNotNil(item.longitude)
            XCTAssertNotNil(item.address)
            XCTAssertNotNil(item.isWaypoint)
            XCTAssertNotNil(item.name)
        }
    }
}
