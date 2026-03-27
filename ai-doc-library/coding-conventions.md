# Coding Conventions

---

> **This document is language-agnostic.** The principles here apply across all high-level languages and technologies. Where a language, framework, or protocol has a well-established convention, follow it — these guidelines govern our own code and naming choices, not ecosystem standards. If a project has its own specific coding conventions document, that supersedes this one.

---

## Core Philosophy

Code is functional first. It must work correctly, reliably, and efficiently — that is non-negotiable. Readability is a discipline we layer on top of that, and it matters because code that is easy to read is easier to debug, maintain, extend, and hand off — whether to another developer or to an AI agent picking up the work cold.

- **Readable over clever** — if a simpler expression communicates the same thing and does the same job, use it
- **Descriptive over brief** — longer, self-documenting names are preferred over short ones that require context to understand
- **Expanded over compressed** — if breaking a dense expression into two or three named steps makes it clearer without any other cost, do it. The extra lines are not waste — they are clarity
- **Conventional where conventions exist** — don't fight the ecosystem to satisfy a style preference. Follow the standard

---

## Naming Principles

Good naming is one of the most effective things we can do for long-term code quality. A well-named variable or function communicates its purpose without requiring the reader to look elsewhere.

- Names should fully convey intent without requiring the reader to look elsewhere
- Names should be **as long as they need to be** — three to six words in a name is normal and encouraged
- If a name fully describes what it contains or does, it is not too long
- **Never abbreviate** unless the abbreviation is a universally established convention in that language or domain (e.g. `url`, `id`, `html`, `db` in some contexts)

```
// ❌ Too short — requires context to understand
$subs
$usr
$db
$cfg

// ✅ Self-documenting — intent is immediately clear
$active_subscriptions
$current_user
$database_connection
$application_config
```

### Verbosity Has Limits

Descriptive naming is the default. Common sense is the override. If a name starts reading like a sentence, trim it — but trim with care, not habit.

```
// ❌ Gone too far
$list_of_all_currently_active_paid_subscriptions_for_this_billing_cycle

// ✅ Still descriptive, still readable
$active_paid_subscriptions_for_current_cycle
```

### Language Casing Conventions

Every language has its own established casing convention — `snake_case`, `camelCase`, `PascalCase`, `kebab-case`, and so on. Always follow the convention for the language you are working in. Our verbosity principles apply on top of that convention, not instead of it.

In practice this means: use the casing that the language expects, but make the name itself as descriptive as it needs to be. A PHP variable uses `snake_case` — so `$active_subscription_list`, not `$subs`. A JavaScript function uses `camelCase` — so `calculateSubscriptionProration()`, not `calcProration()`. The casing follows the language. The verbosity follows these guidelines.

If you are working in a language or framework not covered here, apply the same principle — find the established convention for that language, follow it, and layer our naming principles on top.

---

## Respect Established Conventions

Where a language, framework, protocol, or tool has a well-established naming or structural convention, follow it — even if a more descriptive alternative seems possible.

Examples of conventions that take precedence:

- `.env` — not `.environment`
- `README.md` — not renamed
- `package.json`, `composer.json` — not renamed
- Framework lifecycle methods (`handle()`, `up()`, `down()`, `boot()`) — keep the standard name
- HTTP verbs, status codes, REST resource naming — follow the standard
- Database naming conventions specific to a platform or ORM — follow them
- Third-party API field names — preserve their terminology when interfacing with them

The rule is simple: **if the ecosystem owns the name, don't rename it. If we own the name, make it descriptive.**

This also applies to database naming. Follow the standard for your platform and ORM, but within that, lean toward descriptive names where you have freedom. Don't rename established platform conventions in the name of verbosity — that creates confusion for anyone familiar with the standard.

---

## Code Expansion Over Compression

When logic has multiple conceptual steps, express them as multiple steps. Do not compress into a single dense expression for the sake of brevity.

Each line should carry one clear unit of meaning. An extra two or three lines is a small price for code that can be read, debugged, and understood at a glance.

```javascript
// ❌ Dense — hard to read, hard to debug
const total = (plan.price * 1.15) + (hasDiscount ? -(plan.price * discountRate) : 0);

// ✅ Expanded — each step is named and inspectable
const basePrice = plan.price;
const platformFee = basePrice * 0.15;
const discountAmount = hasDiscount ? basePrice * discountRate : 0;
const totalAmountDue = basePrice + platformFee - discountAmount;
```

This principle applies broadly — not just to arithmetic. A complex regular expression broken into named steps, a chained transform split across intermediate variables, a ternary condition that requires a second read rewritten as an explicit `if/else` — in all of these cases, if expanding it makes the intent clearer without any functional cost, expand it. These are examples of the pattern, not an exhaustive list.

---

## File and Folder Naming

Follow the naming convention for the language or framework you are working in. Within that convention, apply the same descriptive naming principles — file names should communicate what the file contains or does.

Avoid generic names like `helpers`, `misc`, `utils`, or `common` unless the file genuinely is a collection of miscellaneous utilities with no better grouping available. Where a more specific name is possible, use it.

---

## Third-Party and External Conventions

When interfacing with external libraries, APIs, or services, preserve their terminology in variable names — even if it means a shorter or less descriptive name than we would normally use. This keeps the connection to external documentation clear.

```javascript
// ✅ Preserve the external terminology, add our context around it
const stripeClientSecret = setupIntent.client_secret;

// ❌ Renamed — loses the connection to Stripe's own docs
const paymentSecret = setupIntent.client_secret;
```

---

## Applying These Guidelines

These are **best practice guidelines** — a steer, not a straitjacket. They are not here to box the coding process into a rigid set of rules or to artificially elongate everything. They exist to nudge toward code that is easier to maintain, easier to read, and easier to work with over time.

Apply them with judgment. When making a decision, the useful questions are: does this make the code easier to maintain? Does it aid readability? Does the code do what it is meant to do clearly and correctly?

A few important clarifications:

- **Verbose naming is a lean, not a blanket rule.** While these conventions favour descriptive names, this does not mean every name must be elongated. Where a shorter name is universally understood in context — `id`, `url`, `index`, `i` in a loop — use it. The goal is clarity, not length for its own sake
- **Ecosystem conventions always win.** If a well-established convention exists in the language or framework, follow it — don't override it in the name of these guidelines
- **Complex code is sometimes necessary.** If the problem genuinely requires a complex solution, write it that way — then make sure it is commented well
- **These conventions apply to our own code.** When interfacing with external systems, follow their conventions

## Naming Suggestions and Alternatives

Getting names right matters, and it sometimes takes a few attempts to land on the best one. When the operator asks for alternative names — for a variable, function, class, method, or anything else — always provide **at least four to five options** that genuinely explore different angles: different levels of verbosity, different framings of the same concept, different word choices.

Always follow the options with a **clear recommendation** — which one you would choose and a brief reason why. Don't sit on the fence. The operator may disagree and pick a different one, but a reasoned recommendation is always more useful than a list with no steer.

---

## Quick Reference

| Principle | Default |
|---|---|
| Name length | As long as needed to convey full intent |
| Abbreviations | Never — unless a universal convention in that language or domain |
| Casing format | Follow the convention for the language being used |
| Logic expansion | Multiple clear lines over one dense expression |
| Ternary expressions | Only for simple, obvious conditions |
| Ecosystem conventions | Always follow — they override our preferences |
| Function responsibility | One thing per function |
| File naming | Descriptive, matching the primary class or responsibility |
| Third-party names | Preserve their terminology when interfacing with external systems |