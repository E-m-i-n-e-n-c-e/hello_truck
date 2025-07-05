# Hello Truck

A modern logistics platform with a Flutter mobile frontend and a NestJS backend.

---

## Prerequisites

- **Node.js** (v20 or above)
- **npm**
- **Flutter** (latest stable version)
- **Docker** (optional, for containerized server)
- **PostgreSQL** (if running server locally)
- **Fly.io CLI** (for deployment)

---

## 1. Running the Server Locally

### a. Clone the Repository

```bash
# Clone the repo
https://github.com/yourusername/hello_truck.git
cd hello_truck
```

### b. Install Dependencies

```bash
cd hello_truck_server
npm install
```

### c. Set Up Environment Variables

Create a `.env` file in `hello_truck_server`:

```
DATABASE_URL=postgresql://<user>:<password>@localhost:5432/<db>
JWT_SECRET=your_jwt_secret
```

### d. Generate prisma client

```bash
npx prisma generate
```

### e. Start the Server

```bash
npm run start:dev
```

The server will run on `http://localhost:3000` by default.

---

## 2. Running the Flutter App

### a. Install Flutter Dependencies

```bash
cd ../hello_truck_app
flutter pub get
```

### b. Run the App

```bash
flutter run
```

---

 

## 3. License

MIT



