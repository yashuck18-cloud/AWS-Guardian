# AWS Guardian — Architecture Documentation

## Overview

AWS Guardian is an enterprise-grade cloud resource monitoring, forgotten resource detection, and cost protection platform. It provides mobile-first visibility into AWS accounts through temporary, read-only STS AssumeRole delegations without storing long-lived AWS secrets.

```text
┌─────────────────────────────────────────────────────────────┐
│                 AWS Guardian Flutter Mobile App             │
│   (Material 3 • Riverpod • GoRouter • Dio • FL Chart)       │
└──────────────────────────────┬──────────────────────────────┘
                               │ HTTPS REST API + JWT Bearer
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Django REST Framework API                   │
│   - Multi-Tenant Isolation & Authentication Engine          │
│   - Resource & Scan Orchestration (Async ThreadPool)        │
│   - Dynamic Rule Engine & Deduplication System              │
│   - Notification Dispatcher (Telegram & In-App)            │
│   - Comprehensive Immutable Audit Trail                     │
└──────────────────────────────┬──────────────────────────────┘
                               │
               ┌───────────────┴───────────────┐
               ▼                               ▼
┌─────────────────────────────┐ ┌─────────────────────────────┐
│   PostgreSQL / SQLite DB    │ │      Boto3 AWS Client       │
│  - Multi-Tenant Isolation   │ │  - STS AssumeRole Session   │
│  - Resource Models & Stats  │ │  - Multi-Region Descriptors │
└─────────────────────────────┘ └──────────────┬──────────────┘
                                               │ Temporary STS Credentials
                                               ▼
                               ┌─────────────────────────────┐
                               │     Customer AWS Account    │
                               │  - EC2 / EBS / EIP / RDS    │
                               │  - S3 / NAT / ELB           │
                               └─────────────────────────────┘
```

## Backend Services & Modules

1. **`users`**: Manages custom authentication, JWT token generation, secure password hashing, and user preferences (scan interval, thresholds).
2. **`aws_accounts`**: Stores account metadata, unique External IDs for IAM trust, and handles STS AssumeRole verification with Boto3.
3. **`scanner`**: Orchestrates multi-service and multi-region AWS scanners (EC2, EBS, EIP, NAT, RDS, S3, ELB) with partial failure fault tolerance.
4. **`rules`**: Evaluates active resources against configurable thresholds to detect idle assets (e.g. EC2 running > 24h, detached EBS > 24h, unassociated Elastic IPs).
5. **`alerts`**: Implements smart alert deduplication, keeping a single active alert per condition and automatically resolving cleared conditions.
6. **`notifications`**: Dispatches twice-daily summaries (09:00 / 19:00) and urgent alerts to In-App history and Telegram bots.
7. **`analytics`**: Aggregates fleet breakdown, regional distribution, risk posture, and estimated cost impact.
8. **`audit`**: Immutable logging of all sensitive actions (`AWS_ACCOUNT_CONNECTED`, `SCAN_STARTED`, `RESOURCE_STOPPED`, etc.) with automatic secret sanitization.

## Flutter Mobile Architecture

- **State Management**: Riverpod 2.x with StateNotifierProvider and repository pattern.
- **Routing**: GoRouter with shell navigation (Home, Resources, Alerts, Accounts, More) and deep linking.
- **Theme**: Dark-first Material 3 design tokens (`#080D18` background, `#7C3AED` primary, `#22C55E` success, `#EF4444` critical).
- **Network**: Dio client with authentication interceptors, base URL switcher, and offline handling.
- **Visualization**: FL Chart interactive donut risk charts and trend lines.
