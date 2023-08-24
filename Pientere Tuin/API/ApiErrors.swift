//
//  ApiErrors.swift
//  Pientere Tuin
//
//  Created by Roel van der Kraan on 15/08/2023.
//

import Foundation
/*
case .undocumented(statusCode: let statusCode, _):
    debugPrint("Error getting data from server, status: \(statusCode)")
case .badRequest(_):
    debugPrint("Bad request")
case .unauthorized(_):
    debugPrint("Unauthorized, check API key")
    throw NotAuthorizedException()
case .notFound(_):
    debugPrint("API not found")
case .serverError(statusCode: let statusCode, _):
    debugPrint("Server error, status: \(statusCode)")
case .tooManyRequests(_):
    debugPrint("Too many requests, 1 request per 10 seconds allowed.")
 */

enum APIError: Error {
    case badRequest
    case notAuthorized
    case notFound
    case generic(statuscode: Int)
    case tooManyRequests
}

class BadRequestError: Error {
    
}

class NotAuthorizedError: Error {
    
}

class NotFoundError: Error {
    
}

class GenericError: Error {
    
}

class TooManyRequestsError: Error {
    
}

