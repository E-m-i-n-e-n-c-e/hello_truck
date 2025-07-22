
**Customer App Requirement Document**

**1. Customer Login & Registration - Requirement Document**

**1.1 Overview**

This chapter outlines the functional requirements for the **Customer** app login module.

---

**1.2. Functional Requirements**

**1.2.1 Login Flow**

1. **User Opens the App**

- Display the splash screen with the app logo.

- SMS access to auto capture OTP.

- Automatically check if the user is already logged in.

2. **Phone Number Entry & OTP Verification**

- Users enter their **mobile number** in the login screen.

- The system sends a **one-time password (OTP)** via SMS for verification. Enable auto capture OTP from SMS

- User enters the OTP, and upon successful validation, they are logged in. After user enter OTP it should auto verify instantly.

3. **Permissions Request**

- After login, the app prompts the user for the following permissions:

  - **Location Access (Mandatory)** – To fetch pickup/delivery addresses.

  - **Notification Access (Optional but Recommended)** – To send booking updates.

4. **New User Registration (If First-Time Login)**

- If the phone number is not linked to an existing user, proceed to registration.

- The user is taken to the **"Personal Information"** page.

---

**1.2.2 Customer Registration (For New Users)**

1. **Personal Details Collection:**

- **Phone Number should be prefilled and disabled.**

- **First Name** (Required)

- **Last Name** (Required)

- **Email ID** (Required)

- **GST Details** (Optional) – If the user is a business. (May be multiple entries)

- **Saved Address** (Optional) – Users can enter frequently used addresses for convenience.

- **Referral code**

2. **Validation & Verification:**

- The phone number is already verified in the previous step.

- All required fields must be filled before proceeding.

3. **User Confirmation & Profile Creation**

- After successful registration, a **customer profile is created** in the system.

- The user is redirected to the **home screen**, where they can start booking vehicles.

---

**1.2.3. UI/UX Considerations For login page**

- **Auto-Fill Support:** Fetch phone numbers automatically where possible (e.g., on Android).

- **Fast OTP Verification:** Auto-read OTP (if permission granted) to minimize manual entry.

- **User Guidance:** Display hints or tooltips to help users fill in required details correctly

**Reference bottom navigation :**

![](file:///C:\Users\AKHILR~1\AppData\Local\Temp\ksohtml20156\wps1.jpg)

**Three tabs – Bookings ( left) , Home (center), Menu(right)**

**2. Booking Vehicle Page - Requirement Document**

**2.1 Overview**

This document outlines the functional requirements for the **Booking Vehicle Page** in the customer app. The booking process consists of four key steps:

1. **Pickup & Drop-off Point Selection**

2. **Package Details Entry**

3. **Estimate & Disclaimers**

4. **Review & Order Confirmation**

---

**2.2. Functional Requirements**

**2.2.1 Step 1: Pickup & Drop-off Point Selection**

1. **Users can select addresses in three ways:**

- **From Saved Addresses** (if available in the user's profile).

- **Check for ways to import location from whatsapp or other location links**

- **By Selecting on the Map** (Google Maps API or OpenStreetMap).

1. **After selecting the map we should get house num, street, landmark, Phone number.**

2. **Validations & Features:**

- Show confirmation pop up on location before proceeding to next step

- If manual entry is used, validate that the address follows standard **India address format** (House Number, Street Name, Area, Landmark).

- Autofill suggestions via **Google Places API**.

- GPS-based auto-detection of the current location (if permission is granted).

---

**2.2.2 Step 2: Package Details Entry**

**There are two radio buttons,**

- Personal Use

- Commercial use - GST bill mandatory

 **1) Product Type Selection**

- The user selects the product category via **two checkboxes**:
✅ **Agricultural Products**
✅ **Non-Agricultural Products**

   **2) Agricultural Products**

- If selected, the user must enter:

- Product name

- **Approximate Weight** (in KG or quintal). Unit should be a dropdown

**3) Non-Agricultural Products**

- The user must provide the following:

- ✅ **Product Weight** (in KG).

  - Average Weight of shipment

  - Weight of each bundle

- From the below two users should provide atleast one

- ✅ **Product Dimensions for each item** (Length, Width, Height in CM).

  - Text box for l, h , w along with drop down for unit. (In or CM)

  - Number of products text box should also be there

- ✅ **Others:**

  - Upload **Package Image** ��

  - Provide **Description** of the package ��

- **For Commercial use give option to upload GST Bill image** (Mandatory)

- **For both Personal/Commercial use give option to upload necessary Transportation documents (Optional) (Should support Multi document upload)**

---

**2.2.3 Step 3: Estimate & Disclaimers Page**

- Once package details are entered, the user presses **Proceed**, and the app navigates to the **Estimate Page**.

- The estimate page displays:

- **Estimated Cost**

- **Distance to be Traveled**

- **Vehicle Type Suggestion**

**Disclaimers Section**

- Loading Distance Limit – the distance between the loading point and the vehicle should not exceed 50 feet. (Conditions may apply for distance more than 50)

