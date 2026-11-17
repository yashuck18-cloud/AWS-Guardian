# AWS Guardian — Security Architecture & Guidelines

## 1. Zero Permanent Credential Storage
- AWS Guardian **NEVER** asks for, receives, or stores AWS root passwords, IAM user passwords, or permanent AWS access key pairs (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`).
- All AWS interactions use temporary, short-lived session credentials generated on-demand via **AWS STS AssumeRole**.
- Temporary STS credentials are held strictly in server memory during active scanning and are **never** persisted to the database or transmitted to the mobile frontend.

## 2. Multi-Tenant Isolation
- Strict database-level foreign key isolation: Users can only query accounts, resources, scans, alerts, notifications, and audit logs linked to their authenticated `User` record.
- Cross-tenant access is tested and blocked with `404 Not Found` or `403 Forbidden`.

## 3. Least Privilege IAM Permissions
- Read-only permissions for inspection: `DescribeInstances`, `DescribeVolumes`, `DescribeAddresses`, `DescribeNatGateways`, `DescribeDBInstances`, `ListAllMyBuckets`, `DescribeLoadBalancers`.
- No `AdministratorAccess`, no `Action: "*"`.

## 4. Confused Deputy Protection
- External IDs are randomly generated cryptographically unique strings assigned per account connection.
- IAM trust policies enforce `sts:ExternalId` conditions, preventing third-party unauthorized role assumption.

## 5. Destructive Action Safeguards
- **Never Auto-Delete**: AWS Guardian will NEVER automatically delete cloud resources.
- **Explicit Confirmation**: Safe actions like Stop Instance require double confirmation dialogs.
- **Type-to-Confirm Deletion**: Permanently destructive actions require the user to explicitly type the exact Resource ID string into a confirmation prompt.

## 6. Audit Trail & Secret Sanitization
- All sensitive actions (`AWS_ACCOUNT_CONNECTED`, `SCAN_STARTED`, `RESOURCE_STOPPED`, etc.) are recorded in an immutable audit log.
- Audit details pass through automatic secret sanitizers that redact sensitive keys (`password`, `token`, `secret`, `credentials`, `key`).
