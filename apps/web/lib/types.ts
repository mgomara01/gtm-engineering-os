export type WorkspaceRole = 'executive_sponsor' | 'gtm_administrator' | 'gtm_engineer' | 'sales_manager' | 'sales_user' | 'analyst' | 'technical_administrator' | 'viewer';

export type WorkspaceSummary = {
  id: string;
  name: string;
  code: string;
  status: 'planning' | 'pilot' | 'active' | 'paused' | 'archived';
  role: WorkspaceRole;
  currentStage: number;
};

export type ImplementationStage = {
  id: string;
  stageNumber: number;
  name: string;
  objective: string;
  status: 'not_started' | 'active' | 'blocked' | 'complete';
  completionPercentage: number;
  targetDate?: string;
  owner: string;
  deliverablesComplete: number;
  deliverablesRequired: number;
  openDecisions: number;
  openRisks: number;
  readinessScore: number;
};