- **Additional Charges** may apply in case of:

- Extended waiting time. ( Starts when loading point otp verification is done)

- Change in destination address after booking.

- Change in package details.

The user must acknowledge the disclaimers before proceeding.

---

**2.2.4 Step 4: Review & Order Confirmation**

- The user is shown a **summary of all entered details**, including:

- Pickup & Drop-off Address.

- Product Type & Specifications.

- Estimated Price & Disclaimers.

- Selected Vehicle Type.

- ✅ If everything is correct, the user presses **"Confirm Booking"**, and the request is sent to the backend.

---

**2.3 UI/UX Considerations**

- **Autocomplete Address Entry**: Reduce typing effort by integrating Google Places API.

- **Image Upload Support**: For users selecting "Other" in Non-Agri Products.

**3. My Bookings**

**3.1. Overview**

The My **Bookings** page allows users to track their ongoing bookings and view past orders. It has two main sections:

1. **Active Orders** – Lists all ongoing bookings.

2. **Order History** – Displays past completed orders.

---

**3.2. Functional Requirements**

**3.2.1 Orders Page Layout**

- The page consists of **two tabs**:
1. **Active Orders**
2. **Order History**

**3.2.1.1 Active Orders**

- Each order is displayed in a **tile format** with the following details:

- **Order ID**

- **Edit Button** (Can modify order only after driver reaching loading point. Cancellation can be done free of cost only within 2 mins of booking confirmation. Post that we will charge them for the distance travelled).

- **Clicking the Tile Opens Full Order Details**.

**3.2.1.2 Order History**

- Displays last 10 bookings in a tile format:

- Order ID

- Status (Completed, Cancelled)

- Order date

- View Details Button

- Ratings and review button

**3.2.3 Order Details Page**

When a user clicks on an order tile, a **full-screen order details page** appears, showing:

1. **Order Information:**

- **Order ID**

- **Delivery Partner Name/ Profile Image**

- **Vehicle Number**

- **Need help? Option**

2. **Live Tracking Section:**

- **Map with Driver's Live Location**

- **Call Button** (To communicate with the driver).

- **Edit & Close Tile Buttons** at the top.

---

**3.2.4. Order Lifecycle & Process Flow**

**3.2.4.1 Driver Arrival & OTP Verification**

- When the driver reaches the pickup location, the system sends an **OTP to the user**.

- The driver must **enter the OTP in the app** to confirm arrival.

- Upon OTP confirmation, the **waiting timer starts** (10 mins free).

- **If waiting exceeds 10 mins, additional charges apply.**

**3.2.4.2 Loading Confirmation**

- Once loading is completed, the driver must:

- **Upload a photo** of the loaded goods. (optional)

- Press the **"Start Ride"** button to begin transit.

**3.2.4.3 Arrival at Unloading Point**

- Before unloading, the driver must:

- **Upload a photo** of the goods before unloading (Optional).

- The system sends an **OTP to the receiver's mobile**.

- The receiver **enters the OTP** to confirm arrival.

- **Unloading timer starts** (10 mins free).

**3.2.4.4 Unloading Confirmation & Ride Completion**

- After unloading, ride ends.

---

**3.3 UI/UX Considerations**

- **Clear Tabs & Filtering Options** for easier navigation.

- **Real-time Order Updates** with tracking info.

- **Easy-to-Use OTP Verification** for order security.

- **Visual Proof (Photo Uploads)** to ensure goods are delivered safely.

**4.Menu Page**

**1. Overview**

The **Profile Page** allows users to manage their personal details, update preferences, and access key settings like saved addresses, language preferences, and support options.

---

**2. Functional Requirements**

**2.1 Menu Page Layout**

**At the top show profile image and name in a banner.**

![](file:///C:\Users\AKHILR~1\AppData\Local\Temp\ksohtml20156\wps2.jpg)

The profile page consists of the following sections:

1. **My Profile:**

- Profile image

- Email id – (if it's not verified show 'verify now' in red)

- **Edit Personal information**

1. **Edit Name** ✏️.

2. **Update Phone Number**  (Requires OTP verification).

3. **Edit GST Details** (Optional). (Pop up)

- Logout

- Delete account

2. **Add GST Details Button:**

- Provides a separate explicit option to **add GST details** for business users. (Use same pop up in profile)

3. **Saved Addresses Section:**

- Users can **save frequently used addresses** for quick booking.

- Options to **Add, Edit, and Delete addresses**.

4. **Payments and refunds**

- Two top tabs with date and status filters

1. Payments – Booking id, payment amount, date, Vehicle, payment status

2. Refunds - Booking id, payment amount, date, Vehicle, Refund reason, refund status

5. **Language Selection:**

- Users can **change the app language** from a list of supported languages. (use localization across the app – No hardcoded text)

- English, Tamil, Hindi

6. **Help & Support:**

- Access to **FAQs** and **Customer Support Chat/Call Option**.

7. **Terms & Conditions:**

- Link to **app policies and legal terms**.

Show app version number at the bottom