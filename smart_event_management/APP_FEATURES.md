# Smart Event Management System - Features Overview

## 🚀 Core Features

### 1. Authentication & Security
- **Supabase Authentication**: Secure email and password login/registration.
- **Role-Based Access Control (RBAC)**: Distinct experiences for Admins, Organizers, and Participants.
- **Automated Profile Creation**: Database triggers handle user profile creation upon signup.
- **Row-Level Security (RLS)**: Data privacy enforced at the database level (users can only see their own private data).

### 2. Dashboard
- **Dynamic Home Screen**: Adapts content based on user role.
- **Real-time Stats**:
  - **Participants**: See registered events, ticket counts, and upcoming schedules.
  - **Organizers**: Track event performance, attendee counts, and revenue.
- **Modern UI**: Polished interface with glassmorphism effects, vivid gradients, and smooth animations.

### 3. Event Management (Organizers & Admins)
- **Create & Manage Events**: Full CRUD capabilities for events.
- **Event Publishing**: Draft and publish workflows.
- **Ticket Configuration**: Set prices and available quantities for different ticket tiers (VIP, Standard).

### 4. Ticketing System
- **Event Discovery**: Browse upcoming events with search functionality.
- **Ticket Purchase**:
  - Simulated payment gateway integration.
  - Automatic registration upon ticket purchase.
  - Generates unique QR Codes for each ticket.
- **My Tickets**: dedicated wallet view for purchased tickets.

### 5. Registration & Attendance
- **Auto-Registration**: Seamless registration flow linked to ticket purchases.
- **Attendance Tracking**:
  - Check-in functionality (for organizers).
  - Track registration status (Registered vs Checked-In).

## 🛠 Technical Stack

- **Frontend**: Flutter (Mobile & Web support).
- **Backend & Database**: Supabase (PostgreSQL).
- **State Management**: Provider.
- **Architecture**: Feature-first folder structure.

## 🎨 Design System
- Custom **AppTheme** with dark/light mode foundations.
- Responsive layouts ensuring compatibility across devices.
- High-fidelity components: Custom text fields, gradient buttons, and cards.
