export type MatchEntity = {
  id: string;
  name: string;
  website?: string;
  phone?: string;
  address?: string;
  city?: string;
  state?: string;
  externalIds?: string[];
};

export type MatchReason = { field: string; score: number; detail: string };
export type MatchResult = {
  score: number;
  decision: 'auto_link' | 'review' | 'new_record';
  reasons: MatchReason[];
};

export function normalizeText(value = ''): string {
  return value
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\b(incorporated|inc|llc|ltd|company|co|corporation|corp)\b/g, '')
    .replace(/[^a-z0-9]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function normalizeDomain(value = ''): string {
  return value.toLowerCase().replace(/^https?:\/\//, '').replace(/^www\./, '').split('/')[0].trim();
}

export function normalizePhone(value = ''): string {
  const digits = value.replace(/\D/g, '');
  return digits.length === 11 && digits.startsWith('1') ? digits.slice(1) : digits;
}

function bigrams(value: string): Set<string> {
  const padded = ` ${value} `;
  const result = new Set<string>();
  for (let index = 0; index < padded.length - 1; index += 1) result.add(padded.slice(index, index + 2));
  return result;
}

export function similarity(left: string, right: string): number {
  const a = bigrams(normalizeText(left));
  const b = bigrams(normalizeText(right));
  if (!a.size && !b.size) return 1;
  const intersection = [...a].filter((item) => b.has(item)).length;
  return (2 * intersection) / (a.size + b.size);
}

export function scoreOrganizationMatch(left: MatchEntity, right: MatchEntity): MatchResult {
  const reasons: MatchReason[] = [];
  const leftExternal = new Set(left.externalIds ?? []);
  const externalMatch = (right.externalIds ?? []).some((id) => leftExternal.has(id));
  if (externalMatch) reasons.push({ field: 'external_id', score: 100, detail: 'Shared source-system identifier' });

  const domainA = normalizeDomain(left.website);
  const domainB = normalizeDomain(right.website);
  if (domainA && domainB && domainA === domainB) reasons.push({ field: 'website', score: 98, detail: `Exact domain match: ${domainA}` });

  const phoneA = normalizePhone(left.phone);
  const phoneB = normalizePhone(right.phone);
  if (phoneA.length >= 7 && phoneA === phoneB) reasons.push({ field: 'phone', score: 96, detail: 'Exact normalized phone match' });

  const nameSimilarity = similarity(left.name, right.name);
  reasons.push({ field: 'name', score: Math.round(nameSimilarity * 92), detail: `${Math.round(nameSimilarity * 100)}% normalized-name similarity` });

  const addressSimilarity = left.address && right.address ? similarity(left.address, right.address) : 0;
  if (addressSimilarity > 0) reasons.push({ field: 'address', score: Math.round(addressSimilarity * 88), detail: `${Math.round(addressSimilarity * 100)}% address similarity` });

  const cityState = normalizeText(left.city) === normalizeText(right.city) && normalizeText(left.state) === normalizeText(right.state);
  if (left.city && right.city && cityState) reasons.push({ field: 'geography', score: 70, detail: 'Same city and state' });

  let score = externalMatch ? 100 : 0;
  if (!score) {
    const weighted = Math.max(
      domainA && domainA === domainB ? 98 : 0,
      phoneA.length >= 7 && phoneA === phoneB ? 96 : 0,
      Math.round(nameSimilarity * 70 + addressSimilarity * 20 + (cityState ? 12 : 0)),
    );
    score = Math.min(100, weighted);
  }
  return { score, decision: score >= 95 ? 'auto_link' : score >= 80 ? 'review' : 'new_record', reasons: reasons.sort((a, b) => b.score - a.score) };
}
