import { describe, expect, it } from 'vitest';
import { scoreExternalSignal } from '../../apps/web/lib/signal-scoring';

describe('signal scoring', () => {
  it('scores an old, large commercial building as A-tier (prime HVAC/plumbing replacement lead)', () => {
    const { score, tier } = scoreExternalSignal({ source: 'tampa_geohub', detail: { ageYears: 78, heatedArea: 2840, commercialUnits: 1 } });
    expect(score).toBe(84);
    expect(tier).toBe('A');
  });

  it('scores a newer, smaller building lower than an old, large one', () => {
    const older = scoreExternalSignal({ source: 'tampa_geohub', detail: { ageYears: 78, heatedArea: 2840, commercialUnits: 1 } });
    const newer = scoreExternalSignal({ source: 'tampa_geohub', detail: { ageYears: 37, heatedArea: 988, commercialUnits: 1 } });
    expect(newer.score).toBeLessThan(older.score);
    expect(newer.tier).toBe('B');
  });

  it('scores a serious non-compliance water violation at a community system as A-tier', () => {
    const { score, tier } = scoreExternalSignal({ source: 'epa_echo_sdwa', detail: { seriousViolator: true, complianceStatus: 'Violation Identified', systemType: 'Community water system' } });
    expect(score).toBe(90);
    expect(tier).toBe('A');
  });

  it('scores a clean, transient water system as low priority (C-tier)', () => {
    const { score, tier } = scoreExternalSignal({ source: 'epa_echo_sdwa', detail: { seriousViolator: false, complianceStatus: 'No Violation Identified', systemType: 'Transient non-community system' } });
    expect(score).toBe(20);
    expect(tier).toBe('C');
  });

  it('scores USGS streamflow signals low regardless of reading (regional context, not an account-level lead)', () => {
    const withReading = scoreExternalSignal({ source: 'usgs_water', detail: { value: '12.3' } });
    const noReading = scoreExternalSignal({ source: 'usgs_water', detail: { value: null } });
    expect(withReading.tier).toBe('C');
    expect(noReading.tier).toBe('C');
    expect(noReading.score).toBeGreaterThan(withReading.score);
  });

  it('scores an unknown source as 0 / C-tier rather than throwing', () => {
    const { score, tier } = scoreExternalSignal({ source: 'unknown_source', detail: {} });
    expect(score).toBe(0);
    expect(tier).toBe('C');
  });

  it('scores a freeze reading as B-tier (burst-pipe emergency risk)', () => {
    const { score, tier } = scoreExternalSignal({ source: 'tomorrow_weather', detail: { temperature: 29 } });
    expect(score).toBe(50);
    expect(tier).toBe('B');
  });

  it('scores an extreme heat reading lower than a freeze reading (AC-failure risk, less urgent than burst pipes)', () => {
    const heat = scoreExternalSignal({ source: 'tomorrow_weather', detail: { temperature: 97 } });
    const freeze = scoreExternalSignal({ source: 'tomorrow_weather', detail: { temperature: 29 } });
    expect(heat.score).toBeLessThan(freeze.score);
    expect(heat.tier).toBe('C');
  });

  it('scores routine weather low (regional context, not a demand trigger)', () => {
    const { score, tier } = scoreExternalSignal({ source: 'tomorrow_weather', detail: { temperature: 82 } });
    expect(score).toBe(10);
    expect(tier).toBe('C');
  });
});
