# Cassandra PR Triage: Quick-Close Candidates

**Generated:** 2026-04-10
**Source:** https://github.com/apache/cassandra/pulls — 612 PRs scanned, 506 remaining after initial cleanup

---

## Part 1: JIRA-Resolved PRs (Previously Closed)

**101 PRs already closed** in the initial triage pass where the linked JIRA was resolved as Fixed.
See git history for the full list if needed.

---

## Part 2: Stale PRs (2+ Years No Activity) — 66 total

| Bucket | Count | Action |
|---|---|---|
| JIRA resolved as Fixed — close now | 12 | Close with JIRA-resolved message |
| JIRA still open — ping or close as stale | 34 | Comment asking for rebase/status |
| JIRA Won't Fix / Abandoned | 4 | Close — work was deliberately dropped |
| No JIRA ticket | 16 | Close — no ticket, no traction in 2+ years |

### 2a. Close Now — JIRA Resolved as Fixed

| PR | JIRA | Age | Title |
|---|---|---|---|
| [#2145](https://github.com/apache/cassandra/pull/2145) | [CASSANDRA-18143](https://issues.apache.org/jira/browse/CASSANDRA-18143) | 1158d | Cassandra 18143 fix for v 3.0 |
| [#2017](https://github.com/apache/cassandra/pull/2017) | [CASSANDRA-17997](https://issues.apache.org/jira/browse/CASSANDRA-17997) | 1040d | Validate the comparison git branch when generating CircleCI confi |
| [#2016](https://github.com/apache/cassandra/pull/2016) | [CASSANDRA-17997](https://issues.apache.org/jira/browse/CASSANDRA-17997) | 1040d | Validate the comparison git branch when generating CircleCI confi |
| [#1984](https://github.com/apache/cassandra/pull/1984) | [CASSANDRA-17997](https://issues.apache.org/jira/browse/CASSANDRA-17997) | 1040d | Validate the comparison git branch when generating CircleCI confi |
| [#2489](https://github.com/apache/cassandra/pull/2489) | [CASSANDRA-18658](https://issues.apache.org/jira/browse/CASSANDRA-18658) | 1001d | Add jvmarg into microbench target to run microbench tests for jdk |
| [#2491](https://github.com/apache/cassandra/pull/2491) | [CASSANDRA-18658](https://issues.apache.org/jira/browse/CASSANDRA-18658) | 913d | Add jvmarg into microbench target to run microbench tests for jdk |
| [#2448](https://github.com/apache/cassandra/pull/2448) | [CASSANDRA-17808](https://issues.apache.org/jira/browse/CASSANDRA-17808) | 913d | Optionally avoid hint transfer during decommission |
| [#2018](https://github.com/apache/cassandra/pull/2018) | [CASSANDRA-17997](https://issues.apache.org/jira/browse/CASSANDRA-17997) | 913d | Validate the comparison git branch when generating CircleCI confi |
| [#1674](https://github.com/apache/cassandra/pull/1674) | [CASSANDRA-17587](https://issues.apache.org/jira/browse/CASSANDRA-17587) | 913d | Cassandra 17587 4.1 |
| [#2938](https://github.com/apache/cassandra/pull/2938) | [CASSANDRA-18963](https://issues.apache.org/jira/browse/CASSANDRA-18963) | 864d | Cassandra 18963 4.1 |
| [#2928](https://github.com/apache/cassandra/pull/2928) | [CASSANDRA-18963](https://issues.apache.org/jira/browse/CASSANDRA-18963) | 864d | Cassandra 18963 4.0 |
| [#2415](https://github.com/apache/cassandra/pull/2415) | [CASSANDRA-18120](https://issues.apache.org/jira/browse/CASSANDRA-18120) | 791d | Replica nodes for batch operation are picked by response time |

### 2b. Close — JIRA Won't Fix / Abandoned

| PR | JIRA | Resolution | Age | Title |
|---|---|---|---|---|
| [#1285](https://github.com/apache/cassandra/pull/1285) | [CASSANDRA-17047](https://issues.apache.org/jira/browse/CASSANDRA-17047) | Abandoned | 1039d | CASSANDRA-17047(4.0): Fix queries for DROP column when  |
| [#1284](https://github.com/apache/cassandra/pull/1284) | [CASSANDRA-17047](https://issues.apache.org/jira/browse/CASSANDRA-17047) | Abandoned | 1039d | CASSANDRA-17047(3.11): Handle unexpected columns due to |
| [#1283](https://github.com/apache/cassandra/pull/1283) | [CASSANDRA-17047](https://issues.apache.org/jira/browse/CASSANDRA-17047) | Abandoned | 1039d | CASSANDRA-17047 (3.0): Handle unexpected columns due to |
| [#2392](https://github.com/apache/cassandra/pull/2392) | [CASSANDRA-17047](https://issues.apache.org/jira/browse/CASSANDRA-17047) | Abandoned | 913d | CASSANDRA-17047(4.1): Fix queries for DROP column when  |

### 2c. Close — No JIRA Ticket, 2+ Years Stale

These PRs have no linked JIRA and have had no activity for 2+ years. Recommend closing with a stale message.

| PR | Age | Title |
|---|---|---|
| [#673](https://github.com/apache/cassandra/pull/673) | 1486d | Avoid hinted handoff per-host throttle being arounded to 0 in large c… |
| [#668](https://github.com/apache/cassandra/pull/668) | 1486d | use thread pool to do commit log segment sync parallel |
| [#458](https://github.com/apache/cassandra/pull/458) | 1486d | Improve performance by avoiding string concatenation in a loop using S |
| [#291](https://github.com/apache/cassandra/pull/291) | 1486d | Fix typo |
| [#165](https://github.com/apache/cassandra/pull/165) | 1486d | Remove the useless conditions. |
| [#164](https://github.com/apache/cassandra/pull/164) | 1486d | Replace the keySet iterator with an entrySet iterator. |
| [#163](https://github.com/apache/cassandra/pull/163) | 1486d | Replace the valueOf() method with parseXXX() method. |
| [#55](https://github.com/apache/cassandra/pull/55) | 1486d | Fix typo in Java doc for pending compactions |
| [#1872](https://github.com/apache/cassandra/pull/1872) | 1297d | Cassandra 3.0 |
| [#2753](https://github.com/apache/cassandra/pull/2753) | 924d | Distributed tests can return incorrect results  |
| [#2778](https://github.com/apache/cassandra/pull/2778) | 913d | Wait for live endpoints as part of waiting for gossip to settle |
| [#2754](https://github.com/apache/cassandra/pull/2754) | 913d | Distributed tests can return incorrect results  |
| [#2690](https://github.com/apache/cassandra/pull/2690) | 913d | typo |
| [#2266](https://github.com/apache/cassandra/pull/2266) | 913d | V4.1.1.2 |
| [#2736](https://github.com/apache/cassandra/pull/2736) | 912d | Do not send ECHO request if one is already in flight |
| [#3216](https://github.com/apache/cassandra/pull/3216) | 736d | 4.1: Disable checking peer certificates when require_client_auth is di |

### 2d. Stale-Open — JIRA Still Active, Needs Ping

These PRs have open JIRAs but haven't been touched in 2+ years. Recommend commenting to ask for a rebase and status update. If no response within 30 days, close.

| PR | JIRA | JIRA Status | Age | Title |
|---|---|---|---|---|
| [#421](https://github.com/apache/cassandra/pull/421) | [CASSANDRA-15437](https://issues.apache.org/jira/browse/CASSANDRA-15437) | Open | 2284d | [CASSANDRA-15437] Decommission fails with Unable to str |
| [#1087](https://github.com/apache/cassandra/pull/1087) | [CASSANDRA-16769](https://issues.apache.org/jira/browse/CASSANDRA-16769) | In Progress | 1650d | CASSANDRA-16769 Add --oldest-fraction option to nodetoo |
| [#1086](https://github.com/apache/cassandra/pull/1086) | [CASSANDRA-16768](https://issues.apache.org/jira/browse/CASSANDRA-16768) | Patch Available | 1650d | CASSANDRA-16768 Allow nodetool scrub to take a user def |
| [#1085](https://github.com/apache/cassandra/pull/1085) | [CASSANDRA-16767](https://issues.apache.org/jira/browse/CASSANDRA-16767) | In Progress | 1650d | CASSANDRA-16767 Allow nodetool garbagecollect to take a |
| [#561](https://github.com/apache/cassandra/pull/561) | [CASSANDRA-15754](https://issues.apache.org/jira/browse/CASSANDRA-15754) | Triage Needed | 1650d | CASSANDRA-15754: Provide the root cause exception. Remo |
| [#322](https://github.com/apache/cassandra/pull/322) | [CASSANDRA-15131](https://issues.apache.org/jira/browse/CASSANDRA-15131) | Triage Needed | 1646d | CASSANDRA-15131 NPE while force remove a node |
| [#1167](https://github.com/apache/cassandra/pull/1167) | [CASSANDRA-16878](https://issues.apache.org/jira/browse/CASSANDRA-16878) | Review In Progress | 1528d | CASSANDRA-16878 4.0: Race in commit log replay can caus |
| [#1166](https://github.com/apache/cassandra/pull/1166) | [CASSANDRA-16878](https://issues.apache.org/jira/browse/CASSANDRA-16878) | Review In Progress | 1528d | CASSANDRA-16878 3.11: Race in commit log replay can cau |
| [#1165](https://github.com/apache/cassandra/pull/1165) | [CASSANDRA-16878](https://issues.apache.org/jira/browse/CASSANDRA-16878) | Review In Progress | 1528d | CASSANDRA-16878 3.0: Race in commit log replay can caus |
| [#1151](https://github.com/apache/cassandra/pull/1151) | [CASSANDRA-16863](https://issues.apache.org/jira/browse/CASSANDRA-16863) | Review In Progress | 1486d | CASSANDRA-16863 Ignore repair requests in mixed mode |
| [#398](https://github.com/apache/cassandra/pull/398) | [CASSANDRA-13148](https://issues.apache.org/jira/browse/CASSANDRA-13148) | Open | 1486d | CASSANDRA-13148 add systemd service |
| [#342](https://github.com/apache/cassandra/pull/342) | [CASSANDRA-15280](https://issues.apache.org/jira/browse/CASSANDRA-15280) | In Progress | 1486d | CASSANDRA-15280 Update help for nodetool tablehistogram |
| [#218](https://github.com/apache/cassandra/pull/218) | [CASSANDRA-13971](https://issues.apache.org/jira/browse/CASSANDRA-13971) | Patch Available | 1486d | CASSANDRA-13971 Automatic certificate management using  |
| [#1539](https://github.com/apache/cassandra/pull/1539) | [CASSANDRA-17505](https://issues.apache.org/jira/browse/CASSANDRA-17505) | Triage Needed | 1471d | CASSANDRA-17505: Do not use local/broadcast addresses b |
| [#1653](https://github.com/apache/cassandra/pull/1653) | [CASSANDRA-17073](https://issues.apache.org/jira/browse/CASSANDRA-17073) | In Progress | 1414d | CASSANDRA-17073: Send all gossip notifications also to  |
| [#1687](https://github.com/apache/cassandra/pull/1687) | [CASSANDRA-15968](https://issues.apache.org/jira/browse/CASSANDRA-15968) | Open | 1386d | CASSANDRA-15968 4.0 |
| [#1960](https://github.com/apache/cassandra/pull/1960) | [CASSANDRA-17972](https://issues.apache.org/jira/browse/CASSANDRA-17972) | Open | 1254d | CASSANDRA-17972 3.11 |
| [#874](https://github.com/apache/cassandra/pull/874) | [CASSANDRA-16403](https://issues.apache.org/jira/browse/CASSANDRA-16403) | Open | 1252d | CASSANDRA-16403 Python3 for 3.11 |
| [#1956](https://github.com/apache/cassandra/pull/1956) | [CASSANDRA-17972](https://issues.apache.org/jira/browse/CASSANDRA-17972) | Open | 1247d | CASSANDRA-17972 3.0 |
| [#1688](https://github.com/apache/cassandra/pull/1688) | [CASSANDRA-15968](https://issues.apache.org/jira/browse/CASSANDRA-15968) | Open | 1166d | CASSANDRA-15968 3.0 |
| [#2477](https://github.com/apache/cassandra/pull/2477) | [CASSANDRA-18656](https://issues.apache.org/jira/browse/CASSANDRA-18656) | Open | 1001d | CASSANDRA-18656 Ensure SSTable streaming transactions d |
| [#2631](https://github.com/apache/cassandra/pull/2631) | [CASSANDRA-18572](https://issues.apache.org/jira/browse/CASSANDRA-18572) | Patch Available | 956d | CASSANDRA-18572 4.0 dont mock JMX on nodetool in dtests |
| [#2630](https://github.com/apache/cassandra/pull/2630) | [CASSANDRA-18572](https://issues.apache.org/jira/browse/CASSANDRA-18572) | Patch Available | 956d | CASSANDRA-18572 3.11 dont mock JMX on nodetool in dtest |
| [#2702](https://github.com/apache/cassandra/pull/2702) | [CASSANDRA-18845](https://issues.apache.org/jira/browse/CASSANDRA-18845) | Triage Needed | 933d | Cassandra 18845 4.0 |
| [#2701](https://github.com/apache/cassandra/pull/2701) | [CASSANDRA-18845](https://issues.apache.org/jira/browse/CASSANDRA-18845) | Triage Needed | 933d | Cassandra 18845 3.11 |
| [#2767](https://github.com/apache/cassandra/pull/2767) | [CASSANDRA-18891](https://issues.apache.org/jira/browse/CASSANDRA-18891) | Patch Available | 920d | CASSANDRA-18891 Update JNA to 5.13.0 |
| [#2632](https://github.com/apache/cassandra/pull/2632) | [CASSANDRA-18572](https://issues.apache.org/jira/browse/CASSANDRA-18572) | Patch Available | 913d | CASSANDRA-18572 4.1 dont mock JMX on nodetool in dtests |
| [#2461](https://github.com/apache/cassandra/pull/2461) | [CASSANDRA-18642](https://issues.apache.org/jira/browse/CASSANDRA-18642) | Open | 913d | CASSANDRA-18642 4.1 |
| [#2405](https://github.com/apache/cassandra/pull/2405) | [CASSANDRA-14351](https://issues.apache.org/jira/browse/CASSANDRA-14351) | Open | 913d | CASSANDRA-14351 Feat: notify systemd when startup is co |
| [#2703](https://github.com/apache/cassandra/pull/2703) | [CASSANDRA-18845](https://issues.apache.org/jira/browse/CASSANDRA-18845) | Triage Needed | 913d | Cassandra 18845 4.1 |
| [#2805](https://github.com/apache/cassandra/pull/2805) | [CASSANDRA-18904](https://issues.apache.org/jira/browse/CASSANDRA-18904) | Review In Progress | 910d | Measure repair state caches by memory retention |
| [#2901](https://github.com/apache/cassandra/pull/2901) | [CASSANDRA-19026](https://issues.apache.org/jira/browse/CASSANDRA-19026) | In Progress | 861d | Cassandra 19026 4.0 |
| [#3131](https://github.com/apache/cassandra/pull/3131) | [CASSANDRA-19429](https://issues.apache.org/jira/browse/CASSANDRA-19429) | Changes Suggested | 776d | Remove lock contention generated by getCapacity functio |
| [#2764](https://github.com/apache/cassandra/pull/2764) | [CASSANDRA-14351](https://issues.apache.org/jira/browse/CASSANDRA-14351) | Open | 737d | CASSANDRA-14351 4.0 systemd |

---

## Part 3: Deep-Dive — PRs 1+ Year Stale (95 PRs analyzed)

**Summary by action:**

| Action | Count | Description |
|---|---|---|
| CLOSE-STALE | 29 | JIRA open but PR 2+ years dead — close as stale |
| CLOSE-NO-TICKET | 29 | No linked JIRA, 1+ year stale |
| PING-AUTHOR | 22 | JIRA open, 1–2 years stale — request rebase |
| NEEDS-COMMITTER | 14 | Viable patch, JIRA active — needs committer attention |

---

### 3a. CLOSE-STALE (29 PRs) — JIRA open but PR inactive 2+ years

| PR | JIRA | Age | Title |
|---|---|---|---|
| [#218](https://github.com/apache/cassandra/pull/218) | [CASSANDRA-13971](https://issues.apache.org/jira/browse/CASSANDRA-13971) | 2284d | Automatic certificate management using Vault |
| [#322](https://github.com/apache/cassandra/pull/322) | [CASSANDRA-15131](https://issues.apache.org/jira/browse/CASSANDRA-15131) | 1646d | NPE while force remove a node |
| [#342](https://github.com/apache/cassandra/pull/342) | [CASSANDRA-15280](https://issues.apache.org/jira/browse/CASSANDRA-15280) | 1486d | Update help for nodetool tablehistograms |
| [#398](https://github.com/apache/cassandra/pull/398) | [CASSANDRA-13148](https://issues.apache.org/jira/browse/CASSANDRA-13148) | 1486d | add systemd service |
| [#421](https://github.com/apache/cassandra/pull/421) | [CASSANDRA-15437](https://issues.apache.org/jira/browse/CASSANDRA-15437) | 2284d | Decommission fails with Unable to stream |
| [#561](https://github.com/apache/cassandra/pull/561) | [CASSANDRA-15754](https://issues.apache.org/jira/browse/CASSANDRA-15754) | 1650d | Provide the root cause exception |
| [#874](https://github.com/apache/cassandra/pull/874) | [CASSANDRA-16403](https://issues.apache.org/jira/browse/CASSANDRA-16403) | 1252d | Python3 for 3.11 |
| [#1085](https://github.com/apache/cassandra/pull/1085) | [CASSANDRA-16767](https://issues.apache.org/jira/browse/CASSANDRA-16767) | 1650d | Allow nodetool garbagecollect user-defined concurrency |
| [#1086](https://github.com/apache/cassandra/pull/1086) | [CASSANDRA-16768](https://issues.apache.org/jira/browse/CASSANDRA-16768) | 1650d | Allow nodetool scrub user-defined concurrency |
| [#1087](https://github.com/apache/cassandra/pull/1087) | [CASSANDRA-16769](https://issues.apache.org/jira/browse/CASSANDRA-16769) | 1650d | Add --oldest-fraction option to nodetool |
| [#1151](https://github.com/apache/cassandra/pull/1151) | [CASSANDRA-16863](https://issues.apache.org/jira/browse/CASSANDRA-16863) | 1486d | Ignore repair requests in mixed mode |
| [#1165](https://github.com/apache/cassandra/pull/1165) | [CASSANDRA-16878](https://issues.apache.org/jira/browse/CASSANDRA-16878) | 1528d | Race in commit log replay (3.0) |
| [#1166](https://github.com/apache/cassandra/pull/1166) | [CASSANDRA-16878](https://issues.apache.org/jira/browse/CASSANDRA-16878) | 1528d | Race in commit log replay (3.11) |
| [#1167](https://github.com/apache/cassandra/pull/1167) | [CASSANDRA-16878](https://issues.apache.org/jira/browse/CASSANDRA-16878) | 1528d | Race in commit log replay (4.0) |
| [#1539](https://github.com/apache/cassandra/pull/1539) | [CASSANDRA-17505](https://issues.apache.org/jira/browse/CASSANDRA-17505) | 1471d | Do not use local/broadcast addresses before init |
| [#1653](https://github.com/apache/cassandra/pull/1653) | [CASSANDRA-17073](https://issues.apache.org/jira/browse/CASSANDRA-17073) | 1414d | Send gossip notifications to local listeners |
| [#1687](https://github.com/apache/cassandra/pull/1687) | [CASSANDRA-15968](https://issues.apache.org/jira/browse/CASSANDRA-15968) | 1386d | CASSANDRA-15968 4.0 |
| [#1688](https://github.com/apache/cassandra/pull/1688) | [CASSANDRA-15968](https://issues.apache.org/jira/browse/CASSANDRA-15968) | 1166d | CASSANDRA-15968 3.0 |
| [#1956](https://github.com/apache/cassandra/pull/1956) | [CASSANDRA-17972](https://issues.apache.org/jira/browse/CASSANDRA-17972) | 1247d | CASSANDRA-17972 3.0 |
| [#1960](https://github.com/apache/cassandra/pull/1960) | [CASSANDRA-17972](https://issues.apache.org/jira/browse/CASSANDRA-17972) | 1254d | CASSANDRA-17972 3.11 |
| [#2405](https://github.com/apache/cassandra/pull/2405) | [CASSANDRA-14351](https://issues.apache.org/jira/browse/CASSANDRA-14351) | 913d | Notify systemd when startup is complete |
| [#2461](https://github.com/apache/cassandra/pull/2461) | [CASSANDRA-18642](https://issues.apache.org/jira/browse/CASSANDRA-18642) | 913d | CASSANDRA-18642 4.1 |
| [#2477](https://github.com/apache/cassandra/pull/2477) | [CASSANDRA-18656](https://issues.apache.org/jira/browse/CASSANDRA-18656) | 1001d | Ensure SSTable streaming transactions do not overlap |
| [#2630](https://github.com/apache/cassandra/pull/2630) | [CASSANDRA-18572](https://issues.apache.org/jira/browse/CASSANDRA-18572) | 956d | Don't mock JMX in dtests (3.11) |
| [#2631](https://github.com/apache/cassandra/pull/2631) | [CASSANDRA-18572](https://issues.apache.org/jira/browse/CASSANDRA-18572) | 956d | Don't mock JMX in dtests (4.0) |
| [#2632](https://github.com/apache/cassandra/pull/2632) | [CASSANDRA-18572](https://issues.apache.org/jira/browse/CASSANDRA-18572) | 913d | Don't mock JMX in dtests (4.1) |
| [#2764](https://github.com/apache/cassandra/pull/2764) | [CASSANDRA-14351](https://issues.apache.org/jira/browse/CASSANDRA-14351) | 737d | CASSANDRA-14351 4.0 systemd |
| [#2767](https://github.com/apache/cassandra/pull/2767) | [CASSANDRA-18891](https://issues.apache.org/jira/browse/CASSANDRA-18891) | 920d | Update JNA to 5.13.0 |
| [#3383](https://github.com/apache/cassandra/pull/3383) | [CASSANDRA-18078](https://issues.apache.org/jira/browse/CASSANDRA-18078) | ~730d | CASSANDRA-18078 5.0 wip |

---

### 3b. CLOSE-NO-TICKET (29 PRs) — No JIRA, 1+ year stale

| PR | Age | Title |
|---|---|---|
| [#2683](https://github.com/apache/cassandra/pull/2683) | 933d | 18848 5.0 |
| [#2701](https://github.com/apache/cassandra/pull/2701) | 933d | Cassandra 18845 3.11 |
| [#2702](https://github.com/apache/cassandra/pull/2702) | 933d | Cassandra 18845 4.0 |
| [#2704](https://github.com/apache/cassandra/pull/2704) | 933d | Cassandra 18845 5.0 |
| [#2750](https://github.com/apache/cassandra/pull/2750) | 924d | Distributed tests can return incorrect results |
| [#2805](https://github.com/apache/cassandra/pull/2805) | 910d | Measure repair state caches by memory retention |
| [#2852](https://github.com/apache/cassandra/pull/2852) | ~880d | Standalone Jenkinsfile |
| [#2864](https://github.com/apache/cassandra/pull/2864) | ~870d | Allow unhandled operators on SAI indexed columns |
| [#2875](https://github.com/apache/cassandra/pull/2875) | ~860d | Cassandra 18932 5.0 |
| [#2877](https://github.com/apache/cassandra/pull/2877) | ~860d | Refactor negotiatedProtocolMustBeAcceptedProtocolTest |
| [#2900](https://github.com/apache/cassandra/pull/2900) | ~855d | Fix DiskSpaceMetricsTest.testFlushSize |
| [#2901](https://github.com/apache/cassandra/pull/2901) | 861d | Cassandra 19026 4.0 |
| [#2939](https://github.com/apache/cassandra/pull/2939) | 864d | Cassandra 18963 5.0 |
| [#2950](https://github.com/apache/cassandra/pull/2950) | ~850d | Post-test cleanup refactoring |
| [#2975](https://github.com/apache/cassandra/pull/2975) | ~840d | Cassandra 19126 5.0 |
| [#3097](https://github.com/apache/cassandra/pull/3097) | ~810d | C 19168 5.0 |
| [#3131](https://github.com/apache/cassandra/pull/3131) | 776d | Remove lock contention from getCapacity |
| [#3208](https://github.com/apache/cassandra/pull/3208) | ~750d | Implement types compatibility tests |
| [#3209](https://github.com/apache/cassandra/pull/3209) | ~750d | Implement types compatibility tests |
| [#3210](https://github.com/apache/cassandra/pull/3210) | ~750d | Implement types compatibility tests |
| [#3217](https://github.com/apache/cassandra/pull/3217) | ~745d | 5.0: Disable checking peer certs when require_client_auth disabled |
| [#3306](https://github.com/apache/cassandra/pull/3306) | ~720d | autorepair v2 framework |
| [#3368](https://github.com/apache/cassandra/pull/3368) | ~700d | autorepair v2 framework (against 4.1.3) |
| [#3447](https://github.com/apache/cassandra/pull/3447) | ~670d | Remove duplicated description in features/cql |
| [#3613](https://github.com/apache/cassandra/pull/3613) | ~620d | Fix bash-completion for debian distro |
| [#3755](https://github.com/apache/cassandra/pull/3755) | ~565d | IndexSummaryRedistribution should unmark compacting SSTables |
| [#3760](https://github.com/apache/cassandra/pull/3760) | ~565d | Support copyAndAddIntervals in IntervalTree |
| [#3866](https://github.com/apache/cassandra/pull/3866) | ~530d | Delete all data if reset bootstrap progress |
| [#3874](https://github.com/apache/cassandra/pull/3874) | ~530d | Delete all data if reset bootstrap progress is true |
| [#4043](https://github.com/apache/cassandra/pull/4043) | ~490d | C20514 paxos ttl loop |
| [#3776](https://github.com/apache/cassandra/pull/3776) | ~555d | Draft patch for 19492 |

---

### 3c. NEEDS-COMMITTER (14 PRs) — Viable patches awaiting review

These have active JIRAs with real patches. Do NOT close — needs a committer to look.

| PR | JIRA | Title |
|---|---|---|
| [#2633](https://github.com/apache/cassandra/pull/2633) | [CASSANDRA-18572](https://issues.apache.org/jira/browse/CASSANDRA-18572) | Don't mock JMX in dtests (5.0) |
| [#3296](https://github.com/apache/cassandra/pull/3296) | [CASSANDRA-19624](https://issues.apache.org/jira/browse/CASSANDRA-19624) | casInternal RowIterator leak fix (5.0) |
| [#3371](https://github.com/apache/cassandra/pull/3371) | [CASSANDRA-19583](https://issues.apache.org/jira/browse/CASSANDRA-19583) | Accept "0" as valid config value (5.0) |
| [#3372](https://github.com/apache/cassandra/pull/3372) | [CASSANDRA-19583](https://issues.apache.org/jira/browse/CASSANDRA-19583) | Accept "0" as valid config value (4.1) |
| [#3396](https://github.com/apache/cassandra/pull/3396) | [CASSANDRA-19733](https://issues.apache.org/jira/browse/CASSANDRA-19733) | Bootstrap options to control streaming sources (trunk) |
| [#3397](https://github.com/apache/cassandra/pull/3397) | [CASSANDRA-19733](https://issues.apache.org/jira/browse/CASSANDRA-19733) | Bootstrap options to control streaming sources (5.0) |
| [#3398](https://github.com/apache/cassandra/pull/3398) | [CASSANDRA-19733](https://issues.apache.org/jira/browse/CASSANDRA-19733) | Bootstrap options to control streaming sources (4.1) |
| [#3399](https://github.com/apache/cassandra/pull/3399) | [CASSANDRA-19733](https://issues.apache.org/jira/browse/CASSANDRA-19733) | Bootstrap options to control streaming sources (4.0) |
| [#3466](https://github.com/apache/cassandra/pull/3466) | [CASSANDRA-19828](https://issues.apache.org/jira/browse/CASSANDRA-19828) | Schema modification disablement (4.0) |
| [#3467](https://github.com/apache/cassandra/pull/3467) | [CASSANDRA-19828](https://issues.apache.org/jira/browse/CASSANDRA-19828) | Schema modification disablement (5.0) |
| [#3468](https://github.com/apache/cassandra/pull/3468) | [CASSANDRA-19828](https://issues.apache.org/jira/browse/CASSANDRA-19828) | Schema modification disablement (4.1) |
| [#3580](https://github.com/apache/cassandra/pull/3580) | [CASSANDRA-19958](https://issues.apache.org/jira/browse/CASSANDRA-19958) | Separate queue for Hints (hints queue separation) |
| [#3661](https://github.com/apache/cassandra/pull/3661) | [CASSANDRA-20051](https://issues.apache.org/jira/browse/CASSANDRA-20051) | nodetool reloadseeds (4.1) |
| [#3945](https://github.com/apache/cassandra/pull/3945) | [CASSANDRA-20394](https://issues.apache.org/jira/browse/CASSANDRA-20394) | Restore SSTableHeaderFix for standalone use |

---

### 3d. PING-AUTHOR (22 PRs) — JIRA open, 1–2 years stale

| PR | JIRA | Age | Title |
|---|---|---|---|
| [#2852](https://github.com/apache/cassandra/pull/2852) | — | ~880d | Standalone Jenkinsfile |
| [#2900](https://github.com/apache/cassandra/pull/2900) | — | ~855d | Fix DiskSpaceMetricsTest.testFlushSize |
| [#3133](https://github.com/apache/cassandra/pull/3133) | [CASSANDRA-19429](https://issues.apache.org/jira/browse/CASSANDRA-19429) | 776d | Remove capacity calls when unnecessary (4.1) |
| [#3155](https://github.com/apache/cassandra/pull/3155) | [CASSANDRA-19007](https://issues.apache.org/jira/browse/CASSANDRA-19007) | ~760d | Experimental fix for 19007 |
| [#3169](https://github.com/apache/cassandra/pull/3169) | — | ~755d | Provide tests for types compatibility |
| [#3248](https://github.com/apache/cassandra/pull/3248) | [CASSANDRA-19556](https://issues.apache.org/jira/browse/CASSANDRA-19556) | ~720d | Guardrail to block DDL/DCL queries (4.1) |
| [#3283](https://github.com/apache/cassandra/pull/3283) | [CASSANDRA-19590](https://issues.apache.org/jira/browse/CASSANDRA-19590) | ~710d | Fix dropped legacy cell column handling |
| [#3298](https://github.com/apache/cassandra/pull/3298) | [CASSANDRA-19556](https://issues.apache.org/jira/browse/CASSANDRA-19556) | ~715d | DDL and DCL guardrails (5.0) |
| [#3323](https://github.com/apache/cassandra/pull/3323) | [CASSANDRA-19624](https://issues.apache.org/jira/browse/CASSANDRA-19624) | ~695d | casInternal RowIterator leak (3.0) |
| [#3324](https://github.com/apache/cassandra/pull/3324) | [CASSANDRA-19624](https://issues.apache.org/jira/browse/CASSANDRA-19624) | ~695d | casInternal RowIterator leak (3.11) |
| [#3325](https://github.com/apache/cassandra/pull/3325) | [CASSANDRA-19624](https://issues.apache.org/jira/browse/CASSANDRA-19624) | ~695d | casInternal RowIterator leak (4.0) |
| [#3326](https://github.com/apache/cassandra/pull/3326) | [CASSANDRA-19624](https://issues.apache.org/jira/browse/CASSANDRA-19624) | ~695d | casInternal RowIterator leak (4.1) |
| [#3327](https://github.com/apache/cassandra/pull/3327) | [CASSANDRA-19624](https://issues.apache.org/jira/browse/CASSANDRA-19624) | ~695d | casInternal RowIterator leak (5.0) |
| [#3423](https://github.com/apache/cassandra/pull/3423) | [CASSANDRA-19511](https://issues.apache.org/jira/browse/CASSANDRA-19511) | ~665d | Updated installation instructions |
| [#3455](https://github.com/apache/cassandra/pull/3455) | [CASSANDRA-19750](https://issues.apache.org/jira/browse/CASSANDRA-19750) | ~650d | Include missing cassandra-jaas.config file |
| [#3505](https://github.com/apache/cassandra/pull/3505) | [CASSANDRA-19429](https://issues.apache.org/jira/browse/CASSANDRA-19429) | ~635d | Wrap capacity calls (4.0) |
| [#3583](https://github.com/apache/cassandra/pull/3583) | [CASSANDRA-19961](https://issues.apache.org/jira/browse/CASSANDRA-19961) | ~600d | Fix SAI IndexInputLeakDetector (5.0) |
| [#3644](https://github.com/apache/cassandra/pull/3644) | [CASSANDRA-19429](https://issues.apache.org/jira/browse/CASSANDRA-19429) | ~575d | Avoid getCapacity for SSTableReader |
| [#3647](https://github.com/apache/cassandra/pull/3647) | [CASSANDRA-18526](https://issues.apache.org/jira/browse/CASSANDRA-18526) | ~575d | Fix encoding of Tuples with String types |
| [#3972](https://github.com/apache/cassandra/pull/3972) | [CASSANDRA-19580](https://issues.apache.org/jira/browse/CASSANDRA-19580) | ~490d | Fix replacing node stuck in hibernation (trunk) |
| [#3973](https://github.com/apache/cassandra/pull/3973) | [CASSANDRA-19580](https://issues.apache.org/jira/browse/CASSANDRA-19580) | ~490d | Fix replacing node stuck in hibernation (5.0) |
| [#3974](https://github.com/apache/cassandra/pull/3974) | [CASSANDRA-19580](https://issues.apache.org/jira/browse/CASSANDRA-19580) | ~490d | Fix replacing node stuck in hibernation (4.1) |

---

## Close Comments

**For JIRA-resolved stale PRs:**
```
Closing as [JIRA-ID](https://issues.apache.org/jira/browse/JIRA-ID) has been resolved as Fixed — if this PR contains changes not captured in the merged fix, please reopen.
```

**For Won't Fix / Abandoned JIRAs:**
```
Closing as the linked JIRA has been resolved as [Won't Fix / Abandoned]. If you believe this work is still valuable, please open a new JIRA with updated context.
```

**For no-ticket stale PRs:**
```
Closing as this PR has had no activity for 2+ years and has no associated JIRA ticket. If this work is still relevant, please open a JIRA ticket and resubmit with a rebase against the current branch.
```

**For stale-open pings:**
```
This PR has been open for 2+ years with no recent activity. Could you rebase against the current branch and confirm this is still relevant? If there's no response within 30 days, we will close this PR to keep the queue manageable.
```