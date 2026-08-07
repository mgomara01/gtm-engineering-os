import { describe, expect, it } from 'vitest';
import { normalizeTampaBuildings } from '../../apps/web/lib/connectors/tampa-geohub';

// Fixture shape captured from a live arcgis.tampagov.net query (commercial, built<2000) on 2026-08-05.
const features = [
  { attributes: { OBJECTID: 391, FULLADDRESS: '3411 N 29th St', YEAR_BUILT: 1948, HEAT_AREA: 2840, GROSS_AREA: 2840, COM_UNITS: 1 } },
  { attributes: { OBJECTID: 696, FULLADDRESS: '218 S Boulevard', YEAR_BUILT: 1989, HEAT_AREA: 988, GROSS_AREA: 988, COM_UNITS: 1 } },
];

describe('tampa geohub connector', () => {
  it('computes building age against an explicit reference year', () => {
    const [old] = normalizeTampaBuildings(features.slice(0, 1), 2026);
    expect(old.detail.ageYears).toBe(78);
  });

  it('flags pre-1980 buildings as higher-risk (warning)', () => {
    const [old, newer] = normalizeTampaBuildings(features, 2026);
    expect(old.severity).toBe('warning');
    expect(newer.severity).toBe('info');
  });

  it('carries address and area through to the signal', () => {
    const [old] = normalizeTampaBuildings(features.slice(0, 1), 2026);
    expect(old.location).toBe('3411 N 29th St');
    expect(old.detail.heatedArea).toBe(2840);
  });
});
