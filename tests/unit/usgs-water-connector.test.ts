import { describe, expect, it } from 'vitest';
import { normalizeUsgsTimeSeries } from '../../apps/web/lib/connectors/usgs-water';

// Fixture shape captured from a live waterservices.usgs.gov query (stateCd=FL) on 2026-08-05.
const series = [
  {
    sourceInfo: { siteName: 'NORTH PRONG ST. MARYS RIVER AT MONIAC, GA', siteCode: [{ value: '02228500' }] },
    variable: { variableName: 'Streamflow, ft³/s', unit: { unitCode: 'ft3/s' } },
    values: [{ value: [{ value: '0.00', dateTime: '2026-08-05T15:45:00.000-04:00' }] }],
  },
];

describe('usgs water connector', () => {
  it('normalizes a site reading into a signal', () => {
    const [signal] = normalizeUsgsTimeSeries(series);
    expect(signal.externalRef).toBe('02228500');
    expect(signal.detail.value).toBe('0.00');
    expect(signal.detail.unit).toBe('ft3/s');
    expect(signal.observedAt).toBe('2026-08-05T15:45:00.000-04:00');
    expect(signal.severity).toBe('info');
  });

  it('flags a site with no current reading as a data-quality warning', () => {
    const noReading = [{ ...series[0], values: [{ value: [] }] }];
    const [signal] = normalizeUsgsTimeSeries(noReading);
    expect(signal.severity).toBe('warning');
    expect(signal.observedAt).toBeNull();
  });
});
