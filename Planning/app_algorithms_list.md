# Algorithms Required for Customer and Driver Apps

This document outlines the key algorithms and logical modules needed for implementing core functionality in both the Customer and Driver mobile applications.

## **1. Cost Estimation Algorithm**

· Calculate estimated trip cost based on distance (via Maps API), vehicle type, and package type.

· Include base fare, per km rate, waiting time charges, and tax (if applicable).

· For commercial use, add GST if invoice is generated.

· Output: Estimated Fare, Suggested Vehicle.

## **2. OTP Verification Logic**

· Generate 6-digit OTP for login and pickup/delivery confirmations.

· Set OTP expiry timer (e.g., 2 minutes).

· Securely hash/store OTP server-side and validate input OTP.

· Throttle repeated OTP requests.

## **3.** **Booking Lifecycle Management**

· Track status: Created → Accepted → In-Transit → Delivered → Completed.

· Handle transitions via driver actions (OTP confirmations, photo uploads).

· Allow cancellation only before ride start.

## **4.** **Driver Matching Algorithm (future-ready)**

· Find nearest available driver based on location and vehicle type.

· Score drivers by proximity, recent rides, and availability time.

· Assign ride to top-ranked driver or broadcast to nearby drivers.

· Auto-expire request if no response in 60 seconds.

## **5. Live Tracking Logic**

· Poll driver GPS every 10 seconds or use WebSocket for live updates.

· Send location to backend and push to customer app.

· Visualize using Maps API on both sides.

· Pause updates during app minimize (optional).

## **6. Document Expiry Alert Engine**

· For each driver document (License, Insurance), check expiry date.

· Trigger alert at 45, 30, and every login during final 10 days.

· Store document metadata and use scheduled cron jobs or app-side triggers.

## **7. Profile Completion Score (Optional)**

· Calculate profile completion percentage for drivers/customers.

· Assign weights to each field (photo = 10%, documents = 40%, address = 20%, etc.).

· Display visual meter in profile section.

## **8.** **Payment Reconciliation Logic**

· Track completed rides and payment status (pending/paid).

· Group by payout cycle/date for history view.

· Match payment confirmation against UPI reference/transaction ID.

## **9. Ride History Aggregation**

· Group completed rides by date, week, or month.

· Summarize earnings, distance, and average rating (future).

· Support filtering via date ranges.

## **10. Rating & Feedback System**

· Allow customers to rate driver post-delivery.

· Store average rating per driver and expose to admin.

· Optional: show public rating to customer.