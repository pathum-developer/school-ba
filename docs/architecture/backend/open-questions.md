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

The administration requirements define the security policy. Password login, JWT access
transport, server-side session records, and hashed refresh-token history are implemented.
The following choices remain before full staff sign-in and protected workflows ship:

9. What verified contact and login identifier does each account type use: email, mobile number, or both?
10. Which MFA methods are approved for staff, and what counts as recent reauthentication for a control-plane action? The password step currently creates a challenge but no factor verifier exists.
11. Which out-of-band channels and identity checks are approved for staff invitation, credential recovery, MFA recovery, verified-contact changes, and student portal invitations?
12. What refresh-token rotation, reuse-detection response, logout behavior, and idle-session renewal policy should be applied? The hash history schema exists, but refresh and logout endpoints do not.
13. How are role-policy revisions incorporated into protected permission checks after the role services are delivered? Account and session authorization/credential versions are already checked on every bearer-token request.
14. What retention and access policy applies to authentication events, invitation history, ended assignments, and the append-only audit log?
