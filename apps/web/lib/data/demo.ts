import type { ImplementationStage, WorkspaceSummary } from '@/lib/types';

export const demoWorkspaces: WorkspaceSummary[] = [
  { id: '11111111-1111-1111-1111-111111111111', name: 'Alvarez Growth Intelligence', code: 'ALV', status: 'planning', role: 'gtm_administrator', currentStage: 3 },
  { id: '22222222-2222-2222-2222-222222222222', name: 'Intelligent Waterflow', code: 'IWF', status: 'planning', role: 'executive_sponsor', currentStage: 1 },
];

const stageNames = [
  ['Business Definition','Define the commercial model, strategic objective, and growth hypothesis.'],
  ['ICP Design','Approve target-account definitions, buyer personas, and exclusions.'],
  ['Data Strategy','Specify sources, mappings, ownership, lineage, and refresh rules.'],
  ['Market Universe','Build the complete addressable account and property universe.'],
  ['Enrichment','Complete the required firmographic, property, and contact fields.'],
  ['Scoring','Validate and activate explainable prioritization models.'],
  ['Offer Design','Approve segment-specific offers, economics, and proof points.'],
  ['Playbook Design','Translate strategy into controlled sequences and handoffs.'],
  ['Pilot','Execute a bounded pilot with explicit success and stop criteria.'],
  ['Measurement','Reconcile execution, pipeline, economics, and data quality.'],
  ['Optimization','Revise weak assumptions, rules, offers, and workflows.'],
  ['Scaling','Expand proven plays with governance and operating capacity.'],
] as const;

export const demoStages: ImplementationStage[] = stageNames.map(([name, objective], index) => ({
  id: `stage-${index + 1}`,
  stageNumber: index + 1,
  name,
  objective,
  status: index < 2 ? 'complete' : index === 2 ? 'active' : 'not_started',
  completionPercentage: index < 2 ? 100 : index === 2 ? 55 : 0,
  targetDate: index === 2 ? '2026-08-14' : undefined,
  owner: index < 3 ? 'Mike O’Mara' : 'Unassigned',
  deliverablesComplete: index < 2 ? 4 : index === 2 ? 2 : 0,
  deliverablesRequired: 4,
  openDecisions: index === 2 ? 2 : 0,
  openRisks: index === 2 ? 1 : 0,
  readinessScore: index < 2 ? 100 : index === 2 ? 68 : 0,
}));
