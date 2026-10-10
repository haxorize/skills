# Coexist with the Enterprise Agentic Skills Hub

The HumanaInnersource-EMU organization already hosts the **Enterprise Agentic Skills Hub** — the source for Humana's Claude Code plugin marketplace, where role-based plugins (`enterprise-core`, `enterprise-backend`, and the rest) install through the native `/plugin` command. We keep stormworks-skills a **separate repository** — in the same organization once the move [ADR-0101](0101-fork-and-pr-adoption-at-internal-visibility.md) proposes happens — rather than merging its skills into the Enterprise Agentic Skills Hub, because the two solve different problems: the Enterprise Agentic Skills Hub is a productized, curated marketplace that copies plugin contents into `~/.claude/` on install, while stormworks-skills is a fast-moving workshop whose `scripts/install.sh` symlinks skills live from a clone, so a `git pull` or a local edit takes effect immediately — a workflow the marketplace's copy-on-install model does not support.

UNVERIFIED: the copy-on-install behavior is recorded from the marketplace's description, not checked; it is lifted by citing the Enterprise Agentic Skills Hub's install documentation, or by running one `/plugin install` from it and confirming the contents land as copies, not links, under `~/.claude/`.

We rejected upstreaming into the Enterprise Agentic Skills Hub, which is the obvious move given a sanctioned skills marketplace sits in the exact organization we move to. Merging now would trade the workshop's edit-and-see-it-immediately loop for the marketplace's release cycle, before the skills are stable enough to want that cycle. Running a second distribution beside the sanctioned one is the governance cost of this choice; internal visibility and the organization's own review regime (ADR-0101) are what bound it. The convergence path stays open: a later decision can package these skills as a plugin under the Enterprise Agentic Skills Hub's `plugins/` directory convention once they are ready to be productized.

## Considered Options

- **Upstream into the Enterprise Agentic Skills Hub** — one sanctioned home, native `/plugin` install; rejected because the marketplace's copy-on-install model breaks the symlink-live-edit workflow this repository depends on.
- **Dual-publish** — the maintainers keep symlink-live edits from a clone, while consuming teams install a plugin snapshot from the Enterprise Agentic Skills Hub. The strongest alternative: it removes the copy-on-install objection for everyone but the maintainers, puts consumers on the sanctioned channel, and gives them a pinned version for free. Not chosen now because every snapshot is a packaging and marketplace-review step, and while the skills change weekly consumers would sit behind a release cycle or the maintainers would spend their time cutting releases. It is the shape the convergence path above is expected to take.
- **Coexist as a separate repository (chosen)** — keeps the workshop workflow, leaves a documented path to package as an Enterprise Agentic Skills Hub plugin later.

## Revisit when:

The skills stabilize enough to be productized, or a consuming team needs them delivered through the `/plugin` marketplace rather than clone-and-install.

## Deferred

- Dual-publish as the first convergence step — settled by a later decision when the skills stabilize or a consuming team asks for `/plugin` delivery.
