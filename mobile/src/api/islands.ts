const SEARCHISLE_BASE_URL = "https://searchisle.com/wp-json/wp/v2/islands";
const PER_PAGE = 100;
const PAGE_FETCH_CONCURRENCY = 4;

export interface Island {
  id: string;
  name: string;
  description: string;
  lat: number;
  lng: number;
  url: string;
}

interface WpIslandRecord {
  id: number;
  link: string;
  title: { rendered: string };
  acf?: {
    island_map?: { lat: number; lng: number } | null;
    island_intro?: string;
  };
}

function decodeHtmlEntities(text: string): string {
  return text
    .replace(/&#(\d+);/g, (_match, code: string) => String.fromCharCode(Number(code)))
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'")
    .replace(/&nbsp;/g, " ");
}

function stripHtmlTags(html: string): string {
  return decodeHtmlEntities(html.replace(/<[^>]*>/g, "")).trim();
}

function toIsland(record: WpIslandRecord): Island | null {
  const coords = record.acf?.island_map;
  if (!coords || typeof coords.lat !== "number" || typeof coords.lng !== "number") {
    return null;
  }
  return {
    id: String(record.id),
    name: decodeHtmlEntities(record.title.rendered),
    description: stripHtmlTags(record.acf?.island_intro ?? ""),
    lat: coords.lat,
    lng: coords.lng,
    url: record.link,
  };
}

async function fetchIslandsPage(page: number): Promise<{ records: WpIslandRecord[]; totalPages: number }> {
  const res = await fetch(
    `${SEARCHISLE_BASE_URL}?per_page=${PER_PAGE}&page=${page}&_fields=id,title,link,acf`
  );
  if (!res.ok) {
    throw new Error(`Failed to fetch islands (page ${page}): ${res.status}`);
  }
  const totalPages = Number(res.headers.get("X-WP-TotalPages") ?? "1");
  const records: WpIslandRecord[] = await res.json();
  return { records, totalPages };
}

/** Fetches every island from the searchisle.com public REST API, paginating as needed. */
export async function fetchAllIslands(): Promise<Island[]> {
  const first = await fetchIslandsPage(1);
  const allRecords = [...first.records];

  const remainingPages = Array.from({ length: first.totalPages - 1 }, (_, i) => i + 2);
  for (let i = 0; i < remainingPages.length; i += PAGE_FETCH_CONCURRENCY) {
    const batch = remainingPages.slice(i, i + PAGE_FETCH_CONCURRENCY);
    const results = await Promise.all(batch.map((page) => fetchIslandsPage(page)));
    for (const result of results) allRecords.push(...result.records);
  }

  return allRecords.map(toIsland).filter((island): island is Island => island !== null);
}
