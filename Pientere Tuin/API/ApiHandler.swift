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
    
    /// Loads measurements from Pientere Tuinen API
    /// - Parameters:
    ///   - context: Context to store the measurements in
    ///   - page: Page to start parsing
    ///   - loadAll: Should the parser load all or just the 1st page
    func updateTuinData(context: NSManagedObjectContext, page: Int = 0, loadAll: Bool = false, garden: Garden) async throws {
        debugPrint("Requesting page \(page)")
        let response = try await client.mijnPientereTuin(
            .init(
                query: Operations.mijnPientereTuin.Input.Query(page: Int32(page)),
                headers: Operations.mijnPientereTuin.Input.Headers(wecity_api_key: garden.apiKey)
            )
        )
        
        switch response {
        case let .ok(okResponse):
            debugPrint("OK response")
            //debugPrint(okResponse.body)
            switch okResponse.body {
            case .json(let json):
                writeToCoreData(apiData: json.content, context: context, garden: garden)
                
                // Check if there are more pages to parse
                if loadAll && !(json.last ?? false) {
                    Task {
                        try await Task.sleep(for: .seconds(10))
                        try await updateTuinData(context: context, page: page+1, loadAll: true, garden: garden)
                    }
                }
            }
        case .undocumented(statusCode: let statusCode, _):
            debugPrint("Error getting data from server, status: \(statusCode)")
        case .badRequest(_):
            debugPrint("Bad request")
        case .unauthorized(_):
            debugPrint("Unauthorized, check API key")
        case .notFound(_):
            debugPrint("API not found")
        case .serverError(statusCode: let statusCode, _):
            debugPrint("Server error, status: \(statusCode)")
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
                dataItem.inGarden = garden
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
