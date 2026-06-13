# SmartAid Engineering Implementation Plan

## 1. Implementation Strategy
The SmartAid platform is a life-critical emergency response system. Our implementation strategy prioritizes **reliability, speed of delivery, and verifiable quality** using an iterative Agile framework tailored for a high-intensity hackathon sprint, transitioning seamlessly into production hardening.

### Development Methodology
- **Sprint-Based Agile**: 4-hour micro-sprints during the hackathon, transitioning to 2-week sprints post-hackathon.
- **Trunk-Based Development**: Short-lived feature branches merged frequently into `develop` via Pull Requests.
- **Test-Driven Development (TDD) for Critical Paths**: Core routing and dispatch logic must have failing tests written before implementation.

### Team Structure
- **Frontend Squad**: Focuses on Flutter Citizen/Driver/Hospital apps.
- **Backend & AI Squad**: Focuses on FastAPI, MongoDB, Socket.IO, and Gemini AI.
- **DevOps & QA Lead**: Manages Google Cloud, CI/CD, and End-to-End testing integration.

### Engineering Principles
- **No Single Point of Failure**: Assume network drops; build offline queues.
- **API First**: Define OpenAPI/Swagger contracts before writing frontend code.
- **Shift-Left Security**: Never commit API keys; utilize Secret Manager from Day 1.

---

## 2. Project Phases & Workstreams
The development is orchestrated across 10 distinct phases.

### Phase 0: Repository Foundation
- **Objectives**: Establish the monorepo structure, CI/CD pipelines, and cloud environments.
- **Deliverables**: GitHub Actions, Linter setups, Terraform scripts for GCP.
- **Dependencies**: GCP Billing Account, GitHub Admin Access.
- **Success Criteria**: A merged PR triggers an automated build and linting check successfully.

### Phase 1: Flutter Foundation
- **Objectives**: Setup the base Flutter project, state management (Riverpod/Bloc), and routing.
- **Deliverables**: Blank functioning apps for Citizen, Driver, and Hospital.
- **Dependencies**: Phase 0.
- **Success Criteria**: Apps compile and launch on iOS and Android simulators with base routing intact.

### Phase 2: Authentication
- **Objectives**: Secure the application using Firebase Authentication and JWT middleware.
- **Deliverables**: Login/Signup screens, Firebase integration, FastAPI auth dependency injection.
- **Dependencies**: Phase 1.
- **Success Criteria**: Users can register, log in, and access a protected `/me` backend endpoint.

### Phase 3: Emergency SOS
- **Objectives**: Core functionality to dispatch an emergency request with GPS coordinates.
- **Deliverables**: SOS UI Button, Location permissions, Incident creation API.
- **Dependencies**: Phase 2.
- **Success Criteria**: Clicking SOS creates a new incident in MongoDB with accurate geospatial data.

### Phase 4: Driver Operations
- **Objectives**: Enable ambulance drivers to receive and accept incoming SOS requests.
- **Deliverables**: Driver Dashboard, Accept/Decline APIs, Dispatch assignment logic.
- **Dependencies**: Phase 3.
- **Success Criteria**: An incident changes state from "Pending" to "Accepted" with a linked Driver ID.

### Phase 5: Hospital Coordination
- **Objectives**: Hospital dashboard to view incoming patients and manage bed capacity.
- **Deliverables**: Web-responsive dashboard, Hospital API endpoints.
- **Dependencies**: Phase 4.
- **Success Criteria**: Hospitals receive an alert when a driver assigned to their facility accepts an SOS.

### Phase 6: Real-Time Tracking
- **Objectives**: Live location streaming from the ambulance to the citizen and hospital.
- **Deliverables**: Socket.IO server, Flutter WebSocket client, Google Maps Polylines.
- **Dependencies**: Phase 4.
- **Success Criteria**: Citizen map smoothly updates driver icon position < 500ms after driver moves.

### Phase 7: AI Services
- **Objectives**: Integrate Gemini AI for triage chat and automated symptom extraction.
- **Deliverables**: Chat UI, Gemini API integration, JSON prompt engineering.
- **Dependencies**: Phase 3.
- **Success Criteria**: AI chat successfully outputs a structured JSON triage report saved to the incident record.

### Phase 8: Testing
- **Objectives**: Validate system integrity under load and edge cases.
- **Deliverables**: Unit test suites, Integration tests, Locust load testing scripts.
- **Dependencies**: Phases 1-7.
- **Success Criteria**: > 85% Code Coverage and p95 latency < 500ms on load tests.

