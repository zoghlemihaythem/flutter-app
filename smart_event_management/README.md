# 🎫 Smart Event Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.10.1-blue.svg)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-green.svg)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A powerful, full-stack Event Management System built with **Flutter** and **Supabase**. This application provides a seamless experience for **Admins**, **Organizers**, and **Participants** to create, manage, and attend events.

---

## ✨ Features at a Glance

- 🔐 **Secure Role-Based Authentication**: Distinct experiences for different user types.
- 📅 **Dynamic Event Management**: Full CRUD operations for organizers and admins.
- 🎟️ **Ticketing System**: Integrated ticket purchasing with QR code generation.
- 📊 **Real-time Analytics**: Dashboard with live stats for event performance.
- 🎨 **Modern UI/UX**: Glassmorphism, smooth animations, and responsive design.

[**Explore full features list ➡️**](FEATURES.md) | [**Technical deep dive ➡️**](TECHNICAL_DETAILS.md)

---

## 🛠 Tech Stack

- **Frontend**: Flutter
- **Backend**: Supabase (PostgreSQL, Auth, RLS)
- **State Management**: Provider
- **Utilities**: `qr_flutter`, `intl`, `uuid`, `cupertino_icons`

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.10.1)
- A Supabase Project

### Quick Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd smart_event_management
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**:
   Create a `.env` file or update your initialization code with your Supabase URL and Anon Key.

4. **Run the app**:
   ```bash
   flutter run
   ```

For detailed setup instructions, including Supabase database triggers and RLS policies, see [**SETUP.md**](SETUP.md).

---

## 📸 Screenshots

| Dashboard | Events List | Ticket Wallet |
|:---:|:---:|:---:|
| (Coming Soon) | (Coming Soon) | (Coming Soon) |

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
