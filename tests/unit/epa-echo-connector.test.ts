import { describe, expect, it } from 'vitest';
import { normalizeEpaEchoFacilities } from '../../apps/web/lib/connectors/epa-echo';

// Fixtures captured from a live echodata.epa.gov query (Hillsborough County, FL) on 2026-08-05.
const rows = [
  { FacName: '1 STOP AUTO PARTS', FacCity: 'TAMPA', FacState: 'FL', FacCounty: 'HILLSBOROUGH', RegistryID: '110007473625', SDWAIDs: null, SDWASystemTypes: null, SDWAComplianceStatus: null, SDWASNCFlag: null },
  { FacName: 'ACADEMY ARCO GAS STATION-ACADEMY ARCO GAS STATION', FacCity: 'BRANDON', FacState: 'FL', FacCounty: 'HILLSBOROUGH', RegistryID: '110053900347', SDWAIDs: 'FL6295472', SDWASystemTypes: 'Transient non-community system', SDWAComplianceStatus: 'No Violation Identified', SDWASNCFlag: 'N' },
  { FacName: 'GARDEN SPRINGS MHP-GARDEN SPRINGS MHP', FacCity: 'BRANDON', FacState: 'FL', FacCounty: 'HILLSBOROUGH', RegistryID: '110013168188', SDWAIDs: 'FL6291776', SDWASystemTypes: 'Community water system', SDWAComplianceStatus: 'Violation Identified', SDWASNCFlag: 'N' },
];

describe('epa echo connector', () => {
  it('drops rows with no SDWAIDs (non-water-system facilities)', () => {
    expect(normalizeEpaEchoFacilities(rows)).toHaveLength(2);
  });

  it('marks a clean compliance record as info severity', () => {
    const [clean] = normalizeEpaEchoFacilities(rows.slice(1, 2));
    expect(clean.severity).toBe('info');
    expect(clean.externalRef).toBe('FL6295472');
    expect(clean.location).toBe('BRANDON, HILLSBOROUGH, FL');
  });

  it('marks an active violation as warning severity', () => {
    const [violation] = normalizeEpaEchoFacilities(rows.slice(2, 3));
    expect(violation.severity).toBe('warning');
    expect(violation.title).toContain('Violation Identified');
  });

  it('escalates a serious non-compliance flag to critical', () => {
    const [snc] = normalizeEpaEchoFacilities([{ ...rows[2], SDWASNCFlag: 'Y' }]);
    expect(snc.severity).toBe('critical');
  });
});
