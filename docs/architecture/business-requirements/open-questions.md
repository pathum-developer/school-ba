# Open questions

[← Business requirements](README.md)

Decisions the business needs to make. These are not implementation to-dos — each one
changes *what should be built*, so guessing at them would put the wrong thing in the
codebase.

Ordered by how much damage the wrong answer causes.

## Blocking — before the site takes real traffic

**1. Where does a submitted booking go?**
The form promises a callback within two hours. Nothing receives the booking today
([FR-201](functional-requirements.md#lead-capture), [FR-208](functional-requirements.md#lead-capture)).
Does it become an email, a WhatsApp message to a coordinator, a row in `school-ba`, or a
CRM record? This determines the API contract, and until it is answered the site must not
be advertised as taking bookings.

**2. Are the published claims substantiated?**
94% first-attempt pass rate, 42,000+ drivers, 75 years, and DMT approval are presented as
fact ([published claims](domain-and-rules.md#published-claims)). Who owns each figure,
what is the evidence, and how often is it revalidated? A pass-rate claim attributed to
"last 12 months" ages into a false statement on its own.

**3. Do the FAQ answers reflect actual policy?**
Ten answers state binding terms: the 12-hour reschedule cut-off, three interest-free
instalments, two free refresher lessons after a failed trial, a female-instructor
guarantee, age limits. Each is currently a string in a translation file. Confirm each with
whoever runs the school, because customers will hold the business to them.

**4. Where are the privacy policy, terms, and refunds pages?**
All three footer links point at `#` ([FR-307](functional-requirements.md#contact-and-conversion-routes)).
Collecting phone numbers without a published privacy policy is not a gap to fix later —
see [privacy and data protection](non-functional.md#privacy-and-data-protection).

## Significant — shape what gets built

**5. Should the booking form check eligibility?**
Age and prior-licence rules exist ([BR-19](domain-and-rules.md#regulatory),
[BR-20](domain-and-rules.md#regulatory)) but nothing is collected that could check them, so
a 16-year-old can currently book a lorry trial. Options: leave it to the callback (fine,
if deliberate), add a date of birth, or show the requirement inline once a class is
chosen. Adding a field costs conversion; the business should choose knowingly.

**6. Are courses and packages meant to be linked?**
A visitor picks a *course* when booking but is priced by *package*, and the two are
unrelated in the data ([entities](domain-and-rules.md#entities)). Is a package valid for
any course? The Fast Track features mention a medical certificate and priority test slot
that are class-independent, but "12 practical lessons" against a 28-lesson bus course does
not obviously work.

**7. Who owns prices, and how often do they change?**
If prices move more than once or twice a year, they belong behind the API rather than in a
committed file, and the answer changes the migration priority in
[the API seam](../frontend/state-and-data.md#the-api-seam).

**8. Is the two-hour callback achievable at all hours?**
Wellawatte closes Sundays; Rajagiriya opens 8.00 on Sunday. A Saturday-evening booking
promises a call by a time when nobody is at a branch
([BR-05](domain-and-rules.md#booking)). Either the promise needs qualifying, or the
booking confirmation needs to state the next business window.

**9. What should the learning hub resources open?**
Twelve resources are listed with an "Open" affordance and no destination
([FR-112](functional-requirements.md#discovery-and-content)). Are they public marketing
content, or gated behind enrolment? The copy says "free for every enrolled student", which
implies gating — and therefore authentication, which does not exist here.

## Worth settling soon

**10. Which social profiles are real?**
Facebook, YouTube and Instagram icons link to `#`
([FR-308](functional-requirements.md#contact-and-conversion-routes)). Remove them or point
them somewhere; dead social icons cost credibility on a page whose job is credibility.

**11. Should the theme choice be remembered?**
Language persists across visits, the light/dark choice does not
([FR-407](functional-requirements.md#language-and-presentation)). Probably an oversight
rather than a decision, but fixing it correctly requires a pre-paint script, so it is
worth confirming someone wants it.

**12. Are the five testimonials real, and consented?**
They carry full names, branches and licence classes. Published reviews attributed to named
individuals need those individuals' permission.

**13. Should anything be measured?**
No analytics exist ([success measures](product-scope.md#success-measures)). If the business
wants to know whether the site works, that needs deciding alongside the privacy questions
above rather than after them.
