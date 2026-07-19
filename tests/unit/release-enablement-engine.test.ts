import { describe, expect, it } from 'vitest';
import {
  documentationCoverage,
  launchBlockers,
  onboardingCompletion,
  releaseEnablementReadiness,
  staleDocumentation,
  trainingReadiness,
  unpublishedCommunications,
} from '../../apps/web/lib/release-enablement-engine';
import { getReleaseEnablementData } from '../../apps/web/lib/data/release-enablement';

const d = getReleaseEnablementData();

describe('release enablement engine', () => {
  it('calculates documentation coverage', () => {
    expect(documentationCoverage(d.documentation)).toBe(90);
  });

  it('identifies stale documentation', () => {
    expect(staleDocumentation(d.documentation, new Date('2026-07-26'))).toHaveLength(1);
  });

  it('calculates onboarding completion', () => {
    expect(onboardingCompletion(d.onboarding)).toBe(84);
  });

  it('calculates required training readiness', () => {
    expect(trainingReadiness(d.training)).toBe(92.5);
  });

  it('finds unpublished communications', () => {
    expect(unpublishedCommunications(d.communications)).toHaveLength(2);
  });

  it('finds required launch blockers', () => {
    expect(launchBlockers(d.controls)).toHaveLength(1);
  });

  it('calculates release readiness', () => {
    expect(releaseEnablementReadiness(d.documentation, d.onboarding, d.training, d.communications, d.controls)).toBe(83.3);
  });

  it('returns perfect scores for empty portfolios', () => {
    expect(documentationCoverage([])).toBe(100);
    expect(onboardingCompletion([])).toBe(100);
    expect(trainingReadiness([])).toBe(100);
  });
});
