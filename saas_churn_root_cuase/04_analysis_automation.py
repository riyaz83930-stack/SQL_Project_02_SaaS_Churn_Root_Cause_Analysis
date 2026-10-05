import os
import pandas as pd
from sqlalchemy import create_engine


# ============================================================
# SaaS CHURN ROOT-CAUSE ANALYSIS
# Python Automation
# ============================================================

DB_USER = "root"
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = "localhost"
DB_NAME = "project_02_saas_churn"

engine = create_engine(
    f"mysql+mysqlconnector://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}"
)

OUTPUT_DIR = "outputs"
os.makedirs(OUTPUT_DIR, exist_ok=True)


# ============================================================
# PHASE 2 — REFERENTIAL INTEGRITY
# ============================================================

phase2_queries = {

    "orphan_subscriptions": """
        SELECT s.subscription_id, s.user_id
        FROM subscriptions s
        LEFT JOIN users u
            ON s.user_id = u.user_id
        WHERE u.user_id IS NULL;
    """,

    "orphan_usage_logs": """
        SELECT ul.usage_id, ul.user_id
        FROM usage_logs ul
        LEFT JOIN users u
            ON ul.user_id = u.user_id
        WHERE u.user_id IS NULL;
    """,

    "orphan_support_tickets": """
        SELECT st.ticket_id, st.user_id
        FROM support_tickets st
        LEFT JOIN users u
            ON st.user_id = u.user_id
        WHERE u.user_id IS NULL;
    """,

    "orphan_payments": """
        SELECT ph.payment_id, ph.user_id
        FROM payment_history ph
        LEFT JOIN users u
            ON ph.user_id = u.user_id
        WHERE u.user_id IS NULL;
    """,

    "active_users_zero_usage": """
        SELECT
            u.user_id,
            TRIM(u.name) AS name
        FROM users u
        LEFT JOIN usage_logs ul
            ON u.user_id = ul.user_id
        WHERE LOWER(TRIM(u.status)) = 'active'
        GROUP BY u.user_id, u.name
        HAVING COUNT(ul.usage_id) = 0;
    """
}


# ============================================================
# PHASE 3 — DATE LOGIC
# ============================================================

phase3_queries = {

    "usage_outside_subscription": """
        SELECT
            ul.usage_id,
            ul.user_id,
            ul.usage_date
        FROM usage_logs ul
        WHERE NOT EXISTS (
            SELECT 1
            FROM subscriptions s
            WHERE s.user_id = ul.user_id
              AND ul.usage_date >= s.start_date
              AND (
                    s.end_date IS NULL
                    OR ul.usage_date <= s.end_date
              )
        );
    """,

    "payment_before_signup": """
        SELECT
            ph.payment_id,
            ph.user_id,
            ph.payment_date
        FROM payment_history ph
        JOIN users u
            ON ph.user_id = u.user_id
        WHERE ph.payment_date < u.signup_date;
    """
}


# ============================================================
# PHASE 4A — USAGE CHANGE
#
# Churned:
#   45 days before individual churn date
#
# Active:
#   45 days before fixed reference date
#   2026-09-15
# ============================================================

usage_query = """

WITH daily_usage AS (

    SELECT
        user_id,
        usage_date,
        SUM(session_duration_minutes) AS daily_usage_minutes
    FROM usage_logs
    GROUP BY
        user_id,
        usage_date
),

churn_dates AS (

    SELECT
        user_id,
        MAX(end_date) AS churn_date
    FROM subscriptions
    WHERE end_date IS NOT NULL
    GROUP BY user_id
),

user_reference AS (

    SELECT
        u.user_id,
        LOWER(TRIM(u.status)) AS status,

        CASE
            WHEN LOWER(TRIM(u.status)) = 'churned'
                THEN cd.churn_date
            WHEN LOWER(TRIM(u.status)) = 'active'
                THEN DATE('2026-09-15')
        END AS reference_date

    FROM users u
    LEFT JOIN churn_dates cd
        ON u.user_id = cd.user_id
),

comparison AS (

    SELECT
        ur.user_id,
        ur.status,
        ur.reference_date,

        AVG(du.daily_usage_minutes) AS lifetime_avg_usage,

        AVG(
            CASE
                WHEN du.usage_date BETWEEN
                     DATE_SUB(ur.reference_date, INTERVAL 45 DAY)
                     AND ur.reference_date
                THEN du.daily_usage_minutes
            END
        ) AS last_45_day_avg_usage

    FROM user_reference ur

    LEFT JOIN daily_usage du
        ON ur.user_id = du.user_id

    WHERE ur.status IN ('churned', 'active')

    GROUP BY
        ur.user_id,
        ur.status,
        ur.reference_date
)

SELECT
    user_id,
    status,
    reference_date,

    ROUND(lifetime_avg_usage, 2)
        AS lifetime_avg_usage,

    ROUND(last_45_day_avg_usage, 2)
        AS last_45_day_avg_usage,

    ROUND(
        (
            last_45_day_avg_usage - lifetime_avg_usage
        )
        / NULLIF(lifetime_avg_usage, 0) * 100,
        2
    ) AS pct_change

FROM comparison;

"""


