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

## Blocking Before Authenticated Features

The administration requirements define the security policy. These implementation and
operational choices remain open and must be settled before login or protected APIs ship:

9. What verified contact and login identifier does each account type use: email, mobile number, or both?
10. Are browser sessions implemented with server-backed secure cookies or access/refresh tokens, and what are their idle, absolute, and rotation lifetimes?
11. Which MFA methods are approved for staff, and what counts as recent reauthentication for a control-plane action?
12. Which out-of-band channels and identity checks are approved for staff invitation, credential recovery, MFA recovery, verified-contact changes, and student portal invitations?
13. Where are principal authorization versions, role-policy revisions, session revocations, and replay protection stored so every application instance observes changes immediately?
14. What retention and access policy applies to authentication events, invitation history, ended assignments, and the append-only audit log?
