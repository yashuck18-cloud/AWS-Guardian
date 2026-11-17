// User & Authentication
export interface AdminUser {
  id: string;
  email: string;
  name: string;
  avatar_url?: string;
  is_active: boolean;
  is_staff: boolean;
  is_superuser: boolean;
  scan_interval_hours: number;
  ec2_threshold_hours: number;
  ebs_threshold_hours: number;
  theme_preference: 'dark' | 'light' | 'system';
  last_login: string | null;
  created_at: string;
  aws_accounts_count: number;
  resources_count: number;
  active_alerts_count: number;
}

export interface UserStats {
  accounts_count: number;
  resources_count: number;
  active_alerts_count: number;
  resolved_alerts_count: number;
  total_scans_count: number;
  notifications_count: number;
}

export interface UserDetailData {
  id: string;
  email: string;
  name: string;
  avatar_url?: string;
  is_active: boolean;
  is_staff: boolean;
  is_superuser: boolean;
  scan_interval_hours: number;
  ec2_threshold_hours: number;
  ebs_threshold_hours: number;
  theme_preference: string;
  last_login: string | null;
  created_at: string;
  updated_at: string;
  aws_accounts: AdminAWSAccount[];
  notification_settings: {
    morning_summary_enabled: boolean;
    evening_summary_enabled: boolean;
    urgent_alerts_enabled: boolean;
    telegram_enabled: boolean;
    telegram_chat_id: string;
  } | null;
  stats: UserStats;
}

// AWS Account
export type AWSAccountStatus = 'CONNECTED' | 'DISCONNECTED' | 'ERROR' | 'VERIFICATION_FAILED' | 'PENDING';

export interface AdminAWSAccount {
  id: string;
  user: string;
  user_name: string;
  user_email: string;
  name: string;
  account_id: string;
  role_arn: string;
  external_id: string;
  status: AWSAccountStatus;
  enabled_regions: string[];
  last_scan_at: string | null;
  last_verified_at: string | null;
  created_at: string;
  updated_at: string;
  resources_count: number;
  alerts_count: number;
  scans_count: number;
}

// AWS Resource
export type ResourceService = 'EC2' | 'EBS' | 'RDS' | 'S3' | 'ELB' | 'EIP' | 'NAT';
export type RiskLevel = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';

export interface AdminResource {
  id: string;
  account: string;
  account_name: string;
  account_aws_id: string;
  user_id: string;
  user_name: string;
  user_email: string;
  service: ResourceService;
  resource_id: string;
  resource_name: string;
  region: string;
  status: string;
  risk_level: RiskLevel;
  detection_reason: string;
  metadata: Record<string, any>;
  last_seen: string;
  created_at: string;
  active_alerts_count: number;

  estimated_hourly_cost?: number;
  cost_info?: {
    id?: string;
    resource_id?: string;
    service?: string;
    region?: string;
    actual_cost?: string;
    estimated_cost?: string;
    currency?: string;
    pricing_rate?: string;
    pricing_unit?: string;
    cost_source?: string;
    cost_source_display?: string;
    billing_status?: string;
    billing_status_display?: string;
    approx_inr?: number;
    notes?: string;
  };
}


// Alert
export type AlertSeverity = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
export type AlertStatus = 'ACTIVE' | 'ACKNOWLEDGED' | 'RESOLVED';

export interface AdminAlert {
  id: string;
  account: string;
  account_name: string;
  account_aws_id: string;
  user_id: string;
  user_name: string;
  user_email: string;
  resource?: string;
  resource_type?: string;
  resource_identifier?: string;
  resource_name?: string;
  rule_code: string;
  severity: AlertSeverity;
  title: string;
  description: string;
  estimated_cost_impact: string | number;
  status: AlertStatus;
  resolved_at: string | null;
  first_detected_at: string;
  last_detected_at: string;
}

// Scan
export type ScanStatus = 'PENDING' | 'RUNNING' | 'COMPLETED' | 'FAILED' | 'PARTIAL';

export interface AdminScan {
  id: string;
  account: string;
  account_name: string;
  account_aws_id: string;
  user_id: string;
  user_name: string;
  user_email: string;
  status: ScanStatus;
  resources_found: number;
  alerts_generated: number;
  error_message: string | null;
  started_at: string;
  completed_at: string | null;
}

// Notification
export type NotificationChannel = 'TELEGRAM' | 'EMAIL' | 'PUSH' | 'IN_APP';
export type NotificationStatus = 'SENT' | 'FAILED' | 'PENDING';

export interface AdminNotification {
  id: string;
  user: string;
  user_name: string;
  user_email: string;
  title: string;
  message: string;
  channel: NotificationChannel;
  status: NotificationStatus;
  error_details: string;
  created_at: string;
}

// Audit Log
export interface AdminAuditLog {
  id: string;
  user: string | null;
  user_name: string;
  user_email: string;
  action: string;
  ip_address: string;
  user_agent: string;
  details: Record<string, any>;
  status: 'SUCCESS' | 'FAILURE';
  timestamp: string;
}

// Dashboard
export interface DashboardStats {
  total_users: number;
  active_users: number;
  new_users_30d: number;
  total_accounts: number;
  connected_accounts: number;
  disconnected_accounts: number;
  failed_accounts: number;
  total_resources: number;
  resources_by_service: Record<string, number>;
  active_alerts: number;
  critical_alerts: number;
  high_alerts: number;
  medium_alerts: number;
  low_alerts: number;
  resolved_alerts: number;
  scans_today: number;
  total_scans: number;
  notifications_sent: number;
}

export interface DashboardResponse {
  success: boolean;
  stats: DashboardStats;
  recent_activity: AdminAuditLog[];
}

// Analytics
export interface GrowthPoint {
  date: string;
  users: number;
  new_users: number;
  scans: number;
  alerts: number;
}

export interface ServiceBreakdownItem {
  service: string;
  count: number;
}

export interface AccountStatusItem {
  status: string;
  count: number;
  color: string;
}

export interface SeverityBreakdownItem {
  name: string;
  count: number;
  color: string;
}

export interface AnalyticsResponse {
  success: boolean;
  timeframe: string;
  growth_series: GrowthPoint[];
  service_breakdown: ServiceBreakdownItem[];
  account_status: AccountStatusItem[];
  severity_breakdown: SeverityBreakdownItem[];
}

// System Health
export interface ComponentHealth {
  name: string;
  status: 'Operational' | 'Degraded' | 'Down';
  description: string;
  uptime?: string;
  latency_ms?: number;
  failed_scans_24h?: number;
  failed_notifications_24h?: number;
  error?: string | null;
}

export interface SystemHealthResponse {
  success: boolean;
  timestamp: string;
  components: ComponentHealth[];
}

// Global Search
export interface SearchResultItem {
  id: string;
  title: string;
  subtitle: string;
  type: 'User' | 'AWS Account' | 'Resource' | 'Alert';
}

export interface GlobalSearchResponse {
  success: boolean;
  query: string;
  results: {
    users: SearchResultItem[];
    accounts: SearchResultItem[];
    resources: SearchResultItem[];
    alerts: SearchResultItem[];
  };
}