usage_df = pd.read_sql(
    usage_query,
    engine
)


# ============================================================
# USAGE DROP BUCKETS
# ============================================================

usage_df["pattern"] = usage_df["pct_change"].apply(
    lambda x:
        "No Data"
        if pd.isna(x)
        else "Usage Drop"
        if x < 0
        else "Usage Increase"
        if x > 0
        else "No Change"
)


def drop_bucket(x):

    if pd.isna(x) or x >= 0:
        return None

    drop = abs(x)

    if drop <= 10:
        return "0-10% drop"
    elif drop <= 20:
        return "10-20% drop"
    elif drop <= 30:
        return "20-30% drop"
    elif drop <= 40:
        return "30-40% drop"
    elif drop <= 50:
        return "40-50% drop"
    else:
        return "Severe (>50%) drop"


usage_df["drop_bucket"] = usage_df["pct_change"].apply(
    drop_bucket
)


usage_df.to_csv(
    f"{OUTPUT_DIR}/phase4_usage_analysis.csv",
    index=False
)


# ============================================================
# PHASE 4B — FAILED PAYMENT
#
# Overall failed-payment experience
# NOT restricted to 30-day window
#
# User-level comparison
# ============================================================

failed_payment_query = """

SELECT
    u.user_id,
    LOWER(TRIM(u.status)) AS status,

    COUNT(
        CASE
            WHEN LOWER(TRIM(ph.status)) = 'failed'
            THEN 1
        END
    ) AS failed_payment_count,

    CASE
        WHEN COUNT(
            CASE
                WHEN LOWER(TRIM(ph.status)) = 'failed'
                THEN 1
            END
        ) > 0
        THEN 1
        ELSE 0
    END AS has_failed_payment

FROM users u

LEFT JOIN payment_history ph
    ON u.user_id = ph.user_id

WHERE LOWER(TRIM(u.status)) IN ('active', 'churned')

GROUP BY
    u.user_id,
    LOWER(TRIM(u.status));

"""


failed_payment_df = pd.read_sql(
    failed_payment_query,
    engine
)

failed_payment_df.to_csv(
    f"{OUTPUT_DIR}/phase4_failed_payment_analysis.csv",
    index=False
)


# ============================================================
# PHASE 4C — UNRESOLVED HIGH-PRIORITY TICKET
#
# Overall support experience
# NOT restricted to 30-day window
#
# User-level comparison
# ============================================================

ticket_query = """

SELECT
    u.user_id,
    LOWER(TRIM(u.status)) AS status,

    COUNT(
        CASE
            WHEN LOWER(TRIM(st.priority)) = 'high'
             AND LOWER(TRIM(st.status)) NOT IN
                 ('resolved', 'closed')
            THEN 1
        END
    ) AS unresolved_high_priority_ticket_count,

    CASE
        WHEN COUNT(
            CASE
                WHEN LOWER(TRIM(st.priority)) = 'high'
                 AND LOWER(TRIM(st.status)) NOT IN
                     ('resolved', 'closed')
                THEN 1
            END
        ) > 0
        THEN 1
        ELSE 0
    END AS has_unresolved_high_priority_ticket

FROM users u

LEFT JOIN support_tickets st
    ON u.user_id = st.user_id

WHERE LOWER(TRIM(u.status)) IN ('active', 'churned')

GROUP BY
    u.user_id,
    LOWER(TRIM(u.status));

"""


