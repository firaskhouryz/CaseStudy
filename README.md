# CloudSquare (CSQ) Application Intake — Portal + Webhook

This project implements a small “application intake” flow in Salesforce:

- **Portal (Experience Cloud) submission** via LWC
- **External submission** via an Apex REST webhook
- **Single processing pipeline** that validates input, matches Accounts, and creates either:
	- an **Opportunity** when an Account match is found, or
	- a **Lead** when no Account match exists


## What It Does

For both Portal and Webhook submissions:

1. Validate required fields
2. Attempt to match an Account:
	 - first by `Account.FedTaxId__c` (if provided)
	 - else by `Account.Name`
3. If matched: create an Opportunity under that Account
4. If not matched: create a Lead
5. add the channel/source into `SourceType__c` (Lead/Opportunity)

---

## Key Metadata / Data Model

Custom fields used by this solution:

- `Account.FedTaxId__c` (Tax ID used for matching)
- `Lead.FedTaxId__c` (captured when a Lead is created; duplicates allowed)
- `Lead.SourceType__c` (e.g., `Community`, `Webhook`)
- `Opportunity.SourceType__c` (e.g., `Community`, `Webhook`)

---

## Overall Design

### HEADERS

Headers on every function and every class can be found.

### LWC (Portal)

- Component: `force-app/main/default/lwc/cSQ_LWC_Portal`
- Uses an **imperative Apex call** to submit the payload.


### Apex (Shared Processing Pipeline)

Both channels route into the same processing pipeline for consistency:

- `CSQ_APEX_ApplicationFormController.submit(...)` (Portal entry)
- `CSQ_APEX_ApplicationWebhook` (Webhook entry)
	- Strict validation of headers/body + defensive JSON parsing

Both call:

- `CSQ_Service_ApplicationProcessing.process(...)` → `CSQ_Service_ApplicationProcessingCore`

The core handles:

- **Validation**  (`CSQ_Validator_ApplicationSubmission`)
- **Account matching** (`CSQ_Selector_AccountMatch`)
- **Record construction** via factories
	- `CSQ_Factory_Lead`
	- `CSQ_Factory_Opportunity`
- **DML coordination** via a minimal Unit-of-Work abstraction (`CSQ_UOW_Dml`)

### Responses

Responses are designed to be safe to display:

- Portal returns a wrapper outcome with `ok` + `userMessage` + `created.sObjectType`
- Webhook returns an HTTP status + a JSON response body
---

## Webhook Endpoint

- REST resource: `@RestResource(urlMapping='/cloudsquare/external/applications')`
- Method: `POST`
- Content-Type: `application/json`

Example request body:

```json
{
	"organization": { "legalName": "Acme Inc", "taxId": "12-3456789" },
	"applicant": {
		"givenName": "Jane",
		"familyName": "Doe",
		"emailAddress": "jane.doe@example.com",
		"phoneNumber": "+1 415 555 0100"
	},
	"financials": { "annualRevenue": 2500000 }
}
```

---

## Key Tradeoffs

1. **Extra abstraction layers vs speed/simplicity**
	 - I introduced selectors/factories/UOW/service layers for scalability and testability.
	 - For a small take-home, this is way more verbose than strictly necessary and contains more boilerplate/abstractions, but it keeps controllers thin and makes future channels/rules or requirement changes easier to add.

2. **Single processing core for consistency vs channel-specific flexibility**
	 - Portal and Webhook both flow through `CSQ_Service_ApplicationProcessingCore`.
	 - This ensures consistent behavior across UI + API, but if channels need different rule sets, that introduces extra configuration/branching and complexity as i will need to add specific channel rules but on the other hand my changes/updates applies to all channels.
	 - Example: the Portal UI can enforce stricter input (like phone) while the API might allow it to be optional.

3. **Operational reliability vs “pure” sharing enforcement**
	 - Some server-side processing runs `without sharing` to reduce guest-user permission issues/avoiding sharing settings in Experience Cloud.
	 - This improves reliability for public submissions, but it must be paired with correct object/field permissions and being careful with security.

---

## Failure Scenario (Demonstrates Behavior)

### Scenario A — Portal: missing required fields

**Cause**: A user clicks Submit without filling required fields.

**Behavior**:

- The LWC performs client-side validation.
- The form does **not** call Apex.
- The user sees an inline error message: “Please populate all the required fields.”

### Scenario B — Webhook: invalid request / malformed JSON

**Cause**: The caller sends an invalid request, for example:

- wrong `Content-Type` (not JSON)
- missing request body
- malformed JSON

**Behavior**:

- The webhook returns an appropriate HTTP status (e.g., `415` for unsupported media type, `400` for bad request)
- The response body includes an error message describing the failure (without leaking internal apex error msgs or stacktracee or line number etc..)

---

## One Thing Intentionally Not Implemented (Yet)

I used factories to keep record construction isolated and maintainable, but I **did not build a full strategy/rules engine**.

**Why**:

- The current requirements effectively have one core decision (Opportunity vs Lead) and a small number of defaults.
- A rules engine would be premature and ovoer kill and add complexity for this scope.

**When it would be valuable**:

- If requirements evolve into many channel- and context-specific variations (e.g., 10+ different Opportunity “build styles”), a rules engine could apply field overrides/derivations without creating a lot of factories.

---

## Future Improvements

- **Webhook authentication** (Proper authentication / OAuth)
- **Rate limiting to prevent abuse and api spams from malicious actors/hackers**
- **Async processing** for spikes (Queueable, Platform Events) + retry strategy
- **Observability aka advanced monitoring, storing errors in an object,etc..** (structured logging, correlation IDs, monitoring dashboards)

---
