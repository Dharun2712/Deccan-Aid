# SmartAid Testing & Quality Assurance Strategy

## 1. Testing Vision
As an AI-powered emergency ambulance response ecosystem, SmartAid operates in a life-critical domain where system failures can have severe consequences. Our testing vision is to ensure **zero-defect critical paths**, absolute system reliability during emergency spikes, and strict data integrity across all user journeys (Citizens, Drivers, Hospitals, and Administrators).

### Why Testing Matters in Emergency Systems
In emergency response, seconds matter. A delayed Socket.IO event, a miscalculated Google Maps route, or a failed Firebase authentication attempt can directly impact patient outcomes. Quality Assurance in SmartAid is not merely about finding bugs; it is about guaranteeing operational safety and resilience under extreme conditions.

## 2. Quality Objectives & KPIs
Our testing strategy is designed to achieve the following Quality Key Performance Indicators (KPIs):
- **100% Reliability on Critical Workflows**: e.g., SOS creation, automatic accident detection, and ambulance assignment.
- **< 500ms API Latency**: For 95% of critical backend requests.
- **Zero Data Loss**: In MongoDB transactions and Socket.IO real-time events.
- **> 85% Code Coverage**: For backend FastAPI services and Flutter UI logic.
- **Automated Regression**: 100% of P1 bugs must have corresponding automated regression tests.

## 3. Testing Principles
- **Risk-Based Testing**: Prioritize testing efforts based on the potential impact of failure. Emergency flows receive significantly more testing rigor than administrative features.
- **Shift-Left**: Integrate testing early in the development lifecycle via PR validation, automated linting, and static code analysis.
- **Automation First**: Manual testing is reserved exclusively for exploratory testing, usability assessments, and complex edge cases that cannot be easily mocked.

## 4. Test Pyramid Strategy
SmartAid follows a modernized test pyramid, adapted for AI and Realtime capabilities.

```mermaid
graph TD
    A[End-to-End Tests<br/>Simulated Devices / Playwright] --> B[Integration Tests<br/>API / Socket.IO / Database]
    B --> C[Unit Tests<br/>Flutter Widgets / FastAPI Logic]
    
    style A fill:#f9d0c4,stroke:#333,stroke-width:2px
    style B fill:#fcf4cd,stroke:#333,stroke-width:2px
    style C fill:#d4e157,stroke:#333,stroke-width:2px
```

- **Base (Unit Tests)**: High volume, fast execution. Validates individual functions, Flutter widgets, and FastAPI route handlers.
- **Middle (Integration Tests)**: Validates communication between components. Crucial for verifying FastAPI to MongoDB, Socket.IO event broadcasting, and Google Gemini prompt parsing.
- **Top (End-to-End)**: Low volume, high value. Simulates complete user journeys (e.g., Citizen creating an SOS and Driver accepting the request) in a production-like environment.

---

## 5. Unit & Integration Testing Framework

Our foundational testing layers are designed for high speed and extensive coverage, ensuring business logic correctness before code merges.

### Target Coverage Metrics
| Component | Minimum Coverage Target | Primary Tooling |
| :--- | :--- | :--- |
| **FastAPI Backend (Logic/Services)** | 85% | `pytest`, `pytest-cov`, `pytest-asyncio` |
| **Flutter Mobile App (Widgets/Blocs)** | 80% | `flutter test`, `bloc_test`, `mockito` |
| **Data Models / Repositories** | 90% | `pytest` (Backend), `flutter test` (Frontend) |

### 6. Flutter Unit & Widget Testing
- **State Management (Bloc/Riverpod)**: Isolated unit tests verify state transitions triggered by UI events or background tasks (e.g., verifying `AmbulanceAssignedState` emits when a Socket.IO assignment event is received).
- **Widget Testing**: Flutter's `WidgetTester` is used to instantiate UI components in a headless environment. 
  - Validates correct rendering of Maps, SOS buttons, and emergency notification modals.
  - Ensures responsive design constraints are met.
- **Mocking Strategy**: `mockito` is heavily utilized to mock network calls, Firebase dependencies, and platform channels (e.g., GPS location hardware).

### 7. FastAPI Service & Repository Testing
- **Service Layer**: Business logic (e.g., matching the nearest ambulance via geospatial queries) is tested in isolation using `pytest`.
- **Dependency Isolation**: FastAPI's `Dependency Injection` framework is utilized to swap out real database connections or external API clients (Firebase/Google Maps) with mocked versions during testing.
- **Mocking Strategy**:
  - `httpx` or `respx` for mocking external API calls to Google Gemini and Google Maps.
  - `mongomock` or isolated local Docker databases for Repository testing.

### 8. Backend Integration Testing
Integration testing validates the interplay between microservice components without mocking the database.
- **API Endpoint Verification**: `TestClient` (from `Starlette`) is used to execute HTTP requests against fully-wired FastAPI routes to validate JSON schemas, HTTP status codes, and authentication middleware.
- **Database Testing**: 
  - Tests run against a transient **Test MongoDB Database**.
  - Setup and Teardown hooks drop collections between tests to ensure a clean state and prevent test pollution.
  - Validates geospatial indexes (2dsphere) used for ambulance routing.
- **Test Data Management**: Fixtures (`pytest` fixtures) are created to inject predictable, reproducible datasets (e.g., standardized hospital coordinates, mocked citizen profiles) into the test database.

---

## 9. End-to-End (E2E) Testing Approach
End-to-End tests simulate real users interacting with the system, validating the entire tech stack from the Flutter UI through the Cloud Run APIs, down to MongoDB and external AI/Map services.

### Core User Journey Validation Plans
E2E testing focuses on cross-platform workflows. Tools like Flutter Integration Test or Appium are utilized.

1. **Citizen SOS Flow**:
   - Citizen logs in -> Triggers SOS -> System captures GPS via Google Maps -> Backend creates incident -> Citizen UI updates to "Searching for Ambulance".
2. **Ambulance Driver Flow**:
   - Driver connects via Socket.IO -> Receives broadcasted SOS -> Accepts SOS -> Routing initiated via Google Maps API -> Citizen receives Driver coordinates.
3. **Hospital Coordination Flow**:
   - Backend triggers Gemini AI for triage prediction based on citizen's vital inputs -> Hospital dashboard receives pre-arrival notification via WebSocket -> Hospital acknowledges readiness.
4. **Realtime Tracking Flow**:
   - Driver app continuously emits location data over Socket.IO -> Backend processes stream -> Citizen app renders real-time movement on map.

## 10. Performance & Load Testing
Performance testing ensures SmartAid can handle sudden city-wide emergencies without degradation.

### Testing Strategy & Tooling
We utilize tools like **Locust** or **k6** for backend load testing, simulating thousands of concurrent users.

- **Load Testing**: Determining system behavior under expected peak usage.
  - *Scenario*: Simulating 500 active ambulances emitting Socket.IO location pings every 3 seconds.
- **Stress Testing**: Pushing the system beyond its limits to identify the breaking point and observe how Cloud Run auto-scaling responds.
  - *Scenario*: Ramping up to 10,000 concurrent citizen connections.
- **Emergency Spike Testing**: Simulating sudden, massive traffic surges (e.g., natural disaster scenario) to validate cold-start handling and database connection pooling.

### Performance Benchmarks
| Metric | Target | Failure Threshold |
| :--- | :--- | :--- |
| **API Response Time (p95)** | < 300ms | > 800ms |
| **Socket.IO Event Broadcast Latency** | < 150ms | > 500ms |
| **Gemini AI Triage Response** | < 2.5s | > 5s |
| **Database Query Execution (Indexed)** | < 20ms | > 100ms |