ticket_df = pd.read_sql(
    ticket_query,
    engine
)

ticket_df.to_csv(
    f"{OUTPUT_DIR}/phase4_support_ticket_analysis.csv",
    index=False
)


# ============================================================
# PHASE 4D — MASTER USER-LEVEL SIGNAL TABLE
# ============================================================

master_df = (
    usage_df
    .merge(
        failed_payment_df[
            [
                "user_id",
                "has_failed_payment",
                "failed_payment_count"
            ]
        ],
        on="user_id",
        how="left"
    )
    .merge(
        ticket_df[
            [
                "user_id",
                "has_unresolved_high_priority_ticket",
                "unresolved_high_priority_ticket_count"
            ]
        ],
        on="user_id",
        how="left"
    )
)


master_df.to_csv(
    f"{OUTPUT_DIR}/master_user_signal_analysis.csv",
    index=False
)


# ============================================================
# PHASE 4E — SIGNAL SUMMARY
# ============================================================

signal_summary = []

for status, group in master_df.groupby("status"):

    total_users = group["user_id"].nunique()

    signal_summary.append({
        "status": status,
        "total_users": total_users,

        "usage_drop_users": (
            group["pct_change"] < 0
        ).sum(),

        "usage_drop_pct": round(
            (group["pct_change"] < 0).sum()
            / total_users * 100,
            2
        ),

        "failed_payment_users": (
            group["has_failed_payment"] == 1
        ).sum(),

        "failed_payment_pct": round(
            (group["has_failed_payment"] == 1).sum()
            / total_users * 100,
            2
        ),

        "unresolved_high_priority_users": (
            group["has_unresolved_high_priority_ticket"] == 1
        ).sum(),

        "unresolved_high_priority_pct": round(
            (group["has_unresolved_high_priority_ticket"] == 1).sum()
            / total_users * 100,
            2
        )
    })


signal_summary_df = pd.DataFrame(signal_summary)

signal_summary_df.to_csv(
    f"{OUTPUT_DIR}/signal_summary.csv",
    index=False
)


# ============================================================
# PHASE 4F — CHURN VS ACTIVE DIFFERENCE
# ============================================================

summary_wide = (
    signal_summary_df
    .set_index("status")
)


if "churned" in summary_wide.index and "active" in summary_wide.index:

    comparison = pd.DataFrame({

        "signal": [
            "Usage Drop",
            "Failed Payment",
            "Unresolved High-Priority Ticket"
        ],

        "churned_pct": [
            summary_wide.loc[
                "churned",
                "usage_drop_pct"
            ],

            summary_wide.loc[
                "churned",
                "failed_payment_pct"
            ],

            summary_wide.loc[
                "churned",
                "unresolved_high_priority_pct"
            ]
        ],

        "active_pct": [
            summary_wide.loc[
                "active",
                "usage_drop_pct"
            ],

            summary_wide.loc[
                "active",
                "failed_payment_pct"
            ],

            summary_wide.loc[
                "active",
                "unresolved_high_priority_pct"
            ]
        ]
    })

    comparison["gap_percentage_points"] = (
        comparison["churned_pct"]
        - comparison["active_pct"]
    )

    comparison["lift"] = (
        comparison["churned_pct"]
        / comparison["active_pct"].replace(0, pd.NA)
    )

    comparison["lift"] = comparison["lift"].round(2)

    comparison.to_csv(
        f"{OUTPUT_DIR}/churn_signal_comparison.csv",
        index=False
    )


# ============================================================
# PHASE 4G — USAGE DROP MAGNITUDE COMPARISON
# ============================================================

drop_comparison = (
    usage_df[
        usage_df["drop_bucket"].notna()
    ]
    .groupby(
        ["status", "drop_bucket"]
    )
    .size()
    .reset_index(
        name="user_count"
    )
)

drop_comparison.to_csv(
    f"{OUTPUT_DIR}/usage_drop_magnitude_comparison.csv",
    index=False
)


# ============================================================
# FINISH
# ============================================================

print("\n==========================================")
print("SaaS Churn Root-Cause Automation Complete")
print("==========================================")

print("\nGenerated files:")

for file in sorted(os.listdir(OUTPUT_DIR)):
    print(f" - {file}")




