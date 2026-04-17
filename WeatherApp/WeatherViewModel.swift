//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Assistant on 4/17/26.
//

import Foundation
import Observation

@Observable
final class WeatherViewModel {
    // Inputs
    var query: String = "" {
        didSet { scheduleSearch() }
    }
    var showForecast: Bool = false

    // Outputs
    var suggestions: [City] = []
    var selectedCity: City?
    var currentTempC: Double?
    var daily: [DailyForecast] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let geocoder: GeocodingServiceProtocol
    private let weather: WeatherServiceProtocol
    private var searchTask: Task<Void, Never>?

    init(geocoder: GeocodingServiceProtocol = GeocodingService(),
         weather: WeatherServiceProtocol = WeatherService()) {
        self.geocoder = geocoder
        self.weather = weather

        // Preload New York City on launch
        Task { @MainActor in
            let nyc = City(name: "New York", country: "United States", admin1: "New York", latitude: 40.7128, longitude: -74.0060)
            await selectCity(nyc)
        }
    }

    func scheduleSearch() {
        errorMessage = nil
        suggestions = []
        selectedCity = nil
        currentTempC = nil
        showForecast = false
        searchTask?.cancel()
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        searchTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            await self.searchCities(q)
        }
    }

    @MainActor
    func searchCities(_ q: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let cities = try await geocoder.searchCities(matching: q)
            self.suggestions = cities
        } catch {
            if (error as? WeatherServiceError) == .noResults {
                self.suggestions = []
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    func selectCity(_ city: City) async {
        selectedCity = city
        suggestions = []
        isLoading = true
        errorMessage = nil
        showForecast = false
        defer { isLoading = false }
        do {
            let data = try await weather.fetchWeather(lat: city.latitude, lon: city.longitude)
            currentTempC = data.currentTempC
            daily = data.daily
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleForecast() {
        guard currentTempC != nil else { return }
        showForecast.toggle()
    }
}

