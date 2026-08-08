import { describe, expect, it } from 'vitest';
import { normalizeTomorrowReadings, TAMPA_BAY_WEATHER_POINTS } from '../../apps/web/lib/connectors/tomorrow-weather';

const tampa = TAMPA_BAY_WEATHER_POINTS[0];

describe('tomorrow.io weather connector', () => {
  it('normalizes a mild reading into an info-severity signal', () => {
    const readings = [{ location: tampa, response: { data: { time: '2026-08-08T12:00:00Z', values: { temperature: 82, precipitationIntensity: 0, precipitationType: 0 } } } }];
    const [signal] = normalizeTomorrowReadings(readings);
    expect(signal.source).toBe('tomorrow_weather');
    expect(signal.severity).toBe('info');
    expect(signal.detail.precipitationType).toBe('none');
    expect(signal.title).not.toContain('risk');
  });

  it('flags a freeze reading as critical (burst-pipe risk)', () => {
    const readings = [{ location: tampa, response: { data: { time: '2026-08-08T06:00:00Z', values: { temperature: 29, precipitationIntensity: 0, precipitationType: 0 } } } }];
    const [signal] = normalizeTomorrowReadings(readings);
    expect(signal.severity).toBe('critical');
    expect(signal.title).toContain('freeze risk');
  });

  it('flags an extreme heat reading as warning (AC-failure risk)', () => {
    const readings = [{ location: tampa, response: { data: { time: '2026-08-08T15:00:00Z', values: { temperature: 97, precipitationIntensity: 0, precipitationType: 0 } } } }];
    const [signal] = normalizeTomorrowReadings(readings);
    expect(signal.severity).toBe('warning');
    expect(signal.title).toContain('extreme heat');
  });
});
