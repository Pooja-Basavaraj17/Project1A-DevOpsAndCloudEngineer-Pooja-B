# Reflections

## AI Attribution
The questions in this document were provided as part of the project methodology. All 
answers below are the author's own reflections, written independently.

## 1. What was the hardest technical decision you made, and why?

The hardest decision was choosing canary deployment over blue-green as the primary strategy, 
rather than treating them as equally viable options. Blue-green felt intuitively simpler — 
two environments, one atomic switch — but the case studies (especially Knight Capital and 
Cloudflare) made it clear that an instant 100% traffic switch maximizes blast radius if 
something goes wrong. Canary's gradual traffic increase, backed by statistical tests like 
Welch's t-test and chi-squared, meant a bad release only ever affects a small percentage of 
real users before being caught. The trade-off was speed: canary's full rollout takes over 
100 minutes with bake time, while blue-green could switch in seconds. I had to justify why 
safety mattered more than speed for a banking system, and keep blue-green only as a fallback 
for genuine emergency hotfixes.

## 2. What would you do differently if you started this project again?

I would read the full official project brief (Part A through Part F) before writing anything, 
instead of starting from a shorter summary. Early on, I built an entire repository structure 
and wrote several deliverables based on an incomplete understanding of what was actually 
required, then had to rebuild the repo from scratch once I saw the full specification with 
its exact mandatory folder structure. That cost real time. Next time, I'd confirm the 
complete requirements and exact submission format upfront before writing a single line of 
documentation.

## 3. How did using AI tools change how you approached this project?

AI was most useful for structuring complex information quickly — turning dense regulatory 
text (RBI Master Directions, PCI-DSS requirements) into clear mapping tables, and drafting 
YAML/SQL examples that I could then read and understand rather than writing from scratch. It 
let me move through eight technical deliverables in a fraction of the time it would have 
taken researching each tool and pattern individually. That said, I made sure to actually 
read and understand every piece of content before committing it — the goal was using AI to 
accelerate research and drafting, not to submit something I couldn't explain if asked.

## 4. Which stakeholder would be hardest to satisfy with your design, and why?

The Head of Compliance would be hardest to satisfy, because their standard isn't "does this 
work" but "can I prove this worked, to an external RBI auditor, with a complete audit trail." 
Technical correctness alone doesn't satisfy that bar — every gate needs a documented 
threshold, a logged decision, a named approver, and a timestamp. Writing the compliance gate 
table made this concrete: it's not enough to say "SAST scanning runs" — I had to specify 
exactly what triggers a failure, who approves an exception, and how long that exception can 
last before it expires. That level of specificity is what an auditor actually demands.

## 5. What's one thing about real-world DevOps/banking compliance that surprised you while researching this?

I was surprised by how much of "zero downtime" comes down to database migration strategy, 
not deployment strategy. I initially assumed zero downtime was mostly about traffic routing 
(blue-green, canary) — but the expand-contract pattern taught me that a single unsafe schema 
change can break a deployment regardless of how careful the traffic-shifting logic is, 
because old and new application versions run against the same database simultaneously during 
any rollout. The database, not the deployment mechanism, turned out to be the more fragile 
part of the whole system.
