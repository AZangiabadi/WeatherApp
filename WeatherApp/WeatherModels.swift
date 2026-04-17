//
//  WeatherModels.swift
//  WeatherApp
//
//  Created by Assistant on 4/17/26.
//

import Foundation

// MARK: - Domain Models

struct City: Identifiable, Hashable, Codable {
    var id: String { "\(name)-\(latitude)-\(longitude)" }
    let name: String
    let country: String?
    let admin1: String?
    let latitude: Double
    let longitude: Double

    var displayName: String {
        var parts: [String] = [name]
        if let admin1, !admin1.isEmpty { parts.append(admin1) }
        if let country, !country.isEmpty { parts.append(country) }
        return parts.joined(separator: ", ")
    }
}

struct DailyForecast: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let minTempC: Double
    let maxTempC: Double
}

struct WeatherData {
    let currentTempC: Double
    let daily: [DailyForecast]
}

// MARK: - API DTOs

struct GeocodingAPIResponse: Codable {
    let results: [GeocodingResult]?
}

struct GeocodingResult: Codable {
    let id: Int?
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?
}

struct WeatherAPIResponse: Codable {
    struct Current: Codable {
        let temperature_2m: Double?
    }
    struct Daily: Codable {
        let time: [String]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }
    let current: Current?
    let daily: Daily?
    let timezone: String?
}
