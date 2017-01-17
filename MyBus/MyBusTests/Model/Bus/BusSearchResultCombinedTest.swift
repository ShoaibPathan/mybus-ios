//
//  BusSearchResultCombinedTest.swift
//  MyBus
//
//  Created by Marcos Jesus Vivar on 11/10/16.
//  Copyright © 2016 Spark Digital. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import MYBUS

class BusSearchResultCombinedTest: XCTestCase
{
    var firstBusRouteResultCombined: [BusRouteResult] = []
    var secondBusRouteResultCombined: [BusRouteResult] = []
    
    var firstCombinedOriginRoutePoint:RoutePoint = RoutePoint()
    var firstCombinedDestinationRoutePoint:RoutePoint = RoutePoint()
    var secondCombinedOriginRoutePoint:RoutePoint = RoutePoint()
    var secondCombinedDestinationRoutePoint:RoutePoint = RoutePoint()
    
    var firstBusSearchResultCombined: BusSearchResult = BusSearchResult()!
    var secondBusSearchResultCombined: BusSearchResult = BusSearchResult()!
    
    override func setUp()
    {
        super.setUp()

        let firstCombinedRouteFilePath = Bundle(for: BusSearchResultCombinedTest.self).path(forResource: "BusRouteResultCombined_1", ofType: "json")
        let secondCombinedRouteFilePath = Bundle(for: BusSearchResultCombinedTest.self).path(forResource: "BusRouteResultCombined_2", ofType: "json")
        
        let firstCombinedOriginRoutePointFilePath = Bundle(for: BusSearchResultCombinedTest.self).path(forResource: "RoutePointCombined_1_1", ofType: "json")
        let firstCombinedDestinationRoutePointFilePath = Bundle(for: BusSearchResultCombinedTest.self).path(forResource: "RoutePointCombined_1_2", ofType: "json")
        let secondCombinedOriginRoutePointFilePath = Bundle(for: BusSearchResultCombinedTest.self).path(forResource: "RoutePointCombined_2_1", ofType: "json")
        let secondCombinedDestinationRoutePointFilePath = Bundle(for: BusSearchResultCombinedTest.self).path(forResource: "RoutePointCombined_2_2", ofType: "json")
        
        // Combined Routes
        let firstCombinedRouteJSONData = try! Data(contentsOf: URL(fileURLWithPath: firstCombinedRouteFilePath!), options:.mappedIfSafe)
        let secondCombinedRouteJSONData = try! Data(contentsOf: URL(fileURLWithPath: secondCombinedRouteFilePath!), options:.mappedIfSafe)
        
        let firstCombinedRouteJSON = try! JSONSerialization.jsonObject(with: firstCombinedRouteJSONData, options: .mutableContainers)
        let secondCombinedRouteJSON = try! JSONSerialization.jsonObject(with: secondCombinedRouteJSONData, options: .mutableContainers)
        
        var firstCombinedRouteDictionary = JSON(firstCombinedRouteJSON)
        var secondCombinedRouteDictionary = JSON(secondCombinedRouteJSON)
        
        let firstCombinedRouteType = firstCombinedRouteDictionary["Type"].intValue
        let firstCombinedRouteResults = firstCombinedRouteDictionary["Results"]
        
        let secondCombinedRouteType = secondCombinedRouteDictionary["Type"].intValue
        let secondCombinedRouteResults = secondCombinedRouteDictionary["Results"]
        
        // Combined Routes' Points
        let firstCombinedOriginRoutePointJSONData = try! Data(contentsOf: URL(fileURLWithPath: firstCombinedOriginRoutePointFilePath!), options:.mappedIfSafe)
        let firstCombinedDestinationRoutePointJSONData = try! Data(contentsOf: URL(fileURLWithPath: firstCombinedDestinationRoutePointFilePath!), options:.mappedIfSafe)
        let secondCombinedOriginRoutePointJSONData = try! Data(contentsOf: URL(fileURLWithPath: secondCombinedOriginRoutePointFilePath!), options:.mappedIfSafe)
        let secondCombinedDestinationRoutePointJSONData = try! Data(contentsOf: URL(fileURLWithPath: secondCombinedDestinationRoutePointFilePath!), options:.mappedIfSafe)
        
        let firstCombinedOriginRoutePointJSON = try! JSONSerialization.jsonObject(with: firstCombinedOriginRoutePointJSONData, options: .mutableContainers)
        let firstCombinedDestinationRoutePointJSON = try! JSONSerialization.jsonObject(with: firstCombinedDestinationRoutePointJSONData, options: .mutableContainers)
        let secondCombinedOriginRoutePointJSON = try! JSONSerialization.jsonObject(with: secondCombinedOriginRoutePointJSONData, options: .mutableContainers)
        let secondCombinedDestinationRoutePointJSON = try! JSONSerialization.jsonObject(with: secondCombinedDestinationRoutePointJSONData, options: .mutableContainers)
        
        let firstCombinedOriginRoutePointDictionary = JSON(firstCombinedOriginRoutePointJSON)
        let firstCombinedDestinationRoutePointDictionary = JSON(firstCombinedDestinationRoutePointJSON)
        let secondCombinedOriginRoutePointDictionary = JSON(secondCombinedOriginRoutePointJSON)
        let secondCombinedDestinationRoutePointDictionary = JSON(secondCombinedDestinationRoutePointJSON)
        
        // For logging purposes
        /*
        print("1st BusRouteResult: \(firstCombinedRouteDictionary)")
        print("1st OriginRoutePoint: \(firstCombinedOriginRoutePointDictionary)")
        print("1st DestinationRoutePoint: \(firstCombinedDestinationRoutePointDictionary)")
         
        print("2nd BusRouteResult: \(secondCombinedRouteDictionary)")
        print("2nd OriginRoutePoint: \(secondCombinedOriginRoutePointDictionary)")
        print("2nd DestinationRoutePoint: \(secondCombinedDestinationRoutePointDictionary)")
        */

        firstBusRouteResultCombined = BusRouteResult.parseResults(firstCombinedRouteResults, type: firstCombinedRouteType)
        secondBusRouteResultCombined = BusRouteResult.parseResults(secondCombinedRouteResults, type: secondCombinedRouteType)

        firstCombinedOriginRoutePoint = RoutePoint.parse(firstCombinedOriginRoutePointDictionary)
        firstCombinedDestinationRoutePoint = RoutePoint.parse(firstCombinedDestinationRoutePointDictionary)
        secondCombinedOriginRoutePoint = RoutePoint.parse(secondCombinedOriginRoutePointDictionary)
        secondCombinedDestinationRoutePoint = RoutePoint.parse(secondCombinedDestinationRoutePointDictionary)
        
        firstBusSearchResultCombined = BusSearchResult(origin: firstCombinedOriginRoutePoint, destination: firstCombinedDestinationRoutePoint, busRoutes: firstBusRouteResultCombined)
        secondBusSearchResultCombined = BusSearchResult(origin: secondCombinedOriginRoutePoint, destination: secondCombinedDestinationRoutePoint, busRoutes: secondBusRouteResultCombined)
    }
    
