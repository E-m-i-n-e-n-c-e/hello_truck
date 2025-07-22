# Driver App – Backend API Specification

This document outlines the backend API endpoints required for the Driver App functionality, including login, profile management, ride handling, and payment tracking.

# **1. Authentication & Onboarding**

## **POST /auth/driver/send-otp**

Sends OTP to the driver’s phone number.

### **Request Parameters**

· phone: string

### **Response Example**

{"status": "OTP sent"}

## **POST /auth/driver/verify-otp**

Verifies OTP and returns session token.

### **Request Parameters**

· phone: string

· otp: string

### **Response Example**

{"token": "jwt_token", "isNewDriver": true/false}

## **POST /driver/onboarding**

Submits driver registration and documents.

### **Request Parameters**

· photo: file

· name: string

· email: string (optional)

· phone_alt: string (optional)

· referralCode: string (optional)

· bankDetails: object

· vehicleDetails: object

· identityDocs: files

· address: object

· ownerDetails: object

### **Response Example**

{"status": "Submitted for verification"}

# **2. Profile Management**

## **GET /driver/profile**

Fetches driver profile info.

### **Request Parameters**

· Authorization: Bearer token

### **Response Example**

{"name": "Ravi", "vehicleNumber": "TN09 AB1234"}

## **PUT /driver/profile**

Updates editable profile info.

### **Request Parameters**

· name: string

· phone: string

### **Response Example**

{"status": "Profile updated"}

## **POST /driver/documents**

Uploads or replaces vehicle and identity documents.

### **Request Parameters**

· documentType: string

· file: file

### **Response Example**

{"status": "Document uploaded"}

# **3. Dashboard & Availability**

## **POST /driver/availability**

Toggles driver availability to receive rides.

### **Request Parameters**

· available: boolean

### **Response Example**

{"status": "updated"}

## **GET /driver/dashboard**

Fetches ride summary for the day.

### **Response Example**

{"ridesToday": 3, "earningsToday": 1200, "lastRide": "Order #123"}

# **4. Booking Notifications & Management**

## **GET /driver/bookings/active**

Lists currently assigned rides.

### **Request Parameters**

· Authorization: Bearer token

### **Response Example**

[{"bookingId": "123", "pickup": "X", "drop": "Y"}]

## **POST /driver/booking/respond**

Responds to a booking offer (accept/reject).

### **Request Parameters**

· bookingId: string

· response: accept/reject

### **Response Example**

{"status": "accepted"}

# **5. Ride Lifecycle**

## **POST /driver/ride/start**

Starts the ride after pickup confirmation.

### **Request Parameters**

· bookingId: string

· otp: string

· loadingPhoto: file

### **Response Example**

{"status": "Ride started"}

## **POST /driver/ride/complete**

Ends the ride and uploads unloading proof.

### **Request Parameters**

· bookingId: string

· unloadingPhoto: file

· otp: string

### **Response Example**

{"status": "Ride completed"}

# **6. Payments**

## **GET /driver/payments/pending**

Fetches list of unpaid rides.

### **Request Parameters**

· Authorization: Bearer token

### **Response Example**

[{"rideId": "789", "amount": 450, "expectedPayout": "2025-07-20"}]

## **GET /driver/payments/history**

Fetches payout history with filters.

### **Request Parameters**

· from: date

· to: date

### **Response Example**

[{"date": "2025-07-18", "amount": 2100, "rides": 5}]