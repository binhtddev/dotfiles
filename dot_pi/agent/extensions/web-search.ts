/**
 * Web Search Extension for pi — Free (DuckDuckGo)
 *
 * Provides `web_search` and `web_fetch` tools using DuckDuckGo's free API.
 * No API keys, no sign-up, no configuration needed.
 *
 * Usage:
 *   - Ask: "search the web for latest news about X"
 *   - Ask: "what's the weather in Tokyo?"
 *   - LLM will automatically call web_search when it needs current info
 *   - Use web_fetch to read the full content of a specific URL
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// ─── DuckDuckGo Search ─────────────────────────────────────────────

interface SearchResult {
  title: string;
  url: string;
  snippet: string;
}

/**
 * Search via DuckDuckGo Lite API.
 * Returns HTML containing search results in a simple table format.
 * No API key required, but rate-limited (~1 request/sec recommended).
 */
async function searchDuckDuckGo(
  query: string,
  count: number,
  signal?: AbortSignal,
): Promise<SearchResult[]> {
  // Step 1: Try the Lite API (returns HTML table with results)
  const liteResults = await searchLiteApi(query, count, signal);
  if (liteResults.length > 0) return liteResults;

  // Step 2: Fallback to the Instant Answer API
  return searchInstantApi(query, count, signal);
}

async function searchLiteApi(
  query: string,
  count: number,
  signal?: AbortSignal,
): Promise<SearchResult[]> {
  const url = new URL("https://lite.duckduckgo.com/lite/");
  url.searchParams.set("q", query);

  const response = await fetch(url.toString(), {
    signal,
    headers: {
      "User-Agent": "Mozilla/5.0 (compatible; PiBot/1.0)",
    },
  });

  if (!response.ok) return [];

  const html = await response.text();
  const results: SearchResult[] = [];

  // Parse DDG Lite HTML format.
  // Results are in <tr> blocks containing:
  //   <td class="result-link">
  //     <a href="...">title</a>
  //   </td>
  //   <td class="result-snippet">...</td>

  // Split into result rows
  const rows = html.split("<tr");
  for (let i = 1; i < rows.length && results.length < count; i++) {
    const row = rows[i]!;

    // Extract link: <a href="URL">TITLE</a>
    const linkMatch = row.match(/<a\s+href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/i);
    if (!linkMatch) continue;

    let url = linkMatch[1]!.trim();
    let title = linkMatch[2]!.replace(/<[^>]*>/g, "").trim();

    // Skip ads, empty titles, or missing data
    if (!title || !url) continue;

    // Extract snippet
    const snippetMatch = row.match(/class="result-snippet">([\s\S]*?)<\/td>/i);
    let snippet = snippetMatch ? snippetMatch[1]!.replace(/<[^>]*>/g, "").trim() : "";

    // Decode HTML entities
    const decode = (s: string) =>
      s
        .replace(/&amp;/g, "&")
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/&quot;/g, '"')
        .replace(/&#x27;/g, "'")
        .replace(/&#39;/g, "'")
        .replace(/&nbsp;/g, " ");

    results.push({
      title: decode(title),
      url: decode(url),
      snippet: decode(snippet),
    });
  }

  return results;
}

async function searchInstantApi(
  query: string,
  count: number,
  signal?: AbortSignal,
): Promise<SearchResult[]> {
  const url = new URL("https://api.duckduckgo.com/");
  url.searchParams.set("q", query);
  url.searchParams.set("format", "json");
  url.searchParams.set("no_html", "1");
  url.searchParams.set("skip_disambig", "1");

  const response = await fetch(url.toString(), {
    signal,
    headers: {
      "User-Agent": "Mozilla/5.0 (compatible; PiBot/1.0)",
    },
  });

  if (!response.ok) return [];

  const data = (await response.json()) as {
    AbstractText?: string;
    AbstractSource?: string;
    AbstractURL?: string;
    Results?: Array<{ Text: string; FirstURL: string }>;
    RelatedTopics?: Array<
      { Text: string; FirstURL: string } | { Topics?: Array<{ Text: string; FirstURL: string }> }
    >;
  };

  const results: SearchResult[] = [];

  // Abstract / instant answer
  if (data.AbstractText) {
    results.push({
      title: data.AbstractSource || "Summary",
      url: data.AbstractURL || "",
      snippet: data.AbstractText.slice(0, 500),
    });
  }

  // Direct results
  if (data.Results) {
    for (const r of data.Results) {
      if (results.length >= count) break;
      const parts = r.Text.split(" - ");
      results.push({
        title: parts[0] || r.Text,
        url: r.FirstURL,
        snippet: r.Text,
      });
    }
  }

  // Related topics
  if (data.RelatedTopics) {
    for (const topic of data.RelatedTopics) {
      if (results.length >= count) break;
      if ("Topics" in topic && topic.Topics) {
        for (const sub of topic.Topics) {
          if (results.length >= count) break;
          const parts = sub.Text.split(" - ");
          results.push({
            title: parts[0] || sub.Text,
            url: sub.FirstURL,
            snippet: sub.Text,
          });
        }
      } else if ("Text" in topic && topic.Text) {
        const parts = topic.Text.split(" - ");
        results.push({
          title: parts[0] || topic.Text,
          url: (topic as { FirstURL: string }).FirstURL,
          snippet: topic.Text,
        });
      }
    }
  }

  return results;
}

// ─── URL Content Fetch ─────────────────────────────────────────────

async function fetchPageContent(
  url: string,
  maxLength: number,
  signal?: AbortSignal,
): Promise<string> {
  try {
    const response = await fetch(url, {
      signal,
      headers: {
        "User-Agent": "Mozilla/5.0 (compatible; PiBot/1.0)",
        Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      },
      redirect: "follow",
    });

    if (!response.ok) return "";

    const html = await response.text();

    // Quick text extraction: strip script/style, remove tags
    const text = html
      .replace(/<script[^>]*>[\s\S]*?<\/script>/gi, "")
      .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, "")
      .replace(/<nav[^>]*>[\s\S]*?<\/nav>/gi, "")
      .replace(/<footer[^>]*>[\s\S]*?<\/footer>/gi, "")
      .replace(/<header[^>]*>[\s\S]*?<\/header>/gi, "")
      .replace(/<[^>]+>/g, " ")
      .replace(/&[a-z]+;/g, " ")
      .replace(/\s+/g, " ")
      .trim();

    return text.slice(0, maxLength);
  } catch {
    return "";
  }
}