### Phase 9: Deployment
- **Objectives**: Containerize and deploy the application to production environments.
- **Deliverables**: Dockerfiles, Cloud Run services, API Gateway, App Store deployments.
- **Dependencies**: Phase 8.
- **Success Criteria**: System is accessible via public domains and apps are in TestFlight/Google Play Console.

**Suggested GitHub Issues**: #1 Setup Monorepo, #2 Setup Firebase Auth
**Suggested Branch Names**: `chore/repo-setup`, `feature/auth-foundation`
**Suggested Commit Messages**: `chore: initialize monorepo and CI pipelines`

---

## 3. Frontend Workstreams
The frontend engineering is broken down into specific parallel workstreams.

### Flutter Setup & Theme System
- **Tasks**: Initialize Flutter project, configure `pubspec.yaml`, implement global Material 3 theme.
- **Issues**: #10 Init Flutter, #11 Define Theme Tokens.
- **Branches**: `feature/ui-foundation`
- **Deliverables**: Scaffolded app with functioning light/dark mode.
- **Acceptance Criteria**: App builds without warnings; theme toggles correctly.

### Routing
- **Tasks**: Implement `go_router`, define protected routes, and splash screen logic.
- **Issues**: #12 Implement Navigation.
- **Branches**: `feature/routing`
- **Deliverables**: Deep-linking enabled routing system.
- **Acceptance Criteria**: Unauthorized users are redirected to `/login`.

### Authentication UI
- **Tasks**: Build Login, Registration, and OTP screens. Integrate Firebase SDK.
- **Issues**: #13 Build Login UI, #14 Firebase Auth Link.
- **Branches**: `feature/auth-ui`
- **Deliverables**: Functioning auth flow generating a valid Firebase ID token.
- **Acceptance Criteria**: User state persists across app restarts.

### Citizen UI
- **Tasks**: Build main SOS dashboard, permissions request modal, and active incident view.
- **Issues**: #15 SOS Button UI, #16 Incident Status Screen.
- **Branches**: `feature/citizen-ui`
- **Deliverables**: Citizen home screen capable of triggering the SOS event.
- **Acceptance Criteria**: Location permissions are cleanly handled if denied.

### Driver UI
- **Tasks**: Build active incoming requests feed, swipe-to-accept UI, and duty toggle.
- **Issues**: #17 Driver Request Feed, #18 Duty Status Toggle.
- **Branches**: `feature/driver-ui`
- **Deliverables**: Driver portal capable of receiving and accepting dispatches.
- **Acceptance Criteria**: Driver can toggle "Online" and receive simulated push notifications.

### Hospital UI
- **Tasks**: Build responsive web dashboard for incoming ETA and triage data.
- **Issues**: #19 Hospital Web Dashboard.
- **Branches**: `feature/hospital-ui`
- **Deliverables**: Tablet-optimized overview of inbound ambulances.
- **Acceptance Criteria**: UI dynamically updates when new triage data is saved.

### Tracking & Maps UI
- **Tasks**: Integrate `google_maps_flutter`, render custom markers, and draw polylines.
- **Issues**: #20 Map Integration, #21 Live Tracking Render.
- **Branches**: `feature/maps-ui`
- **Deliverables**: Interactive map showing citizen and driver locations.
- **Acceptance Criteria**: Driver marker moves smoothly based on coordinate updates.

### Notification UI
- **Tasks**: Configure Firebase Cloud Messaging (FCM) handlers and local push notifications.
- **Issues**: #22 FCM Setup.
- **Branches**: `feature/notifications`
- **Deliverables**: Foreground and background notification handlers.
- **Acceptance Criteria**: Tapping a notification routes the user to the correct incident screen.

**Suggested Commit Messages**: `feat(ui): implement swipe-to-accept for driver requests`

---

## 4. Backend & AI Workstreams

### Database Setup
- **Tasks**: Provision MongoDB Atlas, define Motor (async Python driver) connection pool, create base ODM models.
- **Issues**: #30 MongoDB Provisioning, #31 Define ODM Models.
- **Branches**: `chore/db-setup`
- **Deliverables**: Connectable database with `users`, `incidents`, and `hospitals` collections.
- **Acceptance Criteria**: Backend successfully reads/writes to MongoDB locally and via connection string.

### FastAPI Setup
- **Tasks**: Initialize FastAPI app, configure CORS, setup structured JSON logging, and error handlers.
- **Issues**: #32 FastAPI Boilerplate.
- **Branches**: `chore/api-setup`
- **Deliverables**: Running ASGI server with auto-generated OpenAPI docs.
- **Acceptance Criteria**: `/docs` route loads Swagger UI successfully.

