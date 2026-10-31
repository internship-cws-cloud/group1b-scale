# Project Report · Scale it

**Group:** group1b-scale
**Track:** Scale it · 1B
**Tutor:** Mr. Shadrack Darku
**Cohort:** THRIVE Africa Cloud Engineering Internship · Cohort 3
**Weeks:** 5 → 7

---

## 1 · Executive summary

We took a single, fragile container — one task behind one load balancer — and turned it into a system that runs several copies, adds more under load, loses one without anybody noticing, and takes a deployment while still serving traffic. By Friday of week six we had two tasks serving across two availability zones, autoscaling from two to four under a real load test, zero-downtime deploys through the pipeline, and a kill-and-heal demo that survives in front of a room.

The honest version of this report marks higher than the polished one. Things broke. We name them.

---

## 2 · What we built

Five pieces, each owned by two people. Every piece exists in Terraform, deployed by the pipeline, with no console clicks required to recreate the environment.

### Piece 01 · Running across availability zones
We made `desired_count` a variable (default 2) and passed all three default subnets to the ECS service. Fargate schedules tasks across zones, and the load balancer spans at least two — so a zone failure degrades but does not take the page down. We get that property for free without designing for it.

**Owners:** Saad Umar Alhassan, Daniel Owusu Twum

### Piece 02 · A health check the load balancer can trust
We tuned the target group health check: `interval = 15`, `healthy_threshold = 2`, `unhealthy_threshold = 3`, `timeout = 5`, `deregistration_delay = 30`. On the service, `health_check_grace_period_seconds = 60` gives a freshly started task a short window to wake up before it is tested. With these numbers, a container that stops responding is out of rotation in about forty-five seconds.

**Owners:** Joseph Nii Tetteh Tackie, Isaac Oboh Yamoah

### Piece 03 · Scaling on a signal we chose and can defend
We tried CPU first. It did nothing under load — our app is database-bound, so CPU barely moves. We switched to `ALBRequestCountPerTarget` with a target value of 60 requests per minute per task, `scale_out_cooldown = 60`, `scale_in_cooldown = 300`, `min_capacity = 2`, `max_capacity = 6`. The failed CPU attempt is in our notes because the bug is the content.

**Owners:** Nyamekese Amoako Boateng, Sarah Serebour-Sakyi

### Piece 04 · Deploys that never drop requests
`deployment_minimum_healthy_percent = 100`, `deployment_maximum_percent = 200`, and a circuit breaker with `rollback = true`. ECS starts the new tasks, waits for them to pass the health check, shifts traffic, then stops the old ones. We briefly pay for four tasks instead of two — that is the trade, and it is worth it. If a deployment never goes healthy, the system rolls back automatically.

**Owners:** Amoah Akolbila Yakubu, Gilbert Antwi Yeboah

### Piece 05 · A load test anyone can run
A committed k6 script that ramps from 20 to 60 virtual users over five minutes, hitting `/api/tasks` (a real database read, not the template-rendering root path). Run from a small EC2 instance in `eu-west-1`, not a home laptop — because a performance number without context about where it was measured is not a measurement.

**Owners:** David Cudjoe Akpaloo, Emmanuel Dotse

**Demo owner:** Joseph Nii Tetteh Tackie — owns the demo script, runs rehearsals, writes the report, and also builds piece 02.

---

## 3 · What broke

### The CPU scaling policy that did nothing
We wrote the autoscaling policy on CPU first, because that is what blog posts suggest. The load test ran, response times climbed, the task count stayed stubborn at 2. CPU barely moved — the app spends its time waiting on the database, not computing. A CPU-based policy sits there doing nothing while the user experience degrades.

**The fix:** switched to `ALBRequestCountPerTarget`. The scaling fired within 90 seconds of load arriving on the next run.

**What we kept:** the failed CPU attempt is documented in `docs/week5-notes.md`. The failure is the better thing to say in an interview than a rule copied from a blog post.

### Containers that cycled forever
Our first health check had no grace period. A freshly started task would be tested immediately, fail (because it was still booting), get killed, restart, fail again, get killed — a loop that never settled. The service never stabilised and we spent an afternoon confused.

**The fix:** `health_check_grace_period_seconds = 60` on the service. Ignore health checks for the first 60 seconds after a task starts.

### Load test from a home laptop
Our first load test, run from a home connection in Accra, showed response times of two seconds. We concluded our app was slow. It was not — we were measuring the home connection.

**The fix:** ran the load test from a small EC2 instance in `eu-west-1`. Response times dropped to under 200ms at the same load.

**The lesson:** a performance number without context about where it was measured is not a measurement.

### A merge after teardown
Somebody merged to main after we destroyed the environment for the night. The pipeline helpfully rebuilt everything at 9pm and ran it until morning. We came back to a larger bill than expected.

**The fix:** a rule in the README — no merges to main after teardown, or whoever merges destroys afterwards. The cost watcher reports the spend number on every call from now on.

---

## 4 · What we would do differently

1. **Write the load test first, before the scaling policy.** We did this correctly, but only after the failed CPU attempt. If we had measured first, we would have seen that CPU did not move and skipped the failed policy entirely.
2. **Add an RDS Proxy from day one.** Our `max_capacity = 6` is capped by the database connection limit on `db.t4g.micro` (~80 connections, with each container holding a pool). A proxy would let us scale higher without changing the database size.
3. **Schedule scaling to zero overnight.** We destroy every evening to protect our credits, but scheduled scaling from 2 → 0 at 10pm and back to 2 at 7am would save real money and interact more cleanly with the nightly teardown.
4. **Rehearse beat four three times, not once.** The first rehearsal is where we found the fragile beat. The second confirmed the fix. The third is what made it boring.
5. **Write notes as the week happens, not from memory on Sunday.** The bugs are the content. A report written from memory misses the interesting failures, which were the best part.

---

## 5 · Known weaknesses

We name these because everyone reviewing our work can see them anyway.

1. **The deploy role has `AdministratorAccess`.** It works, and it is too broad. Narrowing it to a least-privilege policy is a real piece of engineering — the kind the Secure it track spends two weeks on. We did not have time.
2. **The database password is a GitHub secret.** Week four removed the AWS keys (the big win), but the database password still lives in GitHub Secrets. The proper fix is for Terraform to generate it and keep it in Secrets Manager, with the task definition reading via `valueFrom`. Nobody ever sees the value.
3. **Single region.** Our ALB spans two AZs, but `eu-west-1` going down takes us down. We did not engineer multi-region in two weeks — Route 53 health-checked failover to a second region is the answer.
4. **The application itself.** The task tracker is a single Python process per container. Past a few hundred requests per second per task, Gunicorn's worker count becomes the limit — not the database, not the network. We did not tune the worker count for this brief.

---

## 6 · The numbers we can defend

| Number | Where | Why |
|---|---|---|
| `desired_count = 2` | service | Minimum to survive one container dying, and to spread across two AZs. |
| `interval = 15s` | health check | Fast enough to notice a sick container in under a minute, slow enough not to dominate traffic. |
| `healthy_threshold = 2` | health check | Two good checks before a new task takes traffic — protects against one flaky response. |
| `grace = 60s` | service | The app needs ~30s to start and connect to the DB. Without grace it is killed mid-start. |
| `target_value = 60` | scaling policy | Observed headroom per task on 0.25 vCPU before p95 latency starts climbing. |
| `max_capacity = 6` | scaling target | Ceiling where `db.t4g.micro`'s ~80 connections becomes the bottleneck. |
| `scale_in = 300s` | scaling policy | Hold capacity five minutes after a spike; shrinking fast means scaling out again a minute later. |
| `100 / 200` | deployment | Never drop below current count during a deploy; briefly allow double. |

If we double any of these, we can say what happens. That is the difference between values we chose and values copied from a blog post.

---

## 7 · Where the system breaks

We pushed, on purpose. These are the walls we found.

1. **The database runs out of connections** at `max_capacity = 6`. `db.t4g.micro` allows roughly 80 connections; each container holds a pool. We capped `max_capacity` here on purpose. The fix is an RDS Proxy or a larger instance.
2. **The application itself.** A single Python process per container. Past a few hundred requests per second per task, Gunicorn's worker count becomes the limit.
3. **Single region.** `eu-west-1` going down takes us down. Route 53 health-checked failover to a second region is the answer.

Knowing where your system stops scaling is more senior than making it scale. We pushed past `max_capacity = 6` once, on purpose, watched it break, and put it back.

---

## 8 · Self-assessment against the marking criteria

| Criterion | How we satisfy it |
|---|---|
| It works, live | Beats 1 to 4 happen in front of the room. Beat 4 — kill a container — is the moment that lands. |
| It is code | Everything in Terraform. Deploys into a clean account from a fresh clone. No console steps in the runbook. The portability test passes. |
| The numbers are ours | We can say why the health check interval is 15, why the scaling target is 60, and what happens if we double either. See section 6. |
| You know where it breaks | We can name the next bottleneck — the database, at ~6 tasks. See section 7. |
| Everyone owns something | Each person can point at a piece and explain it. The ownership table is in the README and in the presentation. |

---

## 9 · What we hand in

- `docs/demo-script.md` — the six beats, refined after rehearsal
- `docs/report.md` — this file
- `infra/autoscaling.tf` — the scaling target and policy, with the signal choice in comments
- `loadtest/basic.js` — the script, a README saying how to run it, and the results we measured
- `docs/week5-notes.md` and `docs/week6-notes.md` — what we tried, what broke, what fixed it
- A recording — 30 to 60 seconds of beat four. This is the LinkedIn clip.
- This week's spend — one number from Cost Explorer, on the call

---

## 10 · Closing

Four weeks ago most of us had not deployed anything. By the end of week seven we will have built a self-healing system: several containers, autoscaling under load, zero-downtime deploys, a kill that the page survives. Then we destroy it live and let the pipeline bring it back. That is the moment the idea lands.

It is code, not a pet.

— **group1b-scale · Scale it · Cohort 3**
