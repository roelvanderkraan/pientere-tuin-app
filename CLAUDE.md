# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pientere Tuin is a Dutch-language iOS app for monitoring garden soil moisture and temperature sensors from the Pientere Tuinen / Good City Sense service. It fetches paginated measurement data via an OpenAPI-generated client, stores it in Core Data, and visualizes it with interactive Swift Charts. Includes a WidgetKit extension for home screen widgets.

## Build & Run

```bash
# Build via CLI (workspace required for SPM dependencies)
xcodebuild -workspace SensorApp.xcworkspace -scheme "Pientere Tuin" -configuration Debug build

# Run tests
xcodebuild test -workspace SensorApp.xcworkspace -scheme "Pientere Tuin" -destination 'platform=iOS Simulator,name=iPhone 16'

# Build widget
xcodebuild -workspace SensorApp.xcworkspace -scheme "Widget" build
```

Open `SensorApp.xcworkspace` in Xcode (not the .xcodeproj) to include SPM dependencies.

## Architecture

### Data Flow

API (OpenAPI client) → `ApiHandler` writes to Core Data → SwiftUI views use `@FetchRequest`/`@SectionedFetchRequest` → `ChartModel` aggregates data for charts

### Key Layers

- **`API/`** - OpenAPI-generated client wrapper. `ApiHandler` (singleton) calls the `mijnPientereTuin` paginated endpoint with a 10-second rate limit enforced by `ApiTimer`. Has server fallback logic (server2 → server1). API spec lives in `openapi.yaml` with config in `openapi-generator-config.yaml`.

- **`Model/`** - Core Data stack (`Persistence.swift`) uses app group container `group.studio.skipper.Pientere-Tuin` for shared access with the widget. Data model is `Pientere_Tuin.xcdatamodeld` (version 4) with two entities: `Garden` (API key, name) and `MeasurementProjection` (sensor readings with moisture, temperature, location, soil type metadata). `GardenStore` and `MeasurementStore` provide fetch/query helpers.

- **`Measurement/`** - Chart views and data processing. `ChartModel` transforms `SectionedFetchResults` into `ChartableMeasurement` arrays at different aggregation levels: hourly (day/week scale), daily averages (month scale), yearly averages (all scale). `MesurementChart.swift` (note: typo in filename) is the main interactive chart with horizontal scrolling.

- **`Garden/`** - Garden setup and API key validation (`LaunchView`).

- **`Weather/`** - Apple WeatherKit integration for daily forecast based on sensor location.

- **`Widget/`** - WidgetKit extension supporting accessoryCircular, accessoryRectangular, accessoryInline, systemSmall, systemMedium families. Reads latest measurement from shared Core Data store.

### State Management

- `PersistenceController.shared` singleton for Core Data
- Background context with `NSMergeByPropertyObjectTrumpMergePolicy` for API writes
- `Preferences` (ObservableObject) for chart scale selection
- `WeatherData.shared` for cached weather forecasts
- `ApiHandler.shared` / `ApiTimer` singletons for API access

### Background Refresh

`BGAppRefreshTask` with identifier `studio.skipper.Pientere-Tuin.refresh`, scheduled every 30 minutes. Configured in `Pientere-Tuin-Info.plist`.

## Domain Logic

Humidity thresholds are soil-type-specific (defined in `MeasurementProjection+types.swift`). Each `SoilType` has ranges for tooDry, stress, healthy (good), and tooWet states. The `humidityState` computed property determines the current state from `moisturePercentage` and soil type.

Soil types: sand, lightClay, zavel, gardenSoil, pottingSoil (mapped to API raw values like `sand_1_1`, `loam_2`, etc.)

## Dependencies

- **OpenAPIRuntime** + **OpenAPIURLSession** - Generated API client (code gen runs as Xcode build phase plugin)
- **SimpleAnalytics** - Event tracking
- **Apple frameworks**: SwiftUI, CoreData, Charts, WeatherKit, WidgetKit, BackgroundTasks, CoreLocation

## CI/CD

Xcode Cloud with `ci_scripts/ci_post_clone.sh` that disables OpenAPI plugin fingerprint validation for cloud builds.

## Notes

- UI text is in Dutch (e.g., "Vandaag", "Morgen", "vochtigheid bodem")
- The app targets iOS 16+ with conditional iOS 17 features
- Widget reloads are triggered after successful API data fetches via `WidgetCenter`
- Preview data uses in-memory Core Data store (`PersistenceController.preview`)
