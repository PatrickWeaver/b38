//
//  Bus.swift
//  B38
//
//  Created by Patrick Weaver on 7/28/18.
//  Copyright © 2018 Patrick Weaver. All rights reserved.
//

import Foundation
import UIKit

func dateFromDatetimeString(dt: String?) -> Date? {
    guard let dtS = dt else {
        return nil
    }
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZ"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: -04 * 3600)
    return dateFormatter.date(from: dtS)
}

func stringIntervalFromDateTime(dt: Date?) -> String {
    guard let interval = dt?.timeIntervalSinceNow else {
        return "Error"
    }
    let intInterval = -Int(interval)
    let hours = intInterval / 3600
    var hoursString = "\(hours):"
    if hours == 0 {
        hoursString = ""
    }
    
    let minutes = (intInterval % 3600) / 60
    var minutesString = "\(minutes):"
    if minutes < 10 {
        minutesString = "0\(minutesString):"
    }
    
    let seconds = (intInterval % 3600) % 60
    var secondsString = String(seconds)
    if seconds < 10 {
        secondsString = "0\(secondsString)"
    }
    let el = "\(hoursString)\(minutesString)\(secondsString)"
    return el
}

struct BusDataBlob: Decodable {
    let jsonSiri: JsonSiri
    
    enum CodingKeys: String, CodingKey {
        case jsonSiri = "Siri"
    }
}


struct JsonSiri: Decodable {
    let serviceDelivery: ServiceDelivery
    
    enum CodingKeys: String, CodingKey {
        case serviceDelivery = "ServiceDelivery"
    }
}

struct ServiceDelivery: Decodable {
    let responseTimestamp: String // Datetime
    let stopMonitoringDelivery: [StopMonitoringDelivery]
    
    enum CodingKeys: String, CodingKey {
        case responseTimestamp = "ResponseTimestamp"
        case stopMonitoringDelivery = "StopMonitoringDelivery"
    }
}

struct StopMonitoringDelivery: Decodable {
    let responseTimestamp: String // Datetime
    let monitoredStopVisits: [MonitoredStopVisit]
    let validUntil: String // Datetime
    
    enum CodingKeys: String, CodingKey {
        case responseTimestamp = "ResponseTimestamp"
        case monitoredStopVisits = "MonitoredStopVisit"
        case validUntil = "ValidUntil"
    }
}

struct MonitoredStopVisit: Decodable {
    let monitoredVehicleJourney: MonitoredVehicleJourney
    let recordedAtTime: String // Datetime
    
    enum CodingKeys: String, CodingKey {
        case monitoredVehicleJourney = "MonitoredVehicleJourney"
        case recordedAtTime = "RecordedAtTime"
    }
}

struct MonitoredVehicleJourney: Decodable {
    let lineRef: String
    var directionString: String
    // let FramedVehicleJourney
    let journeyPattern: String
    let lineName: String
    let lineOperator: String
    let originId: String // BusStop.id
    let destinationId: String // BusStop.id
    let destinationName: String // BusStop.name
    //let situations: // Not sure what this is used for
    var monitored: Bool
    var location: VehicleLocation // Location
    var bearing: Double
    var progressRate: String // ProgressRate
    let blockRef: String
    let vehicleId: String // Vehicle
    let monitoredCall: MonitoredCall
    //let onwardCalls: OnwardCall
    
    enum CodingKeys: String, CodingKey {
        case lineRef = "LineRef"
        case directionString = "DirectionRef"
        //case framedVehicleJourney = "FramedVehicleJourneyRef"
        case journeyPattern = "JourneyPatternRef"
        case lineName = "PublishedLineName"
        case lineOperator = "OperatorRef"
        case originId = "OriginRef"
        case destinationId = "DestinationRef"
        case destinationName = "DestinationName"
        //case situations = "SituationRef"
        case monitored = "Monitored"
        case location = "VehicleLocation"
        case bearing = "Bearing"
        case progressRate = "ProgressRate" // ProgressRate
        case blockRef = "BlockRef"
        case vehicleId = "VehicleRef"
        case monitoredCall = "MonitoredCall"
        // case onwardCalls = "OnwardCalls"
    }
}

struct VehicleLocation: Decodable {
    var lat: Double
    var long: Double
    
    enum CodingKeys: String, CodingKey {
        case lat = "Latitude"
        case long = "Longitude"
    }
}

struct MonitoredCall: Decodable {
    let expectedArrivalTime: String? // Datetime
    var arrivalInterval: String {
        return stringIntervalFromDateTime(dt: dateFromDatetimeString(dt: expectedArrivalTime))
    }
    let expectedDepartureTime: String? //Datetime
    let extensions: MonitoredCallExtension?
    let stopPointId: String?
    let visitNumber: Int?
    let stopPointName: String?
    
    enum CodingKeys: String, CodingKey {
        case expectedArrivalTime = "ExpectedArrivalTime"
        case expectedDepartureTime = "ExpectedDepartureTime"
        case extensions = "Extensions"
        case stopPointId = "StopPointRef"
        case visitNumber = "VisitNumber"
        case stopPointName = "StopPointName"
    }
}

struct MonitoredCallExtension: Decodable {
    let distances: MonitoredCallDistances
    
    enum CodingKeys: String, CodingKey {
        case distances = "Distances"
    }
}

struct MonitoredCallDistances: Decodable {
    let descriptive: String
    let metersAway: Double
    let stopsAway: Int
    let metersAlongRoute: Double
    
    enum CodingKeys: String, CodingKey {
        case descriptive = "PresentableDistance"
        case metersAway = "DistanceFromCall"
        case stopsAway = "StopsFromCall"
        case metersAlongRoute = "CallDistanceAlongRoute"
    }
}

struct OnwardCall: Decodable {
    
}

/*
class BusCell: NSObject, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "\(self.milesAway) miles away"
        return cell
    }
}
*/

struct Bus {
    var id: UUID = UUID.init()
    var descriptiveDistance: String = ""
    var metersAway: Double?
    var milesAway: Double? {
        guard let meters = metersAway else {
            return nil
        }
        return meters * 0.000621371
    }
    var stopsAway: Int?
    var secondsAway: Int?
    var minutesAway: Double? {
        guard let seconds = secondsAway else {
            return nil
        }
        return Double(seconds) / 60.0
    }
    var destinationId: String? // Destination
    var destinationName: String? // Destination
    var arrivalInterval: String
}


