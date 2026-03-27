# Community-First Website References

Capture date: **2026-03-24**

## Goal
This note collects open source project websites worth studying for a future Cassandra web presence under `future/website/`. The filter here is strict:

- community-first, not campaign-first
- useful entry points over brand theater
- obvious paths into docs, downloads, governance, and contribution
- modern navigation and page structure without turning the site into product marketing

I treated a site as a strong reference when it helped a user answer one of these quickly:

1. Where do I start?
2. Where are the docs?
3. How is this project run?
4. How do I contribute?
5. What is current right now: release, event, roadmap, or support channel?

## Best Primary References

### 1. Python
Main site: [python.org](https://www.python.org/)

Why it is considered:
- It acts like a project hub, not a brochure.
- Docs, downloads, community, events, jobs, PSF, and contribution paths are all first-class.
- The site handles both end users and community participants without forcing either into a marketing funnel.

What it does especially well:
- The global navigation immediately exposes `Downloads`, `Documentation`, `Community`, `Success Stories`, `News`, and `Events`.
- The PSF area makes volunteering, membership, working groups, and governance visible rather than implicit.
- The broader Python network is legible from the site itself, which matters for a mature ecosystem.

Transferable ideas for Cassandra:
- Make docs, downloads, support channels, and governance peers in the top navigation.
- Treat project operations as part of the website, not as hidden maintainer knowledge.
- Expose community participation modes directly from the main site.

Sources:
- [Python home](https://www.python.org/)
- [PSF volunteer page](https://www.python.org/psf/volunteer/)

### 2. Fedora
Main site: [fedoraproject.org](https://fedoraproject.org/)

Why it is considered:
- Fedora is one of the clearest examples of a modern open source site that still feels run for contributors.
- It balances download/start-here flows with visible contributor onboarding.
- The visual design is contemporary, but the site stays information-dense.

What it does especially well:
- The homepage exposes `Edit this website`, `Docs`, `Ask Fedora`, `Discussion`, `Contribute to Fedora`, and `Community Blog`.
- It treats editions, docs, and community participation as equal parts of the experience.
- The contributor path is visible from the front door rather than buried in a footer.

Transferable ideas for Cassandra:
- Put contribution, discussion, and docs into the same top-level experience.
- Use the homepage to route by intent: use Cassandra, operate Cassandra, contribute to Cassandra.
- Keep the site modern without sacrificing navigational density.

Sources:
- [Fedora home](https://fedoraproject.org/)
- [Fedora contribute](https://docs.fedoraproject.org/en-US/project/join/)

### 3. PostgreSQL
Main site: [postgresql.org](https://www.postgresql.org/)

Why it is considered:
- PostgreSQL is a good model for a serious infrastructure project website that prioritizes operational usefulness over image.
- It keeps current releases, docs, community, support, and events easy to find.
- The site is conservative visually, but the information architecture is excellent.

What it does especially well:
- `Documentation`, `Community`, `Developers`, `Support`, and `About` are all top-level.
- The homepage quickly exposes release status, project news, upcoming events, and links to docs and downloads.
- It feels like an active project home for practitioners rather than an adoption pitch.

Transferable ideas for Cassandra:
- Keep release state and docs current on the homepage.
- Make support and community channels explicit.
- Favor utility and credibility over elaborate homepage storytelling.

Sources:
- [PostgreSQL home](https://www.postgresql.org/)
- [PostgreSQL community](https://www.postgresql.org/community/)

### 4. Rust
Main site: [rust-lang.org](https://rust-lang.org/)

Why it is considered:
- Rust is one of the cleanest modern examples of a project site that still respects governance and community structure.
- The site is polished, but it does not hide learning, tooling, governance, or community behind promotional copy.
- It balances newcomer and contributor needs well.

What it does especially well:
- The top navigation includes `Install`, `Learn`, `Playground`, `Tools`, `Governance`, `Community`, and `Blog`.
- Current release information is visible immediately.
- Governance is a first-class page, which is rare and worth copying.

Transferable ideas for Cassandra:
- Put governance in the main navigation.
- Surface the primary user tasks first, then let deeper docs carry the detail.
- Make release freshness obvious.

Sources:
- [Rust home](https://www.rust-lang.org/)
- [Rust governance](https://www.rust-lang.org/governance/)
- [Rust community](https://www.rust-lang.org/community/)

### 5. Django
Main site: [djangoproject.com](https://www.djangoproject.com/)

Why it is considered:
- Django keeps a mature project website compact, readable, and community-aware.
- It makes docs, community, downloads, and foundation information easy to scan from the homepage.
- The site feels calm and editorial rather than promotional.

What it does especially well:
- The homepage quickly routes to `Download`, `Documentation`, `News`, `Community`, and `Code`.
- The Django Software Foundation and contribution surfaces are close at hand.
- The homepage is concise without being empty.

Transferable ideas for Cassandra:
- Use a compact homepage that routes into the real work fast.
- Keep the foundation and governance context near the technical content.
- Prefer strong, editorial information architecture over oversized hero sections.

Sources:
- [Django home](https://www.djangoproject.com/)
- [Django community](https://www.djangoproject.com/community/)
- [Django internals foundation page](https://www.djangoproject.com/foundation/)

### 6. Kubernetes
Main site: [kubernetes.io](https://kubernetes.io/)

Why it is considered:
- Kubernetes is one of the best examples of docs and contribution workflow being treated as core product surface.
- The project makes contribution, localization, preview, and review operationally visible.
- It is larger and more polished than Cassandra likely needs, but the structure is instructive.

What it does especially well:
- Contributor documentation is rich and directly linked from the docs ecosystem.
- The docs site treats browser edits, local preview, and ownership as normal parts of participation.
- The information architecture supports users and maintainers at the same time.

Transferable ideas for Cassandra:
- Put edit and preview paths directly in the docs experience.
- Treat contribution workflow as public documentation, not maintainer folklore.
- Use clear audience segmentation without fragmenting the overall site.

Sources:
- [Kubernetes docs](https://kubernetes.io/docs/)
- [Contribute to Kubernetes docs](https://kubernetes.io/docs/contribute/docs/)
- [Preview locally](https://kubernetes.io/docs/contribute/new-content/preview-locally/)

### 7. Helm
Main site: [helm.sh](https://helm.sh/)

Why it is considered:
- Helm is a strong example of a compact OSS site where community process is not hidden.
- The `Community` section is unusually actionable and specific.
- The site makes docs, governance, release policy, maintainers, meetings, and style guidance easy to reach.

What it does especially well:
- The community page is a real contributor start page, not a social-link dump.
- Governance, maintainers, HIPs, release checklists, communication channels, and edit links all live in one coherent structure.
- The site supports both daily users and active contributors without duplicating navigation models.

Transferable ideas for Cassandra:
- Build a contributor hub that actually starts work.
- Keep governance, maintainers, communication, and process documentation in one place.
- Add explicit edit paths on content pages.

Sources:
- [Helm home](https://helm.sh/)
- [Helm community](https://helm.sh/community/)
- [Helm docs](https://helm.sh/docs/)

### 8. Homebrew
Main site: [brew.sh](https://brew.sh/)

Why it is considered:
- Homebrew is a strong example of a minimal, practical OSS front door.
- It gets users to action immediately, then hands them to dense documentation and contribution material.
- The tone stays matter-of-fact and low on fluff.

What it does especially well:
- The homepage is short, legible, and action-oriented.
- The docs site is dense and operational, with contributor-facing guides like the formula cookbook and style guide close at hand.
- The ecosystem feels maintained by practitioners for practitioners.

Transferable ideas for Cassandra:
- Keep the homepage short if the deeper docs and contribution paths are excellent.
- Put writing and contribution standards next to the docs, not in a hidden process repo.
- Optimize for "I need to do something now" rather than for a sweeping project pitch.

Sources:
- [Homebrew home](https://brew.sh/)
- [Homebrew docs](https://docs.brew.sh/)
- [Formula cookbook](https://docs.brew.sh/Formula-Cookbook)
- [Style guide](https://docs.brew.sh/Style-Guide)

## Strong Secondary References

These are worth studying, but I would treat them as partial references rather than the main model.

### 9. Debian
Main site: [debian.org](https://www.debian.org/)

Why it is considered:
- Debian is deeply community-shaped and governance-rich.
- The site exposes philosophy, people, getting involved, releases, and news clearly.

Why it is secondary:
- The visual and interaction model is older.
- The information architecture is strong, but less modern than Fedora or Rust.

Sources:
- [Debian home](https://www.debian.org/)
- [Getting involved](https://www.debian.org/intro/help)

### 10. Apache Airflow
Main site: [airflow.apache.org](https://airflow.apache.org/)

Why it is considered:
- It is a useful ASF-adjacent example of separating user, admin, developer, and community paths clearly.
- The docs taxonomy is practical and readable.

Why it is secondary:
- It is more documentation-centric than website-centric.
- The main web surface is less distinctive than the best examples above.

Sources:
- [Airflow docs](https://airflow.apache.org/docs/)
- [Airflow community](https://airflow.apache.org/community/)
- [Airflow project page](https://airflow.apache.org/docs/apache-airflow/stable/project.html)

### 11. OpenTelemetry
Main site: [opentelemetry.io](https://opentelemetry.io/)

Why it is considered:
- It exposes docs, ecosystem, status, and community clearly.
- It reflects modern CNCF-era expectations around vendor-neutral governance and project health.

Why it is secondary:
- The homepage still spends more space on value framing than the stronger community-first references do.
- It is useful, but somewhat more product-forward in tone.

Sources:
- [OpenTelemetry home](https://opentelemetry.io/)
- [OpenTelemetry community](https://opentelemetry.io/community/)
- [OpenTelemetry contributing](https://opentelemetry.io/docs/contributing/)

### 12. Godot
Main site: [godotengine.org](https://godotengine.org/)

Why it is considered:
- It puts `Community`, `Docs`, and `Contribute` directly in the main navigation.
- The homepage exposes current releases and news clearly.
- It feels alive and participation-oriented.

Why it is secondary:
- It still carries more showcase and product-positioning weight than the strongest infrastructure references.
- Some of its strengths are specific to an enthusiast ecosystem rather than a project like Cassandra.

Sources:
- [Godot home](https://godotengine.org/)
- [Godot contributing](https://contributing.godotengine.org/)

## What The Best Sites Have In Common

Across the strongest references, the pattern is not primarily aesthetic. It is structural:

- docs are top-level, never buried
- community is top-level, never reduced to social links
- contribution is a visible workflow, not tribal knowledge
- current release state is easy to find
- governance and maintainers are discoverable
- support and discussion channels are explicit
- the homepage routes by user intent instead of trying to sell the project

## Implications For A Future Cassandra Website

If Cassandra wants a community-first web presence, the strongest direction is:

1. Make `Docs`, `Downloads`, `Community`, `Contribute`, and `Project` top-level peers.
2. Route the homepage by intent: `Operate`, `Develop`, `Contribute`, `Reference`.
3. Make release status, supported versions, and current docs entry points visible above the fold.
4. Publish governance, review ownership, and contribution workflow as website content, not side knowledge.
5. Add `Edit this page` and preview guidance anywhere documentation is presented.
6. Keep the tone factual and technical. Avoid filling the homepage with generic claims that repeat what the project already is.

## Working Recommendation

If we want a compact set of models to study in detail, I would focus on:

- Python for ecosystem breadth
- Fedora for modern contributor-forward design
- PostgreSQL for serious project utility
- Rust for governance visibility in a polished site
- Django for editorial restraint
- Helm for contributor workflow clarity

That combination covers most of the behaviors Cassandra should borrow without drifting into product-marketing site design.
