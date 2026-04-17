//
//  ContentView.swift
//  WeatherApp
//
//  Created by Amirali Zangiabadi on 4/17/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = WeatherViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Search
                searchSection

                // Current weather / forecast
                weatherSection

                Spacer()
            }
            .padding()
            .navigationTitle("Weather")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search city", text: $viewModel.query)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
            }
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))

            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, alignment: .leading)
            }

            if let message = viewModel.errorMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            if !viewModel.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.suggestions) { city in
                        Button {
                            Task { await viewModel.selectCity(city) }
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(.tint)
                                Text(city.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if city != viewModel.suggestions.last {
                            Divider()
                        }
                    }
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var weatherSection: some View {
        Group {
            if let city = viewModel.selectedCity, let temp = viewModel.currentTempC {
                VStack(alignment: .leading, spacing: 12) {
                    Text(city.displayName)
                        .font(.title3)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: { viewModel.toggleForecast() }) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(String(format: "%.0f", temp))
                                .font(.system(size: 56, weight: .semibold, design: .rounded))
                            Text("°C current")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)

                    if viewModel.showForecast {
                        forecastList
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .animation(.snappy, value: viewModel.showForecast)
            } else {
                ContentUnavailableView("Search a city", systemImage: "cloud.sun", description: Text("Type a city name to see weather."))
            }
        }
    }

    private var forecastList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.daily) { day in
                HStack {
                    Text(day.date, style: .date)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 12) {
                        Label("\(Int(day.maxTempC))°", systemImage: "arrow.up")
                        Label("\(Int(day.minTempC))°", systemImage: "arrow.down")
                    }
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.secondary)
                }
                if day != viewModel.daily.last { Divider() }
            }
        }
    }
}

#Preview {
    ContentView()
}
