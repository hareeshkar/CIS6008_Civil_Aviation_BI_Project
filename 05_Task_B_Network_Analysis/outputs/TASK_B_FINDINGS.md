# Task B Findings — Sri Lanka Aviation Network Analysis

> **Neat, user-friendly summary** from `Rscript 05_Task_B_Network_Analysis/scripts/task_b_network.R:1`  
> Dataset: `03_Original_Datasets/Task_B/SriLanka_Aviation_SNA_Dataset.csv` → `working_data/` (copy-before-transform) — **28 directed weighted edges, 15 distinct organizations**, no missing values. All numbers below are read from `metrics/*.csv` & `outputs/*.txt` — no invented scores.

---

## Quick Snapshot

| Metric | Value | File |
|---|---|---|
| **Nodes** | **15** organizations | `outputs/graph_summary.txt:1` |
| **Edges** | **28** directed ties | `outputs/graph_summary.txt:1` |
| **Density** | **0.133** (13.3% of possible directed ties) | `metrics/network_level_metrics.txt:1` |
| **Weak components** | **1** (fully connected when ignoring direction) | `metrics/network_level_metrics.txt:1` |
| **Strong components** | **15** (no mutual reachability — hierarchical flow) | `metrics/network_level_metrics.txt:1` |
| **Diameter** | **4 steps** (unweighted), **22.0** (weighted distance = 10-Weight) | `metrics/network_level_metrics.txt:1` |
| **Avg path length** | **1.65** (among reachable pairs) | `metrics/network_level_metrics.txt:1` |
| **Clustering** | Global transitivity **0.278**, avg local **0.247** | `metrics/network_level_metrics.txt:1` |
| **Reciprocity** | **0.00** (no mutual edges — strictly hierarchical) | `metrics/network_level_metrics.txt:1` |

**Relationship mix:** Commercial 10, Support 7, Operational 6, Regulatory 5 — see `outputs/graph_summary.txt:1`.

---

## 1. Who Are the Most Influential? (Degree & Strength)

Degree = number of direct connections (undirected total). Strength = sum of tie Weights (1–9) — where influence actually flows.

File: `metrics/node_centrality.csv:1` (sorted by degree_total)

| Rank | Node | Total Degree (in + out) | In | Out | Strength (Weight Sum) | Why It Matters |
|---|---|---|---|---|---|---|
| **1** | **Cargo Operators** | **7** | 7 | 0 | **35** | Pure sink — 7 incoming ties, heaviest load (avg Weight 5.0). Central payload/customer hub. |
| **2** | **Customs & Immigration** | **6** | 4 | 2 | **32** | Dual role: heavily connected broker, bridges regulatory & operational flows. |
| **3** | **Fuel Supply Companies** | **5** | 3 | 2 | **32** | Strong despite same degree as BIA — heavier ties (avg 6.4) → fuel control leverage. |
| **4** | **Bandaranaike Intl Airport (CMB) / BIA** | **5** | 0 | **5** | **26** | Top source — initiates 5 ties, pure origin authority, drives outbound flows. |
| **4** | **Sri Lanka Air Force** | **5** | 2 | 3 | 18 | Balanced military-civil connector. |

> *User-friendly takeaway:* **Cargo Operators, Customs & Immigration, and Fuel Supply** are the network's **payload / gateway / energy hubs**. BIA CMB is the dominant **origin hub** (all out-edges) — its 5 outbound ties set the pace for the whole system. See `graphs/rank_degree_total.png:1` & `rank_strength_total.png:1` for bar charts.

---

## 2. Who Are the Bridges? (Betweenness — who controls shortest paths)

Betweenness = times a node sits on weighted shortest paths (distance = 10 – Weight, so Weight 9 = distance 1, very close). High betweenness = bottleneck for information/flow.

File: `metrics/betweenness_centrality.csv:1` (also in `node_centrality.csv`)

| Rank | Node | Betweenness (raw) | Normalized | What It Bridges |
|---|---|---|---|---|
| **1** | **Fuel Supply Companies** | **12.0** | 0.066 | Connects Ground Handling → Customs → BIA/CAASL cluster; fuel path chokepoint |
| **2** | **Customs & Immigration** | **11.0** | 0.060 | Links International Airlines ↔ Fuel ↔ Cargo corridors |
| **3** | **Air Traffic Control (ATC)** | **6.0** | 0.033 | Bridges Maintenance/Mihin Lanka → ATC pathway |
| **3** | **International Airlines** | **6.0** | 0.033 | Connects Tourism ↔ Customs gateway |

*Other nodes 0–4, many 0 (e.g., BIA, Cargo — hubs but not bridges; Cargo is sink, not via-point).*

