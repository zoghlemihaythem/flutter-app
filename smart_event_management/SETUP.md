# 🛠 Project Setup Guide

Follow these steps to get your Smart Event Management System up and running.

---

## 1. Supabase Initialization

### Create a Database
1. Go to [Supabase](https://supabase.com/) and create a new project.
2. Once the project is ready, navigate to the **SQL Editor**.

### Database Schema
Run the following SQL to set up the basic tables (Profiles, Events, Tickets):

```sql
-- Create User Profiles
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  full_name text,
  role text default 'participant' check (role in ('admin', 'organizer', 'participant')),
  created_at timestamp with time zone default timezone('utc'::text, now())
);

-- Trigger for profile creation
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, role)
  values (new.id, new.email, new.raw_user_meta_data->>'full_name', 'participant');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

---

## 2. Flutter Project Configuration

### Add Environment Variables
The project uses your Supabase credentials. Ensure you have them configured in your initialization logic (usually in `lib/main.dart` or a config file).

```dart
// Example initialization (lib/main.dart)
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

### Install Dependencies
Run the following command in the root of the `smart_event_management` directory:
```bash
flutter pub get
```

---

## 3. Running the Application

### Debug Mode
```bash
flutter run
```

### Release Build (Android)
```bash
flutter build apk --release
```

---

## 🛠 Troubleshooting

- **Check-in fails**: Ensure the Organizer has the correct permissions for the `attendance` table.
- **QR Code not showing**: Ensure the `qr_flutter` package is correctly installed.
- **Auth Errors**: Verify that your email templates are configured in Supabase Auth settings.

---

[**⬅️ Back to README**](README.md)