// ─── Extension ─────────────────────────────────────────────────────

export default function webSearchExtension(pi: ExtensionAPI) {
  // ── web_search tool ──────────────────────────────────────────
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web for current information. Use when you need up-to-date news, " +
      "weather, prices, documentation, or any live fact. Powered by DuckDuckGo (free, no API key).",
    promptSnippet: "Search the web using a keyword or question",
    promptGuidelines: [
      "Use web_search when the user asks about current events, recent news, or time-sensitive information.",
      "Use web_search to verify facts or get the latest documentation instead of guessing.",
      "For live prices, weather, or rapidly changing data, always use web_search.",
    ],
    parameters: Type.Object({
      query: Type.String({
        description: "Search query — keywords or a natural language question",
      }),
    }),
    async execute(_toolCallId, params, signal, onUpdate, _ctx) {
      onUpdate?.({
        content: [{ type: "text", text: `🔍 Searching: "${params.query}"` }],
        details: undefined,
      });

      const results = await searchDuckDuckGo(params.query, 5, signal);

      if (results.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: `No results found for "${params.query}". Try different wording.`,
            },
          ],
          details: { query: params.query, count: 0 },
        };
      }

      // Format results as a clean list
      const lines = [`## Web search: "${params.query}"`, ""];

      for (let i = 0; i < results.length; i++) {
        const r = results[i]!;
        lines.push(`### ${i + 1}. ${r.title}`);
        lines.push(`[${r.url}](${r.url})`);
        lines.push(`${r.snippet}`);
        lines.push("");
      }

      return {
        content: [{ type: "text", text: lines.join("\n") }],
        details: { query: params.query, count: results.length },
      };
    },
  });

  // ── web_fetch tool ───────────────────────────────────────────
  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description:
      "Fetch and extract text from a URL. Use to read the full content of a webpage, " +
      "article, or documentation page found via web_search.",
    promptSnippet: "Fetch the text content of a URL",
    promptGuidelines: [
      "Use web_fetch when the user provides a specific URL to read.",
      "Use web_fetch to read the full content of a page found via web_search.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "The URL to fetch" }),
      max_length: Type.Optional(
        Type.Integer({
          description: "Max characters (default 5000, max 30000)",
          minimum: 500,
          maximum: 30000,
        }),
      ),
    }),
    async execute(_toolCallId, params, signal, onUpdate, _ctx) {
      const maxLength = params.max_length || 5000;

      onUpdate?.({
        content: [{ type: "text", text: `📄 Fetching: ${params.url}` }],
        details: undefined,
      });

      const content = await fetchPageContent(params.url, maxLength, signal);

      if (!content) {
        return {
          content: [
            {
              type: "text",
              text: `Could not fetch content from:\n${params.url}`,
            },
          ],
          isError: true,
          details: { url: params.url },
        };
      }

      return {
        content: [
          {
            type: "text",
            text: [
              `## Content from: ${params.url}`,
              "",
              content,
              "",
              `---\n*Fetched ${content.length} characters*`,
            ].join("\n"),
          },
        ],
        details: { url: params.url, length: content.length },
      };
    },
  });
}
