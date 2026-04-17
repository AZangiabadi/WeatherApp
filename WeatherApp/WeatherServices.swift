//
//  WeatherServices.swift
//  WeatherApp
//
//  Created by Assistant on 4/17/26.
//

import Foundation

enum WeatherServiceError: Error, LocalizedError {
    case badURL
    case requestFailed
    case decodingFailed
    case noResults

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid URL"
        case .requestFailed: return "Network request failed"
        case .decodingFailed: return "Failed to decode response"
        case .noResults: return "No results found"
        }
    }
}

protocol GeocodingServiceProtocol {
    func searchCities(matching query: String) async throws -> [City]
}

protocol WeatherServiceProtocol {
    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherData
}

struct GeocodingService: GeocodingServiceProtocol {
    // Using Open-Meteo Geocoding API (no API key required)
    // https://geocoding-api.open-meteo.com/v1/search?name=London&count=10&language=en&format=json
    func searchCities(matching query: String) async throws -> [City] {
        guard var comps = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search") else { throw WeatherServiceError.badURL }
        comps.queryItems = [
            .init(name: "name", value: query),
            .init(name: "count", value: "10"),
            .init(name: "language", value: Locale.current.language.languageCode?.identifier ?? "en"),
            .init(name: "format", value: "json")
        ]
        guard let url = comps.url else { throw WeatherServiceError.badURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw WeatherServiceError.requestFailed }
        let decoded = try JSONDecoder().decode(GeocodingAPIResponse.self, from: data)
        let results = decoded.results ?? []
        if results.isEmpty { throw WeatherServiceError.noResults }
        return results.map { r in
            City(name: r.name, country: r.country, admin1: r.admin1, latitude: r.latitude, longitude: r.longitude)
        }
    }
}

struct WeatherService: WeatherServiceProtocol {
    // Using Open-Meteo Forecast API (no API key required)
    // https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current=temperature_2m&daily=temperature_2m_max,temperature_2m_min&forecast_days=7&timezone=auto
    func fetchWeather(lat: Double, lon: Double) async throws -> WeatherData {
        guard var comps = URLComponents(string: "https://api.open-meteo.com/v1/forecast") else { throw WeatherServiceError.badURL }
        comps.queryItems = [
            .init(name: "latitude", value: String(lat)),
            .init(name: "longitude", value: String(lon)),
            .init(name: "current", value: "temperature_2m"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            .init(name: "forecast_days", value: "7"),
            .init(name: "timezone", value: "auto")
        ]
        guard let url = comps.url else { throw WeatherServiceError.badURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw WeatherServiceError.requestFailed }
        let decoded = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        let currentTemp = decoded.current?.temperature_2m
        let dailyAPI = decoded.daily
        guard let currentTempC = currentTemp, let daily = dailyAPI else { throw WeatherServiceError.decodingFailed }
        var forecasts: [DailyForecast] = []
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        for (idx, day) in daily.time.enumerated() {
            if let date = formatter.date(from: day),
               idx < daily.temperature_2m_max.count,
               idx < daily.temperature_2m_min.count {
                forecasts.append(DailyForecast(date: date,
                                               minTempC: daily.temperature_2m_min[idx],
                                               maxTempC: daily.temperature_2m_max[idx]))
            }
        }
        return WeatherData(currentTempC: currentTempC, daily: forecasts)
    }
}

