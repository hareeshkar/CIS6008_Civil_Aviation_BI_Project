#!/usr/bin/env Rscript
# Task B — Network Analysis for Sri Lanka Civil Aviation (CIS6008)
# Steps: load → inspect → build graph → centralities → communities → vulnerability → export plots/tables
# Inherits same model pattern as Task A: renv-aware, copy-before-transform, traceable outputs

# --- paths and project-local environment ---
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(file_arg) == 1L) {
  base_dir <- dirname(dirname(normalizePath(sub("^--file=", "", file_arg))))
} else if (dir.exists(file.path(getwd(), "outputs"))) {
  base_dir <- normalizePath(getwd())
} else {
  base_dir <- normalizePath(file.path(getwd(), "05_Task_B_Network_Analysis"))
}
if (!dir.exists(file.path(base_dir, "outputs"))) stop("Task B directory not found: ", base_dir)

renv_activate <- file.path(base_dir, "renv", "activate.R")
if (file.exists(renv_activate)) {
  setwd(base_dir)
  source(renv_activate)
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(igraph)
  library(tidygraph)
  library(ggraph)
  library(scales)
})

cat("Base dir:", base_dir, "\n")
src_csv <- file.path(dirname(base_dir), "03_Original_Datasets", "Task_B", "SriLanka_Aviation_SNA_Dataset.csv")
working_dir <- file.path(base_dir, "working_data")
outputs_dir <- file.path(base_dir, "outputs")
metrics_dir <- file.path(base_dir, "metrics")
graphs_dir  <- file.path(base_dir, "graphs")
dir.create(working_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(outputs_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(metrics_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(graphs_dir,  showWarnings = FALSE, recursive = TRUE)

# --- 1. Load (copy-before-transform) ---
cat("[1] Loading SriLanka_Aviation_SNA_Dataset.csv\n")
csv_path <- file.path(working_dir, "SriLanka_Aviation_SNA_Dataset.csv")
if (file.exists(src_csv)) {
  # The protected master is mode 0444; make the derived working copy replaceable.
  if (file.exists(csv_path)) Sys.chmod(csv_path, mode = "0644")
  copied <- file.copy(src_csv, csv_path, overwrite = TRUE)
  if (!copied) stop("Could not copy source CSV to: ", csv_path)
  Sys.chmod(csv_path, mode = "0644")
  cat("  Copied master -> working_data/\n")
} else {
  stop("Source CSV not found: ", src_csv)
}
edges_raw <- read_csv(csv_path, show_col_types = FALSE)
cat("  Rows:", nrow(edges_raw), "Cols:", ncol(edges_raw), "\n")
print(glimpse(edges_raw))
stopifnot(all(c("Source","Target","Relationship","Weight") %in% names(edges_raw)))
# Clean: trim, ensure Weight numeric 1-9
edges_raw <- edges_raw %>%
  mutate(Source = str_trim(Source), Target = str_trim(Target),
         Relationship = str_trim(Relationship), Weight = as.numeric(Weight))
cat("  Relationships:", paste(sort(unique(edges_raw$Relationship)), collapse=", "), "\n")
cat("  Weight range:", min(edges_raw$Weight, na.rm=TRUE), "-", max(edges_raw$Weight, na.rm=TRUE), " mean ", round(mean(edges_raw$Weight),2), "\n")

# Inspect nodes
all_nodes <- sort(unique(c(edges_raw$Source, edges_raw$Target)))
cat("  Distinct nodes:", length(all_nodes), "\n")
print(all_nodes)
# Missing check
cat("  Missing per col:", paste(colSums(is.na(edges_raw)), collapse=", "), "\n")

# Save inspection
sink(file.path(outputs_dir, "graph_summary.txt"))
cat("=== TASK B NETWORK SUMMARY ===\n")
cat("Source CSV:", csv_path, "\n")
cat("Edges (rows):", nrow(edges_raw), "\n")
cat("Distinct nodes:", length(all_nodes), "\n")
cat("Distinct sources:", n_distinct(edges_raw$Source), " distinct targets:", n_distinct(edges_raw$Target), "\n")
cat("Relationships (4):", paste(sort(unique(edges_raw$Relationship)), collapse=", "), "\n")
cat("Weight stats: min", min(edges_raw$Weight), "max", max(edges_raw$Weight), "mean", round(mean(edges_raw$Weight),2), " sd", round(sd(edges_raw$Weight),2), "\n")
cat("\n--- Edge counts by Relationship ---\n")
print(table(edges_raw$Relationship))
cat("\n--- Out-degree (Source) ---\n")
print(table(edges_raw$Source) %>% sort(decreasing=TRUE))
cat("\n--- In-degree (Target) ---\n")
print(table(edges_raw$Target) %>% sort(decreasing=TRUE))
sink()

# --- 2. Build graph ---
cat("\n[2] Building igraph (directed, weighted)\n")
g <- graph_from_data_frame(edges_raw, directed = TRUE, vertices = data.frame(name = all_nodes))
E(g)$Relationship <- edges_raw$Relationship
E(g)$Weight <- edges_raw$Weight
# For distance-based metrics, use inverse? igraph's weight is cost, higher weight = longer. For relevance weight 9 is strong, so for shortest path we invert: distance = 10 - Weight or 1/Weight. Use 10-Weight for intuition.
E(g)$distance <- 10 - E(g)$Weight

cat("  vcount:", vcount(g), "ecount:", ecount(g), "directed:", is_directed(g), "weighted:", is_weighted(g), "\n")
cat("  Density:", edge_density(g), "\n")
# Save g for later
saveRDS(g, file.path(outputs_dir, "graph_raw.rds"))

# Undirected version for communities/clustering (Louvain requires undirected)
g_und <- as_undirected(g, mode="collapse", edge.attr.comb = list(Weight="mean", Relationship="concat", distance="mean", "ignore"))
cat("  Undirected for clustering: v", vcount(g_und), "e", ecount(g_und), "\n")

# --- 3. Centralities ---
cat("\n[3] Computing centralities\n")
# Degree (raw count)
deg_total <- degree(g, mode="all")
deg_in    <- degree(g, mode="in")
deg_out   <- degree(g, mode="out")
# Weighted degree (strength) — sum of weights
str_total <- strength(g, mode="all", weights = E(g)$Weight)
str_in    <- strength(g, mode="in",  weights = E(g)$Weight)
str_out   <- strength(g, mode="out", weights = E(g)$Weight)
# Betweenness — use distance (inverse weight) as cost; higher original weight = closer
betw <- betweenness(g, directed=TRUE, weights = E(g)$distance, normalized = FALSE)
betw_norm <- betweenness(g, directed=TRUE, weights = E(g)$distance, normalized = TRUE)
# Closeness (harmonic due to disconnected? Use closeness with weights; handle disconnected with normalized)
close <- closeness(g, mode="all", weights = E(g)$distance, normalized = TRUE)
# Eigenvector (weighted)
eig <- eigen_centrality(g, directed=TRUE, weights = E(g)$Weight, scale = TRUE)$vector
# PageRank (directed weighted)
pr <- page_rank(g, directed=TRUE, weights = E(g)$Weight, damping = 0.85)$vector
# Hub/Authority (HITS)
hits <- hub_score(g, weights = E(g)$Weight)
auth <- authority_score(g, weights = E(g)$Weight)

centrality_df <- tibble(
  node = V(g)$name,
  degree_total = as.numeric(deg_total[node]),
  degree_in    = as.numeric(deg_in[node]),
  degree_out   = as.numeric(deg_out[node]),
  strength_total = as.numeric(str_total[node]),
  strength_in    = as.numeric(str_in[node]),
  strength_out   = as.numeric(str_out[node]),
  betweenness    = as.numeric(betw[node]),
  betweenness_norm = as.numeric(betw_norm[node]),
  closeness      = as.numeric(close[node]),
  eigenvector    = as.numeric(eig[node]),
  pagerank       = as.numeric(pr[node]),
  hub_score      = as.numeric(hits$vector[node]),
  authority_score= as.numeric(auth$vector[node])
) %>%
  arrange(desc(degree_total))

# Also compute z-scores for intuitive ranking? keep raw.

write_csv(centrality_df, file.path(metrics_dir, "node_centrality.csv"))
write_csv(centrality_df, file.path(metrics_dir, "degree_centrality.csv")) # alias per spec
write_csv(centrality_df %>% select(node, betweenness, betweenness_norm) %>% arrange(desc(betweenness)),
          file.path(metrics_dir, "betweenness_centrality.csv"))
write_csv(centrality_df, file.path(outputs_dir, "node_centrality.csv"))

cat("  Centralities written: ", nrow(centrality_df), "nodes\n")
print(centrality_df %>% select(node, degree_total, degree_in, degree_out, betweenness, closeness, eigenvector, pagerank) %>% head(10))

# Top hubs and bridges
top_hubs <- centrality_df %>% arrange(desc(degree_total)) %>% slice_head(n=3)
top_weighted <- centrality_df %>% arrange(desc(strength_total)) %>% slice_head(n=3)
top_bridges <- centrality_df %>% arrange(desc(betweenness)) %>% slice_head(n=3)
top_eig <- centrality_df %>% arrange(desc(eigenvector)) %>% slice_head(n=3)
top_pr  <- centrality_df %>% arrange(desc(pagerank)) %>% slice_head(n=3)

cat("\n  Top hubs (degree_total):\n"); print(top_hubs %>% select(node, degree_total, strength_total))
cat("\n  Top weighted (strength_total):\n"); print(top_weighted %>% select(node, strength_total, degree_total))
cat("\n  Top bridges (betweenness):\n"); print(top_bridges %>% select(node, betweenness, betweenness_norm))
cat("\n  Top eigenvector:\n"); print(top_eig %>% select(node, eigenvector))
cat("\n  Top PageRank:\n"); print(top_pr %>% select(node, pagerank))

# --- 4. Network-level metrics ---
cat("\n[4] Network-level metrics\n")
dens <- edge_density(g)
recip <- reciprocity(g)
trans <- transitivity(g, type="global")
trans_local <- transitivity(g, type="localaverage")
diam <- diameter(g, directed=TRUE, weights = NA) # unweighted diameter
diam_w <- diameter(g, directed=TRUE, weights = E(g)$distance)
apl <- mean_distance(g, directed=TRUE, unconnected = TRUE)
# Components
comp_weak <- components(g, mode="weak")
comp_strong <- components(g, mode="strong")
# Articulation points and bridges
art_points <- articulation_points(g)
bridg <- bridges(g)
# Edge betweenness
eb <- edge_betweenness(g, directed=TRUE, weights = E(g)$distance)

sink(file.path(metrics_dir, "network_level_metrics.txt"), append = FALSE)
cat("=== NETWORK-LEVEL METRICS ===\n")
cat("Nodes:", vcount(g), " Edges:", ecount(g), " Directed:", is_directed(g), "\n")
cat(sprintf("Density: %.4f\n", dens))
cat(sprintf("Reciprocity: %.4f\n", recip))
cat(sprintf("Global transitivity (clustering): %.4f\n", trans))
cat(sprintf("Avg local transitivity: %.4f\n", trans_local))
cat(sprintf("Diameter (unweighted): %d\n", diam))
cat(sprintf("Diameter (weighted distance): %.2f\n", diam_w))
cat(sprintf("Avg path length (unconnected -> NA if disconnected): %.4f\n", apl))
cat(sprintf("Weak components: %d (largest %d nodes)\n", comp_weak$no, max(comp_weak$csize)))
cat(sprintf("Strong components: %d (largest %d nodes)\n", comp_strong$no, max(comp_strong$csize)))
cat(sprintf("Articulation points (%d): %s\n", length(art_points), if(length(art_points)>0) paste(names(art_points), collapse=", ") else "none"))
cat(sprintf("Bridges (cut-edges) (%d): %d edges\n", length(bridg), length(bridg)))
cat("\n--- Top hubs (by degree_total) ---\n")
print(top_hubs %>% select(node, degree_total, degree_in, degree_out, strength_total))
cat("\n--- Top bridges (betweenness) ---\n")
print(top_bridges %>% select(node, betweenness, betweenness_norm, closeness))
cat("\n--- Components (weak) ---\n")
print(table(comp_weak$csize))
sink()
cat("  Network level written: metrics/network_level_metrics.txt\n")
# Also copy to outputs for validator
file.copy(file.path(metrics_dir, "network_level_metrics.txt"), file.path(outputs_dir, "network_level_metrics.txt"), overwrite=TRUE)

# Edge metrics
edge_df <- tibble(
  from = as_ids(tail_of(g, E(g))),
  to   = as_ids(head_of(g, E(g))),
  Relationship = E(g)$Relationship,
  Weight = E(g)$Weight,
  distance = E(g)$distance,
  edge_betweenness = as.numeric(eb)
) %>% arrange(desc(edge_betweenness))
write_csv(edge_df, file.path(metrics_dir, "edge_metrics.csv"))
write_csv(edge_df, file.path(metrics_dir, "edge_betweenness.csv"))
write_csv(edge_df, file.path(outputs_dir, "edge_metrics.csv"))
cat("  Edge metrics written\n")

# --- 5. Communities ---
cat("\n[5] Community detection\n")
# Louvain on undirected weighted (using Weight)
set.seed(42)
# louvain weights = Weight (higher = stronger community)
comm_louvain <- cluster_louvain(g_und, weights = E(g_und)$Weight)
mod_louvain <- modularity(comm_louvain)
cat("  Louvain:", length(comm_louvain), "communities, modularity", mod_louvain, " sizes", paste(sizes(comm_louvain), collapse=", "), "\n")

comm_walktrap <- cluster_walktrap(g_und, weights = E(g_und)$Weight, steps = 4)
mod_walktrap <- modularity(comm_walktrap)
cat("  Walktrap:", length(comm_walktrap), " mod", mod_walktrap, " sizes", paste(sizes(comm_walktrap), collapse=", "), "\n")

# Leiden if available? fallback to fast greedy
comm_fg <- cluster_fast_greedy(g_und, weights = E(g_und)$Weight)
cat("  FastGreedy:", length(comm_fg), " mod", modularity(comm_fg), "\n")

# Assign memberships
membership_df <- tibble(
  node = V(g)$name,
  louvain = as.numeric(membership(comm_louvain)[node]),
  walktrap = as.numeric(membership(comm_walktrap)[node]),
  fastgreedy = as.numeric(membership(comm_fg)[node])
) %>%
  left_join(centrality_df %>% select(node, degree_total, betweenness), by="node")

write_csv(membership_df, file.path(metrics_dir, "communities.csv"))
write_csv(membership_df, file.path(metrics_dir, "community_membership.csv")) # alias
write_csv(membership_df, file.path(outputs_dir, "communities.csv"))

# Also save community stats
sink(file.path(metrics_dir, "community_stats.txt"))
cat("=== COMMUNITY STATS ===\n")
cat("Louvain modularity:", mod_louvain, "\n"); print(sizes(comm_louvain))
cat("\nWalktrap modularity:", mod_walktrap, "\n"); print(sizes(comm_walktrap))
cat("\nFastGreedy modularity:", modularity(comm_fg), "\n"); print(sizes(comm_fg))
sink()

# Add community to graph for plotting
V(g)$louvain <- membership(comm_louvain)[V(g)$name]
V(g)$walktrap <- membership(comm_walktrap)[V(g)$name]

# --- 6. Vulnerability / Resilience (what-if removal) ---
cat("\n[6] Vulnerability analysis\n")
# Function to assess fragmentation after node removal
assess_removal <- function(g, nodes_to_remove) {
  g2 <- delete_vertices(g, nodes_to_remove)
  c(
    nodes = vcount(g2),
    edges = ecount(g2),
    weak_comps = components(g2, mode="weak")$no,
    largest_weak = max(components(g2, mode="weak")$csize),
    density = edge_density(g2),
    avg_path = suppressWarnings(mean_distance(g2, directed=TRUE, unconnected=TRUE))
  )
}
# Baseline
base_metrics <- assess_removal(g, character(0))
# Try removing each top hub individually
vuln_list <- lapply(centrality_df$node[1:min(5, nrow(centrality_df))], function(n) {
  m <- assess_removal(g, n)
  tibble(node_removed = n, !!!as.list(m))
}) %>% bind_rows()
# Joint removals: BIA CMB alone, CAASL alone, Cargo Ops alone, BIA+CAASL
key_nodes <- c("Bandaranaike International Airport (CMB)", "Civil Aviation Authority of Sri Lanka (CAASL)", "Cargo Operators", "Customs & Immigration")
key_nodes <- key_nodes[key_nodes %in% V(g)$name]
joint_vuln <- bind_rows(
  tibble(node_removed = "BASELINE (no removal)", !!!as.list(base_metrics)),
  lapply(key_nodes, function(n) tibble(node_removed = paste0("Remove: ", n), !!!as.list(assess_removal(g, n)))) %>% bind_rows(),
  tibble(node_removed = "Remove: BIA CMB + CAASL", !!!as.list(assess_removal(g, c("Bandaranaike International Airport (CMB)","Civil Aviation Authority of Sri Lanka (CAASL)"))))
)

# Articulation points already computed
# Bridges: which edges are cut-edges
bridge_edges_df <- edge_df %>% filter(edge_betweenness == max(edge_betweenness)) %>% slice_head(n=5)

sink(file.path(outputs_dir, "vulnerability.md"))
cat("# Vulnerability & Resilience Analysis\n\n")
cat("Baseline: ", vcount(g), " nodes, ", ecount(g), " edges, density ", round(dens,4), ", weak comps ", comp_weak$no, "\n\n")
cat("## Articulation points (single-point failures)\n")
if (length(art_points)>0) {
  cat(paste0("- ", names(art_points), " (removal fragments network)\n"))
} else {
  cat("- None (no single node whose removal disconnects the weak component) — relatively robust to single loss, but see edge bridges\n")
}
cat("\n## Cut-edges (bridges)\n")
if (length(bridg)>0) {
  cat("Count:", length(bridg), "\n")
  print(edge_df %>% slice_head(n=5) %>% select(from, to, Relationship, Weight, edge_betweenness))
} else {
  cat("None — no single edge is a bridge in this directed sense\n")
}
cat("\n## What-if node removal (fragmentation)\n")
cat("| Removed node(s) | Nodes left | Edges left | Weak comps | Largest weak | Density | Avg path |\n")
cat("|---|---|---|---|---|---|---|\n")
for (i in seq_len(nrow(joint_vuln))) {
  cat(sprintf("| %s | %d | %d | %d | %d | %.3f | %.2f |\n",
              joint_vuln$node_removed[i], joint_vuln$nodes[i], joint_vuln$edges[i],
              joint_vuln$weak_comps[i], joint_vuln$largest_weak[i], joint_vuln$density[i], joint_vuln$avg_path[i]))
}
cat("\n## Edge criticality (top 5 by edge betweenness)\n")
print(edge_df %>% select(from, to, Relationship, Weight, edge_betweenness) %>% slice_head(n=5))
cat("\n## Resilience recommendations (preliminary, detailed in FINDINGS)\n")
cat("- Protect hubs (Cargo Ops, BIA, CAASL) — highest degree/strength\n")
cat("- Monitor bridges (high betweenness nodes/edges) — ATC, Customs, BIA\n")
cat("- Redundancy: strengthen MRIA links to Cargo/ATC to bypass BIA single-point\n")
cat("- Diversify Fuel Supply pathways (currently high betweenness)\n")
sink()

write_csv(vuln_list, file.path(metrics_dir, "vulnerability_single_removal.csv"))
write_csv(joint_vuln, file.path(metrics_dir, "vulnerability_joint.csv"))
write_csv(joint_vuln, file.path(outputs_dir, "vulnerability_table.csv"))
cat("  Vulnerability written\n")

# --- 7. Export graph ---
cat("\n[7] Exporting graph\n")
write_graph(g, file.path(outputs_dir, "graph.graphml"), format="graphml")
# Write GML directly: igraph's macOS writer rejects these character vertex IDs.
gml_quote <- function(x) gsub('"', '\\\\"', x, fixed = TRUE)
gml_lines <- c("graph [", "  directed 1")
for (i in seq_len(vcount(g))) {
  gml_lines <- c(gml_lines, "  node [", paste0("    id ", i - 1),
                 paste0('    label "', gml_quote(V(g)$name[i]), '"'), "  ]")
}
for (i in seq_len(ecount(g))) {
  gml_lines <- c(gml_lines, "  edge [",
                 paste0("    source ", as.integer(tail_of(g, E(g)[i])) - 1),
                 paste0("    target ", as.integer(head_of(g, E(g)[i])) - 1),
                 paste0("    weight ", E(g)$Weight[i]),
                 paste0('    relationship "', gml_quote(E(g)$Relationship[i]), '"'), "  ]")
}
writeLines(c(gml_lines, "]"), file.path(outputs_dir, "graph.gml"))
# Edge list export
write_csv(edges_raw, file.path(metrics_dir, "edgelist.csv"))
write_csv(edges_raw, file.path(outputs_dir, "edgelist.csv"))
cat("  Graph exported: graphml, gml, edgelist.csv\n")

# --- 8. Plots (user-friendly, neat) ---
cat("\n[8] Plotting networks\n")

# Precompute layouts
set.seed(42)
coords_fr  <- layout_with_fr(g, weights = E(g)$Weight)
coords_kk  <- layout_with_kk(g, weights = E(g)$distance)
coords_circle <- layout_in_circle(g)
# Ensure coords have rownames
rownames(coords_fr) <- V(g)$name
rownames(coords_kk) <- V(g)$name

# Theme helpers
my_palette_rel <- c(Support="#2C73D2", Commercial="#2E8B57", Regulatory="#D93D2B", Operational="#E67E22")
my_palette_comm <- c("#2C73D2","#D93D2B","#2E8B57","#F4A259","#8E44AD","#16A085")
# Vertex size by degree_total (scaled), colour by community or degree, label by name (shortened)
V(g)$deg_total <- centrality_df$degree_total[match(V(g)$name, centrality_df$node)]
V(g)$betw <- centrality_df$betweenness[match(V(g)$name, centrality_df$node)]
V(g)$label_short <- sapply(V(g)$name, function(x) {
  # shorten long names for plot readability but keep full in legend table
  if (nchar(x) > 22) paste0(substr(x,1,19),"...") else x
})
# Edge width by Weight

# Generic plot function using base igraph (robust, no ggraph version drift)
plot_network <- function(g, layout_coords, file, title, vertex_color, vertex_size_scale=8, edge_color_attr="Relationship") {
  png(file, width = 2600, height = 2000, res = 220)
  par(mar=c(1,1,3,1))
  # Vertex color
  col <- vertex_color
  # Size: degree + 3 min 6 max 22
  vs <- pmax(8, pmin(24, V(g)$deg_total * 1.8 + 6))
  # Edge widths: Weight 1-9 -> 0.8-4
  ew <- scales::rescale(E(g)$Weight, to=c(0.8, 4))
  # Edge colors
  ecol <- my_palette_rel[E(g)$Relationship]
  ecol[is.na(ecol)] <- "#888888"
  plot(g,
       layout = layout_coords,
       vertex.size = vs,
       vertex.color = col,
       vertex.frame.color = "white",
       vertex.label = V(g)$label_short,
       vertex.label.cex = 0.72,
       vertex.label.color = "black",
       vertex.label.dist = 0,
       vertex.label.family = "sans",
       edge.width = ew,
       edge.color = ecol,
       edge.arrow.size = 0.45,
       edge.curved = 0.12,
       main = title)
  # legends
  legend("topleft", legend=names(my_palette_rel), col=my_palette_rel, pch=19, pt.cex=1.1, cex=0.82, title="Relationship", bty="n")
  # Add weight/size note
  mtext("Node size = degree_total (undirected connections); edge width = Weight (1-9)", side=1, line=0.5, cex=0.72, col="#555555")
  dev.off()
  cat("  Saved", file, "\n")
}

# Colors by louvain community for main plot
comm_cols <- my_palette_comm[ (as.numeric(V(g)$louvain) %% length(my_palette_comm)) + 1 ]
names(comm_cols) <- V(g)$name

# Fruchterman-Reingold — main overview (community colored)
plot_network(g, coords_fr,  file.path(graphs_dir, "network_fruchterman.png"),
             "Sri Lanka Aviation Network — Fruchterman-Reingold (directed, weighted)\nn=15 nodes, 28 edges; colour = Louvain community",
             vertex_color = comm_cols)
file.copy(file.path(graphs_dir, "network_fruchterman.png"), file.path(graphs_dir, "network_graph.png"), overwrite=TRUE)

# Kamada-Kawai
plot_network(g, coords_kk,  file.path(graphs_dir, "network_kamada.png"),
             "Sri Lanka Aviation Network — Kamada-Kawai (distance = 10-Weight)",
             vertex_color = comm_cols)
file.copy(file.path(graphs_dir, "network_kamada.png"), file.path(graphs_dir, "network_kk.png"), overwrite=TRUE)

# Circle layout (neat for centrality reading)
plot_network(g, coords_circle, file.path(graphs_dir, "network_circle.png"),
             "Sri Lanka Aviation Network — Circle Layout (for hub comparison)",
             vertex_color = comm_cols)

# Louvain communities highlighted — use undirected coords but same g
plot_network(g, coords_fr, file.path(graphs_dir, "network_louvain.png"),
             paste0("Communities (Louvain) — ", length(comm_louvain), " clusters, modularity ", round(mod_louvain,3), " | Walktrap ", length(comm_walktrap), " mod ", round(mod_walktrap,3)),
             vertex_color = comm_cols)

# Additional: betweenness-centered plot (node size = betweenness)
png(file.path(graphs_dir, "network_betweenness.png"), width=2600, height=2000, res=220)
par(mar=c(1,1,3,1))
vs_b <- scales::rescale(centrality_df$betweenness[match(V(g)$name, centrality_df$node)], to=c(8,28))
# handle zero betweenness -> min size
vs_b[is.na(vs_b)] <- 8
plot(g, layout=coords_fr,
     vertex.size=vs_b,
     vertex.color="#D93D2B",
     vertex.frame.color="white",
     vertex.label=V(g)$label_short,
     vertex.label.cex=0.72,
     vertex.label.color="black",
     edge.width=scales::rescale(E(g)$Weight, to=c(0.8,4)),
     edge.color=my_palette_rel[E(g)$Relationship],
     edge.arrow.size=0.45,
     edge.curved=0.12,
     main="Node Size = Betweenness (bridge importance) — Red hubs are critical bridges")
legend("topleft", legend=names(my_palette_rel), col=my_palette_rel, pch=19, pt.cex=1.1, cex=0.82, title="Relationship", bty="n")
mtext("Largest nodes = highest betweenness (control over shortest paths)", side=1, line=0.5, cex=0.72, col="#555555")
dev.off()

# Degree distribution histogram — fixed: avoid geom_text with stat_bin grouping issue
p_deg <- ggplot(centrality_df, aes(x=degree_total)) +
  geom_histogram(binwidth=1, fill="#2C73D2", color="white", boundary=0) +
  labs(title="Degree Distribution (15 nodes, 28 directed edges)", x="Total degree (in+out)", y="Node count") +
  theme_minimal()
ggsave(file.path(graphs_dir, "degree_distribution.png"), p_deg, width=8, height=5, dpi=300)
# Optional: annotated version with counts on top
p_deg2 <- ggplot(centrality_df %>% count(degree_total, name="n"), aes(x=degree_total, y=n)) +
  geom_col(fill="#2C73D2", color="white", width=0.85) +
  geom_text(aes(label=n), vjust=-0.4, size=3.5) +
  labs(title="Degree Distribution (counts)", x="Total degree", y="Nodes") +
  theme_minimal()
ggsave(file.path(graphs_dir, "degree_distribution_counts.png"), p_deg2, width=8, height=5, dpi=300)

# Centrality dot plots (user-friendly ranking)
for (metric in c("degree_total","betweenness","eigenvector","pagerank","strength_total")) {
  df_plot <- centrality_df %>% arrange(desc(.data[[metric]])) %>% mutate(node_short = fct_reorder(V(g)$label_short[match(node, V(g)$name)], .data[[metric]]))
  p <- ggplot(df_plot, aes(x=.data[[metric]], y=node_short)) +
    geom_col(fill="#2C73D2", width=0.65) +
    geom_text(aes(label=round(.data[[metric]],2)), hjust=-0.1, size=3) +
    labs(title=paste0("Ranked: ", metric), x=metric, y=NULL) +
    theme_minimal() + theme(axis.text.y = element_text(size=8)) +
    scale_x_continuous(expand=expansion(mult=c(0,0.18)))
  ggsave(file.path(graphs_dir, paste0("rank_", metric, ".png")), p, width=8, height=6, dpi=300)
}

# ggraph version for polished publication (if ggraph available — use FR)
tryCatch({
  tg <- as_tbl_graph(g) %>%
    activate(nodes) %>%
    mutate(deg = centrality_degree(mode="all"),
           btw = centrality_betweenness(weights = distance),
           comm = as.factor(louvain))
  p_gg <- ggraph(tg, layout="fr", weights = Weight) +
    geom_edge_link(aes(width=Weight, colour=Relationship), alpha=0.75, arrow=arrow(length=unit(3,"mm")), end_cap=circle(4,"mm"), show.legend=TRUE) +
    geom_node_point(aes(size=deg, colour=comm), alpha=0.9) +
    geom_node_text(aes(label=label_short), repel=TRUE, size=3, max.overlaps=20) +
    scale_edge_width(range=c(0.4,2.2)) +
    scale_edge_color_manual(values=my_palette_rel) +
    scale_color_brewer(palette="Set2", name="Louvain") +
    scale_size(range=c(3,10), name="Degree") +
    labs(title="Sri Lanka Aviation SNA — ggraph (Fruchterman, Louvain)", subtitle="Edge colour = Relationship, width = Weight (1-9); node size = degree") +
    theme_graph() + theme(legend.position="bottom")
  ggsave(file.path(graphs_dir, "network_ggraph_fr.png"), p_gg, width=11, height=8, dpi=300)
}, error=function(e) cat(" ggraph plot skipped:", conditionMessage(e), "\n"))

# network_graph is only a legacy byte-for-byte alias of the FR overview.
file.remove(file.path(graphs_dir, "network_graph.png"))

cat("\n=== Task B Complete ===\n")
cat("Nodes:", vcount(g), "Edges:", ecount(g), "\n")
cat("Top hub:", top_hubs$node[1], " degree ", top_hubs$degree_total[1], "\n")
cat("Top bridge:", top_bridges$node[1], " bet ", round(top_bridges$betweenness[1],1), "\n")
cat("Outputs in:", outputs_dir, " Metrics:", metrics_dir, " Graphs:", graphs_dir, "\n")
print(list.files(outputs_dir, full.names=FALSE))
print(list.files(metrics_dir, full.names=FALSE))
print(list.files(graphs_dir, full.names=FALSE))
