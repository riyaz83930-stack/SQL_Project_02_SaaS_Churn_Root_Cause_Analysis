# SaaS Churn Root-Cause Analysis

## Project Overview

Customer churn is an important business problem for subscription-based SaaS businesses.

Instead of focusing only on predicting which customers may churn, this project investigates a more practical question:

> What customer behaviors and experiences are commonly observed before churn, and which patterns appear more strongly associated with churned customers?

The analysis uses SQL for data investigation and Python for automation and visualization.

---

## Business Problem

The business has customers who eventually cancel their subscriptions, but the reason behind churn is not immediately clear.

Potential explanations include:

- Declining product usage
- Payment failures
- Poor customer support experience
- Unresolved high-priority issues
- Subscription-related behavior

The goal of this project is to investigate these potential signals using historical customer data.

---

## Objectives

The project aims to:

1. Audit the underlying customer data.
2. Identify data-quality and relationship issues.
3. Validate subscription and payment dates.
4. Analyse customer usage behaviour before churn.
5. Compare usage patterns between churned and active customers.
6. Investigate payment and support-related churn signals.
7. Automate the analysis using Python.
8. Produce business-oriented findings and recommendations.

---

## Dataset

The dataset represents a subscription-based SaaS / fitness application.

| Table | Records | Description |
|---|---:|---|
| users | 400 | Customer profile and account status |
| subscriptions | 459 | Subscription history |
| usage_logs | 17,047 | Customer product usage activity |
| support_tickets | 600 | Customer support interactions |
| payment_history | 3,000 | Customer payment activity |

---

## Key Tables

### users

Contains customer-level information such as:

- user_id
- name
- email
- signup_date
- plan_type
- status

### subscriptions

Contains:

- subscription_id
- user_id
- plan_name
- start_date
- end_date
- monthly_amount
- status

### usage_logs

Contains:

- usage_id
- user_id
- usage_date
- feature_used
- session_duration_minutes

This table is particularly important for understanding changes in customer engagement.

### support_tickets

Contains:

- ticket_id
- user_id
- ticket_date
- category
- priority
- status
- resolved_date

### payment_history

Contains:

- payment_id
- user_id
- payment_date
- amount
- status

---

## Analysis Approach

### Phase 1 — Surface Exploration

The initial audit covered:

- Row counts
- NULL values
- Status consistency
- Invalid numeric values
- Distinct categorical values

The purpose was to understand the quality and structure of the data before performing churn analysis.

---

### Phase 2 — Referential Integrity

Relationships between the main tables were validated.

Checks included:

- Orphan subscriptions
- Orphan usage records
- Orphan support tickets
- Orphan payment records
- Active customers with no usage activity

---

### Phase 3 — Date Logic

Date relationships were checked to identify records that could affect downstream analysis.

The analysis included:

- Usage occurring outside valid subscription periods
- Payments occurring before customer signup

---

### Phase 4 — Churn Signal Investigation

Potential churn signals were investigated at the customer level.

The main signals were:

### Usage behaviour

Customer usage during a 45-day observation period was compared with lifetime average usage.

For churned customers, the observation window was anchored to the customer's churn date.

For active customers, a fixed reference date of **15 September 2026** was used to create a comparable 45-day observation period.

Usage changes were further divided into magnitude buckets.

### Payment behaviour

Customer payment history was examined for failed payments.

### Support experience

Support history was examined for unresolved high-priority tickets.

The analysis focuses on customer-level signals rather than simply counting raw transactions.

---

## Python Automation

Python was used to automate the analytical workflow and generate reusable outputs.

Main libraries:

- Pandas
- SQLAlchemy
- Matplotlib

The automation generates:

- Phase-level CSV outputs
- User-level signal analysis
- Churn signal comparison
- Usage decline analysis
- Usage decline magnitude comparison
- Visualization outputs

---

## Visualizations

Two main visualizations were created:

1. **Churned vs Active Signal Comparison**
2. **Usage Decline Magnitude — Churned vs Active**

These visuals are intended to communicate the most important analytical findings without overwhelming the business reader with unnecessary charts.

---

## Project Structure

```text
saas_churn_root_cause/
│
├── data/
│   ├── project_data.sql
│   
│   
│   
│   
│
├── outputs/
│   ├── churn_signal_comparison.csv
│   ├── master_user_signal_analysis.csv
│   ├── signal_summary.csv
│   ├── phase4_usage_analysis.csv
│   ├── phase4_failed_payment_analysis.csv
│   ├── phase4_support_ticket_analysis.csv
│   ├── usage_drop_magnitude_comparison.csv
│   └── ...
│
├── visuals/
│   ├── churn_signal_comparison.png
│   └── usage_drop_magnitude_comparison.png
│
├── 01_surface_exploration_&_referential_integrity.sql
├── 02_date_logic_audit.sql
├── 03_pattern_analysis.sql
├── 04_analysis_automation.py
├── 05_visualization.ipynb
│
├── README.md
└── Report_insights_and_recommendations.md