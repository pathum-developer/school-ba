# API Contracts

[<- Backend Architecture](README.md)

## Contract Style

Prefer stable JSON contracts that preserve the frontend's id-and-relationship model. The frontend currently treats `src/data/school.ts` as the future API shape.

IDs such as `car-manual`, `rajagiriya`, and `light` are public contract values. Do not replace them with database-only numeric identifiers in API responses unless the original stable ids are still present.

## Public School Profile

```http
GET /api/school/profile
```

Response body:

```json
{
  "name": "Elven Driving School",
  "shortName": "Elven",
  "hotline": "077 123 4567",
  "hotlineHref": "tel:+94771234567",
  "whatsappHref": "https://wa.me/94771234567",
  "email": "hello@elvendriving.lk",
  "established": 1950
}
```

This endpoint mirrors the frontend's current `school` object and is read-only public catalogue/profile data.
## Public School Catalogue

```http
GET /api/school/catalog
```

Response body returns the frontend's language-independent catalogue structure:

```json
{
  "licenceClasses": ["light", "motorcycle", "threewheeler", "heavy"],
  "stats": [{ "id": "years", "value": "75" }],
  "courses": [{ "id": "car-manual", "licenceClass": "light", "dmtClasses": ["B"], "lessons": 20, "weeks": 14, "priceLkr": 48000, "transmission": "manual", "popular": true }],
  "packages": [{ "id": "complete", "priceLkr": 48000, "lessons": 20, "popular": true }],
  "journey": [{ "id": "medical" }],
  "branches": [{ "id": "rajagiriya", "kind": "branch", "phone": "077 480 1120", "teaches": ["light", "motorcycle", "threewheeler", "heavy"], "mapsQuery": "Cotta Road, Rajagiriya, Sri Lanka" }],
  "resources": [{ "id": "r1", "kind": "tutorial" }],
  "testimonials": [{ "id": "t1", "name": "Nimali Perera", "initials": "NP", "branchId": "rajagiriya", "rating": 5 }],
  "faqs": [{ "id": "f1" }]
}
```

This endpoint intentionally returns structural data only. User-visible copy remains in the frontend locale catalogues until API-served localization is designed.
## Public Booking Submission

Initial endpoint candidate:

```http
POST /api/bookings/trial
Content-Type: application/json
```

Request body:

```json
{
  "courseId": "car-manual",
  "branchId": "rajagiriya",
  "preferredStartDate": "2026-09-01",
  "name": "Nimali Perera",
  "phone": "0771234567",
  "language": "en"
}
```

`language` is optional but useful for staff callback context. Supported values should match the frontend languages: `en`, `si`, `ta`.

Successful response candidate:

```json
{
  "id": "booking_...",
  "status": "pending_callback",
  "courseId": "car-manual",
  "branchId": "rajagiriya",
  "preferredStartDate": "2026-09-01",
  "callbackDueAt": "2026-09-01T10:30:00+05:30"
}
```

## Validation Rules

The server must enforce rules even when the frontend already does:

- `courseId` must exist.
- `branchId` must exist.
- The selected branch must teach the selected course's licence class.
- `preferredStartDate` must be between today and one year ahead, using the backend's configured business timezone.
- `name` and `phone` are required.
- Phone format should be validated enough to prevent unusable submissions, without rejecting reasonable Sri Lankan phone entry formats too aggressively.

## Error Shape

Use a consistent validation response, for example:

```json
{
  "code": "VALIDATION_FAILED",
  "message": "The booking request is invalid.",
  "fields": {
    "branchId": "Branch does not teach the selected course."
  }
}
```

Keep user-facing translation in the frontend. Backend messages are developer/debug oriented unless the API contract later decides otherwise.

## Catalogue Data

The frontend currently has these structural datasets in `src/data/school.ts`:

- `school`
- `licenceClasses`
- `stats`
- `courses`
- `packages`
- `journey`
- `branches`
- `resources`
- `testimonials`
- `faqs`

When moved behind the API, return language-independent record fields plus localized copy for the requested locale. Preserve relationships by id.


