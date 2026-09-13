# Agent classes and the names operators publish

Open this only when writing or reviewing a robots.txt, WAF, CDN, or bot-management rule that names an AI agent, or when classifying a user agent seen in origin logs. The names below were read from mined sources on 2026-09-12 and are a starting list, not an authority: **verify each against the operator's current documentation before a rule is written**, because operators add and rename agents quarterly, and a rule keyed on a stale name blocks nothing or blocks the wrong class.

## The four classes and what blocking each does

| Class | What it does | Honors robots.txt | Blocking it means |
| --- | --- | --- | --- |
| **Training crawler** | Collects pages to train a model | Yes | A legitimate, separate decision; changes no answer served today |
| **Search and assistant indexer** | Builds the retrieval index an assistant answers from | Yes | The site leaves live answers, silently, with no error anywhere |
| **On-demand user-triggered fetcher** | Fetches one page because a person asked the assistant to | No, by design | Only server-side controls (rate limits, verified identity) apply; a robots.txt line is ignored |
| **Agentic browser** | Operates the page for a person, as a browser | Varies | A member's own agent fails the task; the failure lands on the member |

## Names per operator, as read on 2026-09-12

| Operator | Training | Indexer or retrieval | User-triggered | Notes |
| --- | --- | --- | --- | --- |
| **OpenAI** | GPTBot | OAI-SearchBot | ChatGPT-User | Blocking GPTBot does not remove the site from ChatGPT search; OAI-SearchBot does |
| **Anthropic** | ClaudeBot | Claude-SearchBot | Claude-User | Two sources labeled ClaudeBot the citation bot; Anthropic's own page is the authority |
| **Google** | Google-Extended (an opt-out token, not a crawler) | Googlebot (Search, AI Overviews, AI Mode alike) | Google-Agent, Google-NotebookLM | Google-Extended affects Gemini training only; blocking it changes no Search or AI answer |
| **Microsoft** | — | Bingbot (grounds Copilot's web answers) | — | A block on Bingbot removes the site from Copilot's grounding |
| **Perplexity** | — | PerplexityBot | Perplexity-User | |
| **Apple** | Applebot-Extended (an opt-out token) | Applebot | — | Applebot-Extended does not crawl; it withholds pages Applebot fetched from training |
| **Common Crawl** | CCBot | — | — | Blocking it removes the site from a corpus many models train on; one engineer's quiet block tanked a company's visibility for months before anyone noticed |
| **Meta** | Meta-ExternalAgent | — | — | |
| **DuckDuckGo** | — | DuckAssistBot | — | |
| **Mistral** | — | — | MistralAI-User | |

A cell reading — means no name was found in the sources read, not that the operator has no such agent.

## Verifying identity

A user-agent string is asserted by the client and proves nothing. In order of strength: the operator's published IP ranges (OpenAI, Anthropic, Google, Microsoft, and Perplexity each publish a list or a JSON endpoint), reverse DNS to the operator's domain with a forward-confirming lookup, and Web Bot Auth (RFC 9421 HTTP message signatures with a Signature-Agent header pointing at the operator's key directory, emerging in 2026). Report each agent in a rule as allowed, blocked, or unverified from the origin log and the WAF's challenge behavior; a test fetch with a spoofed string tests only the response path.

## Reading robots.txt

Read it as blocks, not lines: a Disallow applies to the User-agent line above it, and a `*` block applies only to agents with no block of their own, so a site that adds a GPTBot block with no Disallow lines under it has opened GPTBot to everything the `*` block forbade. Fetch the file over HTTPS and report a non-200, a redirect off HTTPS, or a failed fetch as unverified with the reason, never as open. Refuse loopback and private-range hosts, send no cookies, and follow no redirect off the site.
