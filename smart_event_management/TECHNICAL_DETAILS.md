# 🛠 Technical Specification - Smart Event Management System

This document provides a deep dive into the technical implementation, architectural patterns, and data flows of the Smart Event Management System.

---

## 🏗 Architectural Overview

The application follows a **Feature-First Architecture**, ensuring high modularity and scalability. Each feature is self-contained with its own models, providers, and presentation logic.

### Directory Structure
```text
lib/
├── core/               # Shared utilities, themes, and global constants
├── features/           
│   ├── auth/           # Identity management and RBAC logic
│   ├── events/         # Event CRUD and lifecycle management
│   ├── registration/   # Attendee registration and booking
│   ├── schedule/       # Session management and scheduling
│   └── tickets/        # QR generation and digital wallet
└── shared/             # Reusable UI components across features
```

---

## 🔐 Authentication & Identity Management

### Role-Based Access Control (RBAC)
User roles are managed via the `profiles` table in Supabase. The application enforces role constraints on the client-side using `AuthProvider` and on the server-side via **PostgreSQL Check Constraints** and **RLS (Row-Level Security)**.

### Database Triggers
When a user signs up via Supabase Auth, a SQL function `handle_new_user()` is automatically executed to insert a corresponding record into the `public.profiles` table:
```sql
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

---

## 🛰 Data Persistence Layer

### Supabase Integration
The app communicates with Supabase via the `supabase_flutter` SDK. Data fetching uses asynchronous Streams and Futures managed by the `Provider` state management package.

### Key Logic: Event Lifecycle
Events are managed via `EventProvider`. The lifecycle includes:
1.  **Draft State**: `is_published: false`. Only visible to the creating Organizer.
2.  **Published State**: `is_published: true`. Visible to all Participants via RLS policies.
3.  **Automatic Status Calculation**: The `Event` model dynamically calculates status (`Upcoming`, `Ongoing`, `Completed`) using getter logic:
    ```dart
    bool get isOngoing {
      final now = DateTime.now();
      return now.isAfter(date) && now.isBefore(endDate);
    }
    ```

---

## 🎫 Ticketing & QR Technology

### QR Code Generation
Tickets are assigned a unique UUID upon purchase. This UUID is encoded into a high-density QR code using the `qr_flutter` package.
- **Payload**: `ticket_id`
- **Verification**: Organizers scan the QR code to verify the ticket against the database and update `attendance_status`.

### State Synchronization
The `TicketProvider` maintains a real-time list of purchased tickets. When an organizer scans a ticket, the `RegistrationProvider` updates the attendance record, which triggers a UI update for both the organizer (live count) and participant (checked-in badge).

---

## 🎨 Design System & UI Engine

### Glassmorphism & Visual Effects
The app uses a custom `AppTheme` that defines modern design tokens:
- **Acrylic Blur**: Implemented using `BackdropFilter` with `ImageFilter.blur`.
- **Gradients**: Linear and Radial gradients are used for primary actions to provide a "premium" feel.
- **Transitions**: Native Flutter `Hero` animations are used for event image transitions between list and detail views.

### Performance Optimizations
- **Lazy Loading**: Event lists use `ListView.builder` for efficient memory usage.
- **Provider Scoping**: State is scoped as closely as possible to the consuming widgets to minimize rebuilds.

---

## 🛠 Tech Stack Details

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **State Management** | Provider | Reactive state and dependency injection |
| **Backend** | Supabase | Auth, Database, Storage, and Real-time |
| **Database** | PostgreSQL | Relational data with JSONB support |
| **Storage** | Supabase buckets | Hosting event banners and profile images |
| **QR Library** | qr_flutter | Ticket generation |
| **Localization** | Intl | Date/Time formatting and currency |

---

[**⬅️ Back to README**](README.md) | [**View Feature List ➡️**](FEATURES.md)