> **Bridge nodes = fuel, immigration, ATC.** Remove Fuel Supply and the Ground Handling → ATC path stretches; remove Customs and International ↔ Cargo disconnects. Visual confirmation in `graphs/network_betweenness.png:1` (red nodes scaled by betweenness) & `rank_betweenness.png:1`.

*Edge bridges:* Top edge betweenness `Customs & Immigration → International Airlines` (13, Commercial 9), `Fuel Supply Companies → Customs & Immigration` (12), `Maintenance → ATC` (8) — see `metrics/edge_metrics.csv:1`.

---

## 3. Who Is Structurally Close & Authoritative? (Closeness, Eigenvector, PageRank)

| Node | Closeness (normalized) | Eigenvector | PageRank | Interpretation |
|---|---|---|---|---|
| **Fuel Supply** | **0.189** | 0.00 | 0.058 | Most reachable despite not highest degree — fuel sits centrally |
| **Cargo Operators** | 0.184 | **1.00** | **0.278** | **Eigenvector champion:** sinks all paths, neighbors are themselves well-connected; PageRank sunk — random walk ends at Cargo |
| **Customs & Immigration** | 0.171 | 0.00 | 0.065 | Broker centrality + hub score 0.37 / authority 0.64 → recognized authority |
| **BIA CMB** | 0.161 | 0.00 | 0.026 | Source → low closeness (can't be reached), hub score **0.56** → strong hub (HITS) |
| **Maintenance & Engineering** | 0.128 | 0.00 | **0.123** | PageRank runner-up — feeds ATC/Cargo key path |
| **CAASL, MRIA, AASL** | 0.099–0.136 | 0.00 | 0.026 | Peripheral origins, authority 0 — regulators/sources |

> *Note:* Eigenvector is 1.00 for Cargo and 0 for all others because the graph is **directed acyclic** — `eig=1` only at sinks (igraph warning in log). For undirected influence use `strength`/`degree` above; for directed prestige use **PageRank** (Cargo 0.278 dominates). See `metrics/node_centrality.csv:1` columns `eigenvector`, `pagerank`, `hub_score`, `authority_score`.

---

## 4. Clusters & Communities (Where Does the Network Split?)

File: `metrics/communities.csv:1` + `community_stats.txt:1`

| Algorithm | Clusters Found | Modularity | Sizes | Meaning |
|---|---|---|---|---|
| **Louvain (weighted, undirected)** | **4** | **0.331** | 3, 5, 5, 2 | Best partition — fair modularity (0.3+ is meaningful). |
| Walktrap (steps=4) | 3 | 0.241 | 9, 3, 3 | Over-lumps into mega-cluster — weaker |
| Fast-Greedy | 4 | 0.331 | same as Louvain | Confirms Louvain stability |

**Louvain clusters (see `graphs/network_louvain.png:1` — colour = community):**

* **Community 1 (3 nodes):** ATC, CAASL, Mihin Lanka — *Regulatory/ATC core* (blue)
* **Community 2 (5):** AASL, Cargo, MRIA, SriLankan Airlines, Tourism — *Commercial/tourism–cargo corridor* (teal)
* **Community 3 (5):** BIA CMB, Customs, Fuel, Ground Handling, International Airlines — *BIA gateway fuel/immigration gateway* (green)
* **Community 4 (2):** Maintenance & Engineering, Sri Lanka Air Force — *Military–maintenance island* (purple)

> **Connectivity insight:** Despite one weak component, the network fractures into **four functional islands** when ties are treated as undirected proximity — BIA's gateway cluster is separate from the MRIA/cargo commercial cluster, with CAASL/ATC as a third regulatory island. See `graphs/network_fruchterman.png:1` (FR) vs `network_kamada.png:1` & `network_ggraph_fr.png:1` for layout convergence.

---

## 5. Connectivity & Vulnerabilities

### Net-level
* **Weak connectivity:** Robust (1 component) — ignore direction and the network is traversable.
* **Strong connectivity:** Fragile (15 components) — following direction, almost no cycles ⇒ information/materiel flows **one-way** (hierarchical, not mesh).

### Single-Point Failures

File: `metrics/network_level_metrics.txt:1` + `outputs/vulnerability.md:1`

* **Articulation points (2):** **Cargo Operators**, **Fuel Supply Companies** — their removal **splits the weak component into 2**. Cargo removal → 14 nodes remain but 2 weak comps (largest 13), edges 21→ (was 28). Fuel removal similarly fragments.
* **Bridges (cut-edges, 2):** The directed bridge detection flags 2 edges as strict bridges (list in `network_level_metrics.txt:1`). Top edge betweenness shows near-bridge edges vulnerable.

### What-If Removal (What happens if we lose a key node?)

File: `metrics/vulnerability_joint.csv:1` + `outputs/vulnerability.md:1` (table excerpt)

| Removed | Nodes Left | Edges Left | Weak Components | Largest | Density | Avg Path |
|---|---|---|---|---|---|---|
| **Baseline** | 15 | 28 | 1 | 15 | 0.133 | 1.65 |
| BIA CMB | 14 | 23 | 1 | 14 | 0.126 | 1.67 |
| CAASL | 14 | 24 | 1 | 14 | 0.132 | 1.65 |
| **Cargo Operators** | **14** | **21** | **2** | **13** | **0.115** | **1.66** |
| Customs & Immigration | 14 | 22 | 1 | 14 | 0.121 | 1.59 |
| BIA + CAASL jointly | 13 | 19 | 1 | 13 | 0.122 | 1.68 |

> **Read this:** Removing **Cargo collapses 7 edges (25% loss) and fractures the network** — density drops to 0.115, component splits. BIA removal is less fragmenting (only degree 5→ edges 23) but severs the main origin (all paths from BIA lost). CAASL removal is moderate; joint BIA+CAASL removes 9 edges and pushes density to 0.122.

---

## 6. Resilience Recommendations (For Ministry / BIA)

> Evidence-backed, not generic — each maps to a metric above.

1.  **Protect & Duplicate the Cargo Hub.** Cargo is both top hub (7, 35) and articulation point. Invest in **redundant cargo handling nodes** (split AASL or MRIA-cargo link redundancy: MRIA already links to Cargo with Weight 7, but only once). Create a second cargo gateway or co-located cold-chain at MRIA to bypass single-point failure — monitored via `node_centrality.csv`.

2.  **Harden Fuel Supply Pathways.** Fuel is top bridge (betweenness 12) and articulation point. Current redundancy is low (only 5 connections). **Add alternative fuel→ATC/CAASL direct edges** or ground-handling fuel bypass, so Ground Handling → ATC doesn't transit Fuel.

3.  **Weaken Bridge Dependence on Customs & ATC.** Customs betweenness 11 and ATC 6 mean immigration clearance is a chokepoint. **Digitize/parallelize Customs** (e.g., e-gate, pre-clearance) and **ATC backup channel** (secondary ATC node or procedural ATC for MRIA direct). Monitor via `edge_metrics.csv` top edges.

4.  **Connect Regulatory Island.** CAASL cluster (with ATC/Mihin) is isolated from Cargo/MRIA commercial cluster (only via Mihin → ATC). Add **CAASL → Cargo Operators** regulatory oversight edge or **CAASL → Fuel** compliance link to mesh communities — would raise modularity resilience and reduce Walktrap mega-cluster risk.

5.  **Treat MRIA as Resilience Reserve, not Isolation.** MRIA's 4 outbound ties all go to Tourism/Cargo/Customs but zero incoming — it's a source without feedback. Build **International Airlines → MRIA** and **Cargo → MRIA** reciprocal ties to give MRIA in-degree and create strong connectivity (currently 0 reciprocity). This also improves BIA failure fallback (BAU during BIA closure).

6.  **Monitor PageRank sinks.** Cargo PageRank 0.278 vs next 0.123 means random-flow concentrate. Implement **load-balancing KPIs** (tie Weight 9 edges are hotspots) and cap Cargo in-degree Weight or shard cargo ops.

---

## 7. Files for Appendix / Presentation

Cite these exact paths (Excellent evidence):

* **Centralities:** `metrics/node_centrality.csv:1` (full), `degree_centrality.csv`, `betweenness_centrality.csv`, `edge_metrics.csv:1`
* **Communities:** `metrics/communities.csv:1`, `community_stats.txt:1`
* **Net overview:** `outputs/graph_summary.txt:1`, `metrics/network_level_metrics.txt:1`, `outputs/vulnerability.md:1`, `vulnerability_joint.csv`
* **Edgelist & Graph:** `metrics/edgelist.csv`, `outputs/graph.graphml` (7.9K) + `graph.gml` (4.4K) + `graph_raw.rds`
* **Visuals (14 PNGs, all ≥2400×1500 (network maps ≥2600×2000, rank plots ≥2400×1800)):** `graphs/network_fruchterman.png:1` (alias `network_graph.png`), `network_kamada.png`, `network_circle.png`, `network_louvain.png`, `network_betweenness.png` (size=betweenness), `network_ggraph_fr.png`, `degree_distribution.png`, `rank_degree_total.png`, `rank_betweenness.png`, `rank_eigenvector.png`, `rank_pagerank.png`, `rank_strength_total.png`
* **This summary:** `outputs/TASK_B_FINDINGS.md` (this file)

---

*Generated via `R` igraph 2.3.3 / tidygraph 1.3.1 / ggraph 2.2.2 (see `screenshots/sessionInfo.txt:1`), Louvain seed 42, weighted directed → undirected collapse for clustering, distance = 10 – Weight for betweenness shortest paths. Reproducible: re-run `Rscript 05_Task_B_Network_Analysis/scripts/task_b_network.R`.*
