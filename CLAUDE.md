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

- **`API/`** - OpenAPI-generated client wrapper. `ApiHandler` (singleton) calls the `mijnPientereTuin` paginated endpoint. Has server fallback logic (server2 → server1). API spec lives in `openapi.yaml` with config in `openapi-generator-config.yaml`. The API rate-limits to 1 request per 10 seconds and only updates data hourly.

- **`Model/`** - Core Data stack (`Persistence.swift`) uses app group container `group.studio.skipper.Pientere-Tuin` for shared access with the widget. Data model is `Pientere_Tuin.xcdatamodeld` (version 4) with two entities: `Garden` (API key, name) and `MeasurementProjection` (sensor readings). `GardenStore` and `MeasurementStore` provide fetch/query helpers.

- **`Measurement/`** - Chart views and data processing. `ChartModel` transforms `SectionedFetchResults` into `ChartableMeasurement` arrays at different aggregation levels: hourly (day/week scale), daily averages (month scale), monthly averages (year scale). `MesurementChart.swift` (note: typo in filename) is the main chart view, decomposed into sub-views `ChartContent`, `ChartAverageHeader`, and view modifiers `ChartVisibleDomainModifier` and `ChartXAxisModifier`. All scroll-driven state lives in `ChartContent` (not the parent) — `MesurementChart` communicates scale-reset via a `scrollToLatestTrigger: Int` counter and progressive-load via `onScrolledNearOldest` closure.

- **`Garden/`** - Garden setup and API key validation (`LaunchView`).

- **`Weather/`** - Apple WeatherKit integration for daily forecast based on sensor location.

- **`Widget/`** - WidgetKit extension supporting accessoryCircular, accessoryRectangular, accessoryInline, systemSmall, systemMedium families. Reads latest measurement from shared Core Data store.

### State Management

- `PersistenceController.shared` singleton for Core Data
- Background context with `NSMergeByPropertyObjectTrumpMergePolicy` for API writes
- `Preferences` (ObservableObject) for chart scale selection (`ChartScale`: day/week/month/year)
- `WeatherData.shared` for cached weather forecasts
- `ApiHandler.shared` / `ApiTimer` singletons for API access

### Incremental API Loading

`ApiHandler.updateTuinData` supports two loading modes controlled by the `loadAll: Bool` parameter:
- **Normal refresh** (`loadAll: false`): Pages through API results, stopping when it finds a measurement date that already exists in Core Data.
- **Full historical load** (`loadAll: true`): Loads all pages. Used on first setup (`isAddingGarden` flow) to backfill all historical data.

Pagination continues with an 11-second delay between pages (API rate limit is 10 seconds). The `ApiTimer` also enforces a minimum interval between refresh calls from the UI.

### Progressive Chart Data Loading

`MesurementChart` starts by fetching only the most recent 6 months of data (`NSPredicate.recentData(key:monthsBack:6)`). As the user scrolls toward the oldest loaded data, `checkAndExpandDataRange` expands the fetch predicate in 6-month increments (up to 36 months). This avoids loading all historical data upfront.

### Core Data Sectioning

`MeasurementProjection` has a cached `measuredAtDay` attribute (stored `Date`) that holds just the calendar date (no time). It is updated via `awakeFromFetch` and `didChangeValue(forKey:)` in `MeasurementProjection+section.swift`. The `@objc var sectionMeasuredAt: Date` computed property exposes this for use as the `sectionIdentifier` in `@SectionedFetchRequest`.

### Background Refresh

`BGAppRefreshTask` with identifier `studio.skipper.Pientere-Tuin.refresh`, scheduled every 30 minutes. To simulate a background refresh launch in the Xcode debugger:
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"studio.skipper.Pientere-Tuin.refresh"]
```

## Domain Logic

Humidity thresholds are soil-type-specific (defined in `MeasurementProjection+types.swift`). Each `SoilType` has ranges for tooDry, stress, healthy, and tooWet states. The `humidityState` computed property determines the current state.

**Important**: `moisturePercentage` is stored as a decimal fraction (0.0–1.0). Chart display and threshold comparisons use this raw value; the Y-axis multiplies by 100 for display. The Core Data attribute is `temperatureCelcius` (note typo, missing 's') while the API field is `temperatureCelsius`.

Soil types: sand, lightClay, zavel, gardenSoil, pottingSoil (mapped to API raw values like `sand_1_1`, `loam_2`, etc.)

## Dependencies

- **OpenAPIRuntime** + **OpenAPIURLSession** - Generated API client (code gen runs as Xcode build phase plugin)
- **SimpleAnalytics** - Event tracking
- **Apple frameworks**: SwiftUI, CoreData, Charts, WeatherKit, WidgetKit, BackgroundTasks, CoreLocation

## CI/CD

Xcode Cloud with `ci_scripts/ci_post_clone.sh` that disables OpenAPI plugin fingerprint validation for cloud builds.

### Chart Performance Known Issue

Day scale (`ChartScale.day`) is intentionally hidden from the picker — ~1246 data points cause `ChartContent.body` to re-render at ~2fps during scroll (SwiftUI re-runs `body` on every `@State chartScrolledToDate` change). All day scale code is intact; restore `Text("Dag").tag(ChartScale.day)` in `chartScalePicker` to re-enable. The `Debug/` folder (untracked) contains `BodyRateTracker` and `DebugOverlay` for performance instrumentation.

## Notes

- UI text is in Dutch (e.g., "Vandaag", "Morgen", "vochtigheid bodem")
- The app targets iOS 16+ generally, but `MesurementChart` requires iOS 18+ (`LinePlot`/`PointPlot` are unconditional after removing the iOS 16/17 fallback)
- Widget reloads are triggered after successful API data fetches via `WidgetCenter`
- Preview data uses in-memory Core Data store (`PersistenceController.preview`)
