//
//  ApiHandler.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 10/08/2023.
//

import Foundation
import CoreData
import OpenAPIRuntime
import OpenAPIURLSession

struct ApiHandler {
    let client: Client
    
    init() {
        self.client = Client(
            serverURL: try! Servers.server1(),
            transport: URLSessionTransport()
        )
    }
    
    func updateTuinData(context: NSManagedObjectContext) async throws {
        let response = try await client.mijnPientereTuin(
            .init(
                headers: Operations.mijnPientereTuin.Input.Headers(wecity_api_key: "ee3f7468-11fb-43b6-b870-49f9435524c1")
            )
        )
        
        switch response {
        case let .ok(okResponse):
            debugPrint("OK!")
            debugPrint(okResponse.body)
            switch okResponse.body {
            case .json(let json):
                writeToCoreData(apiData: json.content, context: context)
            }
        case .undocumented(statusCode: let statusCode, _):
            debugPrint("Error getting data from server, status: \(statusCode)")
        }
    }
    
    func writeToCoreData(apiData: [Components.Schemas.MeasurementProjection]?, context: NSManagedObjectContext) {
        if let apiData = apiData {
            for item in apiData {
                let dataItem = MeasurementProjection(context: context)
//                dataItem. = item.
                dataItem.measuredAt = item.measuredAt
                dataItem.apiUUID = item.id
                if let moisture = item.moisturePercentage {
                    dataItem.moisturePercentage = moisture
                }
                if let temperature = item.temperatureCelsius {
                    dataItem.temperatureCelcius = Float(temperature)
                }
            }
            
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