### Authentication APIs
- **Tasks**: Implement Firebase JWT verification middleware, sync user profile to MongoDB.
- **Issues**: #33 Auth Middleware.
- **Branches**: `feature/api-auth`
- **Deliverables**: `@requires_auth` decorator for route protection.
- **Acceptance Criteria**: Reject requests with missing or invalid Bearer tokens with 401 Unauthorized.

### Emergency APIs
- **Tasks**: `POST /sos` endpoint to create an incident with geolocation payload.
- **Issues**: #34 SOS Endpoint.
- **Branches**: `feature/api-sos`
- **Deliverables**: Incident creation logic with initial state set to `SEARCHING`.
- **Acceptance Criteria**: Payload requires valid latitude and longitude floats.

### Dispatch APIs
- **Tasks**: Geospatial query to find nearest active drivers, calculate Google Maps ETA, emit push notification.
- **Issues**: #35 Dispatch Logic, #36 Maps Routing API.
- **Branches**: `feature/api-dispatch`
- **Deliverables**: Algorithm to match SOS to the closest available ambulance.
- **Acceptance Criteria**: Successfully filters out offline drivers and returns nearest driver within a 10km radius.

### Hospital APIs
- **Tasks**: Endpoints for updating hospital bed capacity and retrieving incoming incidents.
- **Issues**: #37 Hospital Capacity Endpoints.
- **Branches**: `feature/api-hospital`
- **Deliverables**: CRUD operations for Hospital entity.
- **Acceptance Criteria**: Only users with `role: hospital` can access capacity modification endpoints.

### Tracking APIs
- **Tasks**: Set up `python-socketio` ASGI app, implement `update_location` event handler, broadcast to room.
- **Issues**: #38 Socket.IO Server.
- **Branches**: `feature/api-tracking`
- **Deliverables**: WebSocket server capable of broadcasting coordinates.
- **Acceptance Criteria**: Client successfully connects to `ws://` and receives location payloads.

### Notification APIs
- **Tasks**: Implement Firebase Admin SDK to trigger Cloud Messaging payloads.
- **Issues**: #39 Push Notification Service.
- **Branches**: `feature/api-notifications`
- **Deliverables**: Service layer to send custom alerts (e.g., "Ambulance Arriving").
- **Acceptance Criteria**: Backend logs successful FCM message ID delivery.

### Gemini Services & Accident Detection
- **Tasks**: Integrate `google-generativeai` SDK. Build strict system prompt for triage extraction. Build endpoint to process accelerometer data for crash signatures.
- **Issues**: #40 Gemini Triage Agent, #41 Crash Signature Engine.
- **Branches**: `feature/ai-triage`
- **Deliverables**: AI parsing function that returns guaranteed JSON structure.
- **Acceptance Criteria**: Given a panic phrase ("My dad collapsed and isn't breathing"), AI returns `{"severity": "CRITICAL", "symptoms": ["unconscious", "apnea"]}`.

**Suggested Commit Messages**: `feat(api): implement geospatial querying for nearest ambulance`

---

## 5. Testing, Deployment, and Integration Milestones
To maintain rapid velocity without compromising stability, strict milestones act as validation gates before code progresses to the next environment.

### Readiness Gates (Pre-Merge)
- Code compiles without warnings on Flutter and passes all `mypy` strict type-checking on FastAPI.
- Unit tests pass with > 85% coverage.
- SonarQube reports 0 critical security vulnerabilities.

### Quality Gates (Post-Merge to `develop`)
- Automated integration tests verify that the Flutter application can successfully communicate with a transient backend database.
- Database fixtures properly load and tear down without polluting the state.

### Release Gates (Deployment to Staging/Prod)
- **Go/No-Go Criteria**: End-to-End core loop (SOS Creation -> Driver Accept -> Hospital Notification) completes successfully on physical devices connected to the Cloud Run backend.
- Locust load tests simulate 500 concurrent WebSocket connections with < 1% dropped packet rate.

### Integration Milestones
1. **Frontend-Backend Contract Verification**: FastAPI Swagger matches the Flutter generated API clients.
2. **Third-Party API Validation**: Firebase, Google Maps, and Gemini tokens are confirmed working via Secret Manager injections.

### Deployment & Monitoring Milestones
- Cloud Run CI/CD pipeline correctly builds and deploys on Tag creation.
- Google Cloud Monitoring alerts are configured to page engineers if API 5xx errors exceed 2%.

**Suggested GitHub Issues**: #50 Setup Load Tests, #51 Configure Cloud Logging.
**Suggested Branch Names**: `chore/testing-gates`, `deploy/staging-env`
**Suggested Commit Messages**: `test(e2e): configure playwright flow for driver acceptance`
