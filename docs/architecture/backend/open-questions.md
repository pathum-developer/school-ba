# Open Questions

[<- Backend Architecture](README.md)

Backend-specific open questions. Product-level questions remain in `../business-requirements/open-questions.md` and should be treated as the source of truth.

## Blocking For Booking Submission

1. Where should submitted bookings be delivered first: database callback queue, email, WhatsApp notification, CRM, or a combination?
2. Should the two-hour callback deadline apply outside branch opening hours?
3. What retention period applies to unconverted booking leads and phone numbers?
4. Who may view incoming bookings: all staff, branch staff for the selected branch, or a central coordinator?

## Significant

5. Should the booking API validate age or prior licence eligibility, or leave those checks to the callback?
6. Are packages valid for every course, or does the backend need course/package compatibility rules?
7. Should catalogue content be API-served in the first backend slice, or should only booking submission move first?
8. What timezone should all booking deadlines and date validation use? Candidate: `Asia/Colombo`.
