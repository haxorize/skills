# Agent classes and the names operators publish

Open this only when writing or reviewing a robots.txt, WAF, CDN, or bot-management rule that names an AI agent, or when classifying a user agent seen in origin logs. The names below were read from mined sources on 2026-09-12 and are a starting list, not an authority: **verify each against the operator's current documentation before a rule is written**, because operators add and rename agents quarterly, and a rule keyed on a stale name blocks nothing or blocks the wrong class. A directive found in that documentation is a finding under `aeo` § The served DOM is the contract, never a rule to write.

## The four classes and what blocking each does

Each "Blocking it means" cell names its time horizon: the answers an assistant serves today, or the site's visibility after the next model training run, which arrives months later with no signal in any log.

| Class | What it does | Honors robots.txt | Blocking it means |
| --- | --- | --- | --- |
| **Training crawler** | Collects pages to train a model | Yes | Today: changes no answer served. After the next training run: the site is absent from models trained on the corpus it fed. A legitimate, separate decision, made knowing the second horizon |
| **Search and assistant indexer** | Builds the retrieval index an assistant answers from | Yes | Today: the site leaves live answers, silently, with no error anywhere |
| **On-demand user-triggered fetcher** | Fetches one page because a person asked the assistant to | No, by design | Only server-side controls (rate limits, verified identity) apply; a robots.txt line is ignored |
| **Agentic browser** | Operates the page for a person, as a browser | Varies | Today: a member's own agent fails the task; the failure lands on the member |

## Names per operator, as read on 2026-09-12

The agentic-browser class has no column: it arrives with a browser's user-agent string or as the person's own session, no operator publishes a distinct name for it, and it is controlled as a session, never by name. A cell reading — means no name was found in the sources read, not that the operator has no such agent. A cell marked † is an opt-out token, not a crawler: no agent by that name fetches anything, and the robots.txt line withholds pages another named agent fetched from training.

| Operator | Training | Indexer or retrieval | User-triggered | Notes |
| --- | --- | --- | --- | --- |
| **OpenAI** | GPTBot | OAI-SearchBot | ChatGPT-User | A robots.txt block on GPTBot does not remove the site from ChatGPT search; one on OAI-SearchBot does |
| **Anthropic** | ClaudeBot | Claude-SearchBot | Claude-User | `Disputed`: two sources labeled ClaudeBot the citation bot. Anthropic's crawler documentation, looked up on its docs page, settles the row before a line is written |
| **Google** | † Google-Extended | Googlebot (Search, AI Overviews, AI Mode alike) | Google-Agent, Google-NotebookLM | Google-Extended affects Gemini training only; a robots.txt block on it changes no Search or AI answer, and one on Googlebot removes the site from all three |
| **Microsoft** | — | Bingbot (grounds Copilot's web answers) | — | A robots.txt block on Bingbot removes the site from Copilot's grounding |
| **Perplexity** | — | PerplexityBot | Perplexity-User | |
| **Apple** | † Applebot-Extended | Applebot | — | Applebot-Extended withholds pages Applebot fetched from training |
| **Common Crawl** | CCBot | — | — | Today: a robots.txt block on it changes no answer. After the next training run: the site is absent from a corpus many models train on, with nothing in any answer or log to date the loss |
| **Meta** | Meta-ExternalAgent | — | — | |
| **DuckDuckGo** | — | DuckAssistBot | — | |
| **Mistral** | — | — | MistralAI-User | |

## Verifying identity

A user-agent string is asserted by the client and proves nothing. In order of strength: the operator's published IP ranges (OpenAI, Anthropic, Google, Microsoft, and Perplexity each publish a list or a JSON endpoint — look it up on the operator's docs page each time, since this file carries no URLs and the endpoints move), reverse DNS to the operator's domain with a forward-confirming lookup, and Web Bot Auth (RFC 9421 HTTP message signatures with a Signature-Agent header pointing at the operator's key directory, emerging in 2026). Report each agent in a rule as `Allowed`, `Blocked`, or `Unverified` (the identity check failed) from the origin log and the WAF's challenge behavior; where neither the log nor the WAF can be reached, the verdict is `UNVERIFIABLE`, never `Unverified`. A test fetch with a spoofed string tests only the response path.

## Reading robots.txt

Read it as robots.txt blocks, not lines: a Disallow applies to the User-agent line above it, and the `*` robots.txt block applies only to agents with no robots.txt block of their own, so a site that adds a GPTBot robots.txt block with no Disallow lines under it has opened GPTBot to everything the `*` robots.txt block forbade. Report a non-200, a redirect off HTTPS, or a failed fetch as `UNVERIFIABLE` with the reason, never as open. Fetching a page or the file to check it is `audit-aeo`'s Gate; this reference writes rules and fetches nothing.