    override func tearDown()
    {
        super.tearDown()
    }
    
    func testResultExistence()
    {
        XCTAssertNotNil(firstBusSearchResultCombined)
        XCTAssertNotNil(secondBusSearchResultCombined)
    }
    
    func testResultUniqueness()
    {
        XCTAssertNotEqual(firstBusSearchResultCombined.origin, firstBusSearchResultCombined.destination)
        XCTAssertNotEqual(secondBusSearchResultCombined.origin, secondBusSearchResultCombined.destination)
    }
    
    func testResultContents()
    {
        XCTAssert(firstBusSearchResultCombined.hasRouteOptions)
        XCTAssert(secondBusSearchResultCombined.hasRouteOptions)
        
        print("\nFirst BusSearchResult Combined:\n")
        for case let item:BusRouteResult in firstBusSearchResultCombined.busRouteOptions
        {
            XCTAssertNotNil(item)
            XCTAssert(item.busRoutes.count > 0)
            XCTAssertNotNil(item.busRouteType)
            XCTAssertEqual(item.busRouteType, MyBusRouteResultType.combined)
            
            let busSearchDescription = "BusSearchResult with Type:\(item.busRouteType) and CombinationDistance:\(item.combinationDistance)\n"
            
            print(busSearchDescription)
        }
        
        print("\nSecond BusSearchResult Combined:\n")
        for case let item:BusRouteResult in secondBusSearchResultCombined.busRouteOptions
        {
            XCTAssertNotNil(item)
            XCTAssert(item.busRoutes.count > 0)
            XCTAssertNotNil(item.busRouteType)
            XCTAssertEqual(item.busRouteType, MyBusRouteResultType.combined)
            
            let busSearchDescription = "BusSearchResult with Type:\(item.busRouteType) and CombinationDistance:\(item.combinationDistance)\n"
            
            print(busSearchDescription)
        }
    }
}
