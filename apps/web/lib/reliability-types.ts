export type ServiceStatus = 'operational' | 'degraded' | 'outage' | 'maintenance';
export type IncidentSeverity = 'sev1' | 'sev2' | 'sev3' | 'sev4';
export type IncidentStatus = 'investigating' | 'identified' | 'monitoring' | 'resolved';
export type FlagStatus = 'draft' | 'active' | 'paused' | 'retired';

export type ServiceObjective = {
  id: string;
  serviceId: string;
  name: string;
  targetPercent: number;
  windowDays: number;
  goodEvents: number;
  totalEvents: number;
};

export type PlatformService = {
  id: string;
  name: string;
  owner: string;
  tier: 0 | 1 | 2 | 3;
  status: ServiceStatus;
  dependencies: string[];
  runbookUrl: string;
  lastDeployAt: string;
};

export type Incident = {
  id: string;
  title: string;
  severity: IncidentSeverity;
  status: IncidentStatus;
  serviceIds: string[];
  commander: string;
  startedAt: string;
  resolvedAt: string | null;
  nextUpdateAt: string | null;
  customerImpact: string;
};

export type FeatureFlag = {
  id: string;
  key: string;
  description: string;
  status: FlagStatus;
  environment: 'staging' | 'production';
  rolloutPercent: number;
  owner: string;
  expiresAt: string | null;
  killSwitch: boolean;
};

export type MaintenanceWindow = {
  id: string;
  serviceId: string;
  title: string;
  startsAt: string;
  endsAt: string;
  status: 'scheduled' | 'in_progress' | 'completed' | 'cancelled';
};
