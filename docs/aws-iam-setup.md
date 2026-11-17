# AWS IAM Setup Guide — AWS Guardian

AWS Guardian connects to your AWS account securely using **IAM Role Delegation** and **AWS Security Token Service (STS) AssumeRole**. This guide explains how to set up the necessary IAM role.

---

## Step 1: Obtain your External ID
1. Open the **AWS Guardian** mobile app.
2. Go to **Accounts > + Connect AWS Account**.
3. Copy your unique **External ID** (e.g., `guardian-a1b2c3d4e5f6`).

---

## Step 2: Create the IAM Role in AWS Console
1. Log in to the [AWS Management Console](https://console.aws.amazon.com/iamv2/home#/roles).
2. Click **Roles** in the left sidebar, then click **Create role**.
3. Under **Trusted entity type**, choose **Custom trust policy**.
4. Paste the following Trust Policy JSON, replacing `YOUR_EXTERNAL_ID` with the ID from Step 1:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::662371887384:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "YOUR_EXTERNAL_ID"
        }
      }
    }
  ]
}
```

> **Note:** `662371887384` is AWS Guardian's Host Account ID. Trusting this account allows the Guardian backend to safely assume the role via AWS STS without requiring long-term credentials.

---

## Step 3: Attach Least-Privilege Permissions
1. Under **Add permissions**, click **Create policy** or attach AWS managed `SecurityAudit` and `AWSViewOnlyAccess`.
2. For least privilege, attach the following minimal policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GuardianReadOnlyScan",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeVolumes",
        "ec2:DescribeAddresses",
        "ec2:DescribeNatGateways",
        "ec2:DescribeTags",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters",
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "s3:GetBucketTagging",
        "s3:GetBucketPolicyStatus",
        "s3:GetPublicAccessBlock",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## Step 4: Name and Create the Role
1. Set the role name to `AWSGuardianRole`.
2. Click **Create role**.
3. Copy the **Role ARN** (e.g., `arn:aws:iam::123456789012:role/AWSGuardianRole`).

---

## Step 5: Verify Connection in AWS Guardian
1. Paste the **Role ARN** and **12-digit Account ID** into the AWS Guardian mobile app.
2. Tap **Verify Connection**.
3. AWS Guardian will perform an STS AssumeRole handshake and verify caller identity.
