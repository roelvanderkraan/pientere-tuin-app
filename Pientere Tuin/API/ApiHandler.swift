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
import WidgetKit

struct ApiHandler {
    let client: Client
    let apiRequestInterval = 10
    
    static let shared = ApiHandler()
    
    init() {
        self.client = Client(
            serverURL: try! Servers.server1(),
            transport: URLSessionTransport()
        )
    }
    
    /// Loads measurements from Pientere Tuinen API
    /// - Parameters:
    ///   - context: Context to store the measurements in
    ///   - page: Page to start parsing
    ///   - loadAll: Should the parser load all or just the 1st page
    func updateTuinData(context: NSManagedObjectContext, page: Int = 0, loadAll: Bool = false, garden: Garden) async throws {
        debugPrint("Requesting page \(page)")
        guard garden.apiKey != nil else {
            debugPrint("Warning, API key empty")
            throw NotAuthorizedError()
        }
        let response = try await client.mijnPientereTuin(
            .init(
                query: Operations.mijnPientereTuin.Input.Query(page: Int32(page)),
                headers: Operations.mijnPientereTuin.Input.Headers(wecity_api_key: garden.apiKey)
            )
        )
        
        switch response {
        case let .ok(okResponse):
            debugPrint("OK response")
            switch okResponse.body {
            case .json(let json):
                debugPrint(json.content)
                debugPrint(json.totalPages)
                writeToCoreData(apiData: json.content, context: context, garden: garden)
                
                // Check if there are more pages to parse. Continue until we hit the last page
                if loadAll && json.content?.count ?? 0 > 0 && !(json.last ?? true) {
                    Task {
                        let interval = apiRequestInterval + 1 // API has 10 seconds rate limit
                        debugPrint("Scheduling next parse for page \(page+1) in \(interval) seconds")
                        try await Task.sleep(for: .seconds(interval)) // API has 10 seconds rate limit
                        try await updateTuinData(context: context, page: page+1, loadAll: true, garden: garden)
                    }
                }
                // Only when new data?
                resetWidgets()
            }
        case .undocumented(statusCode: let statusCode, _):
            debugPrint("Error getting data from server, status: \(statusCode)")
            throw APIError.generic(statuscode: statusCode)
        case .badRequest(_):
            debugPrint("Bad request")
            throw APIError.badRequest
        case .unauthorized(_):
            debugPrint("Unauthorized, check API key")
            throw APIError.notAuthorized
        case .notFound(_):
            debugPrint("API not found")
            throw APIError.notFound
        case .serverError(statusCode: let statusCode, _):
            debugPrint("Server error, status: \(statusCode)")
            throw APIError.generic(statuscode: statusCode)
        case .tooManyRequests(_):
            debugPrint("Too many requests, 1 request per 10 seconds allowed.")
            throw APIError.tooManyRequests
         }
    }
    
    private func writeToCoreData(apiData: [Components.Schemas.MeasurementProjection]?, context: NSManagedObjectContext, garden: Garden) {
        if let apiData = apiData {
            for item in apiData {
                let dataItem = MeasurementProjection(context: context)
                dataItem.measuredAt = item.measuredAt
                dataItem.apiUUID = item.id
                if let moisture = item.moisturePercentage {
                    dataItem.moisturePercentage = moisture
                }
                if let temperature = item.temperatureCelsius {
                    dataItem.temperatureCelcius = Float(temperature)
                }
                if let latitude = item.latitude {
                    dataItem.latitude = latitude
                }
                if let longitude = item.longitude {
                    dataItem.longitude = longitude
                }
                if let gardenHardeningPercentage = item.gardenHardeningPercentage {
                    dataItem.gardenHardeningPercentage = gardenHardeningPercentage
                }
                dataItem.gardenOrientation = item.gardenOrientation
                dataItem.gardenSize = item.gardenSize
                dataItem.soilType = item.soilType
                dataItem.inGarden = garden
            }
            
            context.perform {
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
    
    private func resetWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "studio.skipper.Pientere-Tuin.widget")
    }
}

