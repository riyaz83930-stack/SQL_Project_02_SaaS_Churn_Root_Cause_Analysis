
---

# 2. `findings_report.md`

```markdown
# SaaS Churn Root-Cause Analysis
## Findings, Insights & Business Recommendations

---

# 1. Executive Summary

This analysis investigated potential reasons behind customer churn in a subscription-based SaaS business.

The investigation focused on three areas:

- Product usage behaviour
- Failed payments
- Unresolved high-priority support issues

The strongest current finding comes from usage behaviour.

A simple usage decline was not unique to churned customers. Active customers also showed moderate declines in usage.

However, larger usage declines were substantially more concentrated among churned customers.

Among customers with measurable usage decline:

- 40%+ decline represented approximately 17.0% of churned users.
- 40%+ decline represented approximately 4.7% of active users.

This indicates that **large usage deterioration may be a meaningful churn-warning signal**, while smaller usage fluctuations appear to be relatively normal.

The analysis does not establish that usage decline directly causes churn.

---

# 2. Data Quality Findings

The initial data audit identified several issues that could affect downstream analysis.

## Customer Data

- 21 customer email values were NULL, representing 5.25% of users.
- Customer status contained formatting and case inconsistencies.

These inconsistencies were handled during analysis using standardization such as trimming whitespace and normalizing case.

---

## Subscription Data

265 subscription records had NULL `end_date` values.

This was not automatically treated as a data-quality error because an active subscription can naturally have no end date.

---

## Support Ticket Data

220 support tickets had NULL `resolved_date`.

This can represent unresolved tickets and therefore requires business interpretation rather than automatic removal.

---

## Numeric Data

Zero-value records were identified in financial fields such as subscription and payment amounts.

These records require validation because zero-value financial transactions may represent invalid or exceptional business states.

---

# 3. Referential Integrity Findings

The analysis checked relationships between:

- Users and subscriptions
- Users and usage logs
- Users and support tickets
- Users and payments

Orphan records were identified across transactional relationships.

These records can affect customer-level analysis if they are included without validation.

Active customers with zero usage activity were also investigated separately because no usage may represent either genuine inactivity or insufficient activity data.

---

# 4. Date Logic Findings

Two important date-related issues were identified.

## Usage Outside Subscription Period

47 usage records were identified outside a valid subscription period.

This is important because usage behaviour should ideally be evaluated only when the customer has an active subscription.

---

## Payments Before Signup

30 payment records occurred before the associated customer's signup date.

These records do not directly explain churn but indicate data-quality or timing inconsistencies that should be investigated.

---

# 5. Usage Behaviour Analysis

The central usage analysis compared:

**Lifetime average daily usage**

against

**Average daily usage during the final 45-day observation window.**

For churned customers, the 45-day period was anchored to their individual churn date.

For active customers, a fixed reference date of **15 September 2026** was used.

The objective was to determine whether usage decline is normal customer behaviour or disproportionately concentrated among churned customers.

---

# 6. Overall Usage Pattern

The analysis showed that usage decline occurs in both groups.

This is an important distinction.

Simply observing:

> "The customer's usage declined before churn."

does not prove that the decline is a churn-specific behaviour.

Active customers also experience periods of lower engagement.

Therefore, a small or moderate decline should not automatically trigger a churn intervention.

---

# 7. Usage Decline Magnitude

The decline was divided into magnitude buckets.

| Usage Decline | Churned Users | Active Users |
|---|---:|---:|
| 0–10% | 19 | 52 |
| 10–20% | 7 | 21 |
| 20–30% | 13 | 19 |
| 30–40% | 5 | 10 |
| 40–50% | 4 | 2 |
| >50% | 5 | 3 |

---

# 8. Key Insight — Severe Usage Decline

The clearest difference appears at larger usage declines.

Among users with measurable decline:

### 40%+ decline

Churned users:

9 / 53 ≈ **17.0%**

Active users:

5 / 107 ≈ **4.7%**

The proportion is therefore substantially higher among churned customers.

---

## >50% Decline

Churned:

5 / 53 ≈ **9.4%**

Active:

3 / 107 ≈ **2.8%**

Again, severe declines are more concentrated among churned users.

---

# 9. Business Interpretation

The data suggests that **usage decline magnitude matters more than simply detecting a decline**.

A customer moving from:

> 100 minutes → 90 minutes

may simply be experiencing normal behavioural variation.

A customer moving from:

> 100 minutes → 50 minutes

represents a very different level of disengagement.

Therefore:

> **Moderate usage decline appears to be normal behaviour for some customers, while severe deterioration appears more strongly associated with churn.**

This makes severe usage decline a promising early-warning signal.

It should still be treated as an association rather than a proven cause.

---

# 10. Payment Behaviour

Failed payments were investigated as a potential churn signal.

The correct business-level metric is the percentage of customers experiencing at least one failed payment rather than the total number of failed payment records.

This prevents customers with multiple failed transactions from disproportionately influencing the analysis.

The final interpretation should therefore focus on:

**Affected customers / Total customers**

rather than:

**Number of failed payment transactions.**

---

# 11. Support Experience

Unresolved high-priority support tickets were investigated as another potential churn signal.

Again, the analysis should be performed at the customer level.

A customer with five unresolved high-priority tickets should count as one affected customer, not five separate customers.

This allows the churned and active populations to be compared fairly.

---

# 12. What the Analysis Does NOT Show

The analysis does not support the statement:

> "Customers churn because their usage decreases."

It also does not support treating every usage decline as a churn warning.

The evidence instead suggests:

> **Large usage deterioration is more strongly associated with churn than ordinary usage fluctuation.**

This is a more useful and defensible business conclusion.

---

# 13. Business Recommendations

## Recommendation 1 — Monitor severe usage deterioration

Do not create a churn alert for every customer whose usage decreases.

Instead, prioritize customers showing substantial usage deterioration.

A 40%+ decline can be used as an initial investigation threshold based on this dataset.

However, this threshold should be validated on a larger historical dataset before becoming a production rule.

---

## Recommendation 2 — Investigate why usage is falling

Usage decline is a warning signal, not necessarily the root cause.

When a customer shows a severe decline, investigate:

- Which features they stopped using
- Whether core features are being abandoned
- Whether their plan changed
- Customer tenure
- Recent support interactions
- Onboarding quality
- Product changes
- Feature adoption

This can help move the analysis from:

**"Usage dropped"**

to:

**"Why did usage drop?"**

---

## Recommendation 3 — Monitor payment friction

Customers experiencing repeated failed payments should be monitored because payment friction can create involuntary churn.

Potential operational actions include:

- Automatic payment retries
- Payment-method reminders
- Payment update prompts
- Failed-payment notifications
- Customer communication before account interruption

The priority of this intervention should depend on the final churned-vs-active comparison.

---

## Recommendation 4 — Escalate unresolved high-priority issues

High-priority support tickets that remain unresolved should have an escalation mechanism.

Recommended workflow:

```text
High-Priority Ticket
        ↓
SLA Monitoring
        ↓
Escalation
        ↓
Customer Follow-up
        ↓
Resolution