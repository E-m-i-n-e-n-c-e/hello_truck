# Customer App – Backend API Specification

This document outlines the backend API endpoints required to support the functionality of the Customer App. Each endpoint includes the method, URL, description, request parameters, and response structure.

# **1. Authentication**

## **POST /auth/customer/send-otp**

Sends OTP to the customer's phone number for login or registration.

### **Request Parameters**

· phoneNumber: string – customer's phone number

### **Response**

{ success: boolean, message: string }

## **POST /auth/customer/verify-otp**

Verifies the OTP entered by the customer and returns authentication tokens.

### **Request Parameters**

· phoneNumber: string
· otp: string
· staleRefreshToken?: string (optional) - Previous refresh token if available

### **Response**

{ accessToken: string, refreshToken: string }

## **POST /auth/customer/logout**

Logs out the customer by invalidating the refresh token.

### **Request Parameters**

· refreshToken: string

### **Response**

{ success: boolean }

## **POST /auth/customer/refresh-token**

Refreshes the access token using a valid refresh token.

### **Request Parameters**

· refreshToken: string

### **Response**

{ accessToken: string, refreshToken: string }

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

{
  "success": true,
  "message": "Profile updated successfully"
}


# **2.1 GST Management**

## **POST /customer/gst**

Adds new GST details for a customer.

### **Request Parameters**

· Authorization: Bearer token
· gstNumber: string - Must follow Indian GST format (e.g. 29ABCDE1234F1Z5)
· businessName: string
· businessAddress: string

### **Response Example**

{
  "success": true,
  "message": "GST details added successfully"
}

## **GET /customer/gst**

Retrieves all active GST details for the authenticated customer.

### **Request Parameters**

· Authorization: Bearer token

### **Response Example**

[
  {
    "id": "uuid",
    "customerId": "customer-uuid",
    "gstNumber": "29ABCDE1234F1Z5",
    "businessName": "My Business Name",
    "businessAddress": "Business Complete Address",
    "isActive": true,
    "createdAt": "2024-03-20T10:00:00Z",
    "updatedAt": "2024-03-20T10:00:00Z"
  }
]

## **GET /customer/gst/:id**

Retrieves specific GST details by ID.

### **Request Parameters**

· Authorization: Bearer token
· id: string - GST details UUID

### **Response Example**

{
  "id": "uuid",
  "customerId": "customer-uuid",
  "gstNumber": "29ABCDE1234F1Z5",
  "businessName": "My Business Name",
  "businessAddress": "Business Complete Address",
  "isActive": true,
  "createdAt": "2024-03-20T10:00:00Z",
  "updatedAt": "2024-03-20T10:00:00Z"
}

## **PUT /customer/gst/:id**

Updates existing GST details.

### **Request Parameters**

· Authorization: Bearer token
· id: string - GST details UUID
· businessName: string
· businessAddress: string

### **Response Example**

{
  "success": true,
  "message": "GST details updated successfully"
}

## **POST /customer/gst/deactivate**

Deactivates (soft deletes) existing GST details.

### **Request Parameters**

· Authorization: Bearer token
· id: string - GST details UUID

### **Response Example**

{
  "success": true,
  "message": "GST details deactivated successfully"
}

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