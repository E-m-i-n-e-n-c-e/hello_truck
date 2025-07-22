# Customer App – Backend API Specification

This document outlines the backend API endpoints required to support the functionality of the Customer App. Each endpoint includes the method, URL, description, request parameters, and response structure.

# **1. Authentication**

## **POST /auth/customer/send-otp**

Sends OTP to the customer’s phone number for login or registration.

### **Request Parameters**

· phone: string – customer's phone number

### **Response Example**

{"status": "OTP sent"}

## **POST /auth/customer/verify-otp**

Verifies the OTP entered by the customer.

### **Request Parameters**

· phone: string

· otp: string

### **Response Example**

{"token": "jwt_token", "isNewCustomer": true/false}

# **2. Customer Profile**

## **GET /customer/profile**

Fetches the customer profile details.

### **Request Parameters**

· Authorization: Bearer token

### **Response Example**

{"firstName": "John", "lastName": "Doe", "email": "john@example.com"}

## **PUT /customer/profile**

Updates customer name or email.

### **Request Parameters**

· firstName: string

· lastName: string

· email: string

### **Response Example**

{"status": "updated"}

## **POST /customer/gst**

Adds a GST entry for commercial bookings.

### **Request Parameters**

· gstNumber: string

### **Response Example**

{"status": "GST added"}

# **3. Saved Addresses**

## **GET /customer/addresses**

Fetches all saved addresses for the customer.

### **Request Parameters**

· Authorization: Bearer token

### **Response Example**

[{"id": 1, "label": "Home", "address": "21 MG Road"}]

## **POST /customer/addresses**

Saves a new address.

### **Request Parameters**

· label: string

· houseNo: string

· street: string

· city: string

### **Response Example**

{"status": "Address saved"}

## **PUT /customer/addresses/:id**

Updates an existing address.

### **Request Parameters**

· label: string

· houseNo: string

### **Response Example**

{"status": "Address updated"}

## **DELETE /customer/addresses/:id**

Deletes an address from the customer's profile.

### **Response Example**

{"status": "Address deleted"}

# **4. Booking Management**

## **POST /booking**

Creates a new booking.

### **Request Parameters**

· pickup: object

· drop: object

· package: object

### **Response Example**

{"bookingId": "123456", "status": "created"}

## **GET /booking/estimate**

Returns cost estimate and vehicle suggestion.

### **Request Parameters**

· pickup: object

· drop: object

· package: object

### **Response Example**

{"estimatedCost": 350, "suggestedVehicle": "Mini Truck"}

## **GET /booking/active**

Returns list of ongoing bookings.

### **Request Parameters**

· Authorization: Bearer token

### **Response Example**

[{"bookingId": "123456", "status": "pending"}]

## **GET /booking/history**

Fetches list of completed/cancelled bookings.

### **Request Parameters**

· Authorization: Bearer token

### **Response Example**

[{"bookingId": "123", "status": "completed"}]

## **PUT /booking/:id**

Allows modifying a booking (if allowed).

### **Request Parameters**

· drop: object (optional)

· package: object (optional)

### **Response Example**

{"status": "Booking updated"}

## **DELETE /booking/:id**

Cancels a pending booking.

### **Response Example**

{"status": "Booking cancelled"}

# **5. Ride Lifecycle**

## **POST /ride/confirm-pickup-otp**

Confirms pickup using OTP at the origin location.

### **Request Parameters**

· bookingId: string

· otp: string

### **Response Example**

{"status": "Pickup confirmed"}

## **POST /ride/start**

Marks the ride as started after loading photo upload.

### **Request Parameters**

· bookingId: string

· loadingPhoto: file

### **Response Example**

{"status": "Ride started"}

## **POST /ride/confirm-drop-otp**

Confirms delivery OTP entered by receiver.

### **Request Parameters**

· bookingId: string

· otp: string

### **Response Example**

{"status": "Drop confirmed"}

## **POST /ride/complete**

Ends the ride after unloading confirmation.

### **Request Parameters**

· bookingId: string

· unloadPhoto: file

### **Response Example**

{"status": "Ride completed"}