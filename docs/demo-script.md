# Demo Script · Week 7

**Group:** group1b-scale
**Track:** Scale it · 1B
**Tutor:** Mr. Shadrack Darku
**Demo owner:** Joseph Nii Tetteh Tackie
**Duration:** 8 minutes, live

> The room sees this. The names are the properties we are demonstrating;
> the actions are how we prove them. Beat four is the moment people remember.

---

## Pre-demo checklist  *(run this 5 minutes before we start)*

- [ ] App is live at the ALB URL; both tasks `RUNNING` and `HEALTHY`
- [ ] Both tasks confirmed in different AZs (describe-tasks output ready)
- [ ] CloudWatch dashboard open on a second screen
- [ ] GitHub Actions tab open on a third screen
- [ ] Load test ready: `k6 run -e TARGET=http://<our-alb> loadtest/basic.js`
- [ ] `aws ecs stop-task` command prepared with one task ARN
- [ ] A small, harmless change ready on a branch (bump `APP_VERSION`)
- [ ] An earlier image tag noted, in case we demo the rollback stretch goal
- [ ] `terraform destroy` typed but **not** entered — wait for beat six

---

## Beat 1 · High Availability  *(0:00 – 1:00)*

**What we say**
> Here is the app, running. Two containers, in two different availability zones, both healthy. We are no longer a single point of failure.

**What we do**
1. Open the app in a browser; refresh once to confirm it loads.
2. Switch to the ECS console; show two tasks in `RUNNING` state.
3. Run `aws ecs describe-tasks` and point at `eu-west-1a` and `eu-west-1b`.

**What the room sees** — Two healthy tasks, two zones.

**Backup** — If a task is unhealthy, fall back to the architecture diagram and explain the design. Skip the live `describe-tasks` call.

---

## Beat 2 · Realistic Load  *(1:00 – 2:30)*

**What we say**
> We start the load test. The request count climbs on the dashboard.

**What we do**
1. Start the k6 script from the EC2 box in `eu-west-1`.
2. Switch to the ALB metrics dashboard; point at the request count climbing.

**What the room sees** — A live load test, real traffic on a real dashboard.

**Note** — Run from the EC2 instance in `eu-west-1`, not a home laptop. A home connection in Accra measures the connection, not the service.

**Backup** — If k6 fails, fall back to `hey -z 5m -c 50 http://<our-alb>/api/tasks`.

---

## Beat 3 · Elastic Scaling  *(2:30 – 4:00)*

**What we say**
> The task count goes from two to four on its own, live on screen. Autoscaling reacts to a signal we chose — requests per target, not CPU.

**What we do**
1. Keep the load test running.
2. Watch the ECS service `desired_count` climb from 2 → 4.
3. Briefly explain why we picked `ALBRequestCountPerTarget` over CPU.

**What the room sees** — The system growing on its own. No human intervention.

**Note** — This beat needs the load test from beat two still running. If scaling does not fire within 90 seconds, ramp the k6 target higher.

**Backup** — If scaling does not fire, manually bump `desired_count` to 4 and be honest about it. Skip the autoscaling explanation.

---

## Beat 4 · Self-Healing  *(4:00 – 5:30)*  — THE BEAT PEOPLE REMEMBER

**What we say**
> We kill a container by hand. The page never fails to load. A replacement starts.

**What we do**
1. Copy one task ARN from the ECS console.
2. Run `aws ecs stop-task --cluster group1b-cluster --task <arn>`.
3. Keep refreshing the app in the browser — the page never fails.
4. Watch the target group: the killed target drains, ECS launches a replacement.

**What the room sees** — A container killed live, the page survives, a replacement starts.

**Note** — This is the beat most likely to fail. The health check takes ~45 seconds to notice and pull the target. We rehearse this beat first, alone, three times, before running the full demo.

**Backup** — If the page does fail, point at the CloudWatch logs and explain what the health check is doing. Be honest: "We are still in the drain window — give it thirty seconds."

---

## Beat 5 · Zero-Downtime Deploys  *(5:30 – 7:00)*

**What we say**
> We merge a change and it deploys while the load test is still running. No 5xx.

**What we do**
1. Merge the prepared branch on GitHub.
2. Switch to the GitHub Actions tab; watch the deploy workflow run.
3. Keep the load test running; watch `http_req_failed` stay at zero.
4. Point at the new `APP_VERSION` in the page footer once the deploy completes.

**What the room sees** — A merge → a pipeline run → a new version live, with zero errors during the deploy.

**Note** — With `minimum_healthy_percent = 100` and `maximum_percent = 200`, ECS starts the new tasks first, then drains the old ones. We briefly pay for four tasks instead of two. That is the trade.

**Backup** — If the deploy fails, the circuit breaker rolls back automatically. Point at it and explain. That is itself a demo.

---

## Beat 6 · Infrastructure as Code  *(7:00 – 8:00)*

**What we say**
> We destroy everything. The pipeline rebuilds all of it.

**What we do**
1. Run `terraform destroy` (type `yes`).
2. Watch the console empty: load balancer gone, target group gone, ECS service gone.
3. Re-run the latest deploy workflow from the Actions tab.
4. Watch the environment come back identical.

**What the room sees** — The whole system deleted and rebuilt, with no human touching a terminal.

**Note** — The database takes ~8 minutes to destroy and another ~8 to rebuild. For the live demo, destroy only the app and ALB with `-target`, then bring them back. State the full destroy-and-rebuild time from a recorded run we did earlier in the week.

**Backup** — If the rebuild hangs, cut to the recorded clip. State the time from a real run.

---

## Total — 8 minutes, timed

If we overrun, we cut beat six short and show the recorded destroy-and-rebuild clip instead. Overruns get cut off — that is why we rehearse.

---

## When things go wrong

| What fails | What we do |
|---|---|
| Beat 4 health check is slow | Be honest about the 45-second window. Do not pretend. |
| Beat 5 deploy shows errors | Point at the circuit breaker rolling back. That is the demo. |
| Beat 6 rebuild hangs | Cut to the recorded clip. State the time from a real run. |
| Wi-fi drops on the projector | Pause, ask for two minutes, resume from the same beat. |
| A command typo live | Re-type it. Calmly. Everyone watching has done the same. |

---

## Rehearsal notes

- **Rehearse beat 4 alone, three times, before running the full demo.**
- Time every rehearsal. Overruns get cut off.
- The first rehearsal is where we find the fragile beat. Fix it before the second.
- The recording we hand in (30–60 seconds, beat four) is the LinkedIn clip.
