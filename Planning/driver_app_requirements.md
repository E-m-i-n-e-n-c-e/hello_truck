**Driver App Requirement Document**

---

**1. Driver Login & Onboarding**

**1.1 Overview**

This section outlines the functional requirements for the Driver App login, verification, and onboarding process.

---

**1.2 Functional Requirements**

**1.2.1 Login Flow**

- **App Launch**:

- Splash screen displays with the app logo.

- SMS access to auto capture OTP

- The system checks for existing login status.

- **Phone Number Entry & OTP Verification**:

- Driver enters their mobile number.

- OTP is sent via SMS.

- OTP is verified to continue.

- **Permissions Prompt (Post-Login)**:

- **Location Access** (Mandatory) – For tracking and trip navigation.

- **Notification Access** (Mandatory) – To notify driver about new rides.

- **Manual Verification Step**:

- After OTP verification, new drivers are shown an onboarding form for document collection and admin verification.

---

**1.2.2 Driver Registration & Verification**

- **Driver Personal Details**:

- Photo Capture

- Full Name

- Email (Optional)

- Alternate Phone Number (Optional)

- Referral Code (Optional)

- Bank Account details

- **Camera & Storage** Permission – For document uploads (license, RC book, etc.).

- **Vehicle & Identity Documents**:

- Upload Driver's License (Image)

- License expiry date

- Upload Vehicle RC Book (Image)

- FC (Image)

- Insurance (Image)

- Insurance expiry date

- Aadhar/ID Proof (Image)

- PAN

- EB Bill

- **Vehicle description**

- Vehicle type – 3 wheeler or 4 wheeler

- Vehicle body length (7 or 8 Feet)

- Vehicle body type (open or closed)

- Fuel type – ( Diesel, petrol, ev , cng)

- **Address Details** (with map option):

- Address Line 1, Street

- Landmark (Optional)

- Pincode, City, District, State

- Owner details – Give a check box to select '**Same as Driver**'

- Name

- Aadhar

- Contact Number

- **Admin Verification Process**:

- Submitted details and documents go to admin panel for review.

- Only after approval, driver account is activated.

- Until then, status shown as "Pending Verification".

---

**2. Driver App Navigation & Pages**

**If the driving license or Insurance is about to expire show an alert at the top of the app whenever they login which should be closable. We should alert them at 45th day, 30th day and for last 10 days we should show it throughout.**

**2.1 Bottom Navigation Tabs**

The main interface has 4 tabs at the bottom:

- **Dashboard**

- **Rides**

- **Payments**

- **Menu**

---

**2.2 Dashboard Tab**

- **If driver open app for the first time every day we should show the pop up 'Are you ready to take rides'. It should show only one time at a day**

- **If the amount to be paid by the driver is more than 1500 then we shouldn't enable the below toggle switch. We should show alert to pay the amount**

- **Toggle switch to show if the driver is ready to take orders. It should look like a banner. Can't be turned of while in Ride.**

- Shows summary of current day's rides:

- Total Rides Completed Today

- Earnings for the Day

- Last Ride Details (Time, Destination)

- Placeholder space for future widgets:

- Performance rating

- Admin messages

- Earnings trends

---

Notification for Booking:

You received a order.

Upon clicking app will be opened with a popup that shows pickup, drop, Product details, Amount. (We can have a subscription to view details)

Driver can approve or reject within 1 min else it should be auto rejected.

**2.3 Rides Tab**

- **Active Rides Section**:

 List of current or ongoing bookings.

- Each tile includes:

- Booking ID

- Pickup and Drop Point

- Ride Amount

- Start time

- Option to upload image Upon loading

- Option to upload image after reaching unloading point

- Start Ride and End Ride buttons

- Call option to customer

- **Ride History Section**:

- List of completed rides.

- Each entry shows:

- Booking ID

- Date & Time

- Pickup-Drop Summary

- Earnings from that ride

- View Details (for full ride info)

- Ratings

---

**2.4 Payments Tab**

- **Payment**:

- Displays rides for which payment is pending or to be paid by driver.

- Shows expected payout date.

- **Payment History**:

- Chronological list of past payments received.

- Filters for: Last 7 Days, Monthly, Custom Date Range

- Each entry shows:

- Date

- Number of Rides

- Total Amount Credited

- UPI Reference / Transaction ID

---

**2.5 Menu Tab**

**Show similar banner like customer app**

- **My Profile**

- Driver profile picture

- Name

- Phone number – OTP verification if edited

- License

- Aadhar

- Permanent Address

- Edit Profile

- Logout

- Delete Account

- Vehicle data

- Vehicle Number

- Vehicle name and model

- Vehicle Image

- RC

- Insurance

- Owner Info

- Edit

- **Language Switch**: Tamil / English

- **Support Section**:

- Help & Support

- Terms & Conditions

- Logout

Notes:

**Validation & Edge Handling**

- If driver tries to go offline during active ride → show dialog.

- If booking expired (after 60s) → auto-dismiss popup.

- If API fails during toggle → revert switch & show retry.

- Show "No Pending Payments" message with empty state graphics.

- Gracefully handle API failures

- Disable filters while loading.

- Lock profile fields while verification is pending

- Show upload status (success/failure/loading) on document update

- **If device date and time is modified or changed the app should not be accessible For both apps**