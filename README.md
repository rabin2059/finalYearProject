# 🚌 Merobus - Smart Bus Booking and Route System

Merobus is a full-stack web and mobile platform that helps users seamlessly book buses, find available routes, and pay using Khalti. It's built for both passengers and drivers with a clear and intuitive UI using **Flutter** for frontend and **Node.js + Prisma + MySQL** for backend.

---

## 🌟 Features

### 🚏 Passenger Side
- Search buses by location (OSM-based route mapping)
- See which vehicles pass through your selected route even if the destination isn't their final stop
- Book seat(s) on available buses
- View and track booked trips
- Make secure payments using **Khalti**

### 🚐 Driver/Admin Panel
- Add and manage vehicle details
- Assign routes to vehicles (including encoded polylines)
- View all bookings and their status
- Single route per vehicle validation enforced

---

## 🛠️ Tech Stack

| Layer        | Tech Used                     |
|--------------|-------------------------------|
| Frontend     | Flutter + Riverpod + FlutterMap |
| Backend      | Node.js + Express             |
| ORM          | Prisma                        |
| Database     | MySQL                         |
| Map & Geo    | OpenStreetMap (OSM), Turf.js, Mapbox Polyline |
| Payment      | Khalti Payment Gateway        |
| Authentication | JWT & Custom User Roles (USER, DRIVER, ADMIN) |

---

## 🚀 Getting Started

### 📦 Backend Setup

```bash
cd merobus_backend
npm install
npx prisma generate
npx prisma migrate dev --name init
npm run dev

Create a .env file and configure:
DATABASE_URL=mysql://username:password@localhost:3306/merobus
KHALTI_SECRET_KEY=your_khalti_secret_key

### 📱 Frontend Setup
cd merobus_frontend
flutter pub get
flutter run

### 🔐 Environment Variables
DATABASE_URL=
KHALTI_SECRET_KEY=
KHALTI_PUBLIC_KEY=
JWT_SECRET=
