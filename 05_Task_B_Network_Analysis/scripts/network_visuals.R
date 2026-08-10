#!/usr/bin/env Rscript
# Enhanced network graphs — more readable, user-friendly, enhanced look
file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(file_arg) == 1L) {
  base_dir <- dirname(dirname(normalizePath(sub("^--file=", "", file_arg))))
} else if (dir.exists(file.path(getwd(), "outputs"))) {
  base_dir <- normalizePath(getwd())
} else {
  base_dir <- normalizePath(file.path(getwd(), "05_Task_B_Network_Analysis"))
}
if (!dir.exists(file.path(base_dir, "outputs"))) stop("Task B directory not found: ", base_dir)
setwd(base_dir)
if (file.exists("renv/activate.R")) source("renv/activate.R")

suppressPackageStartupMessages({
  library(tidyverse)
  library(igraph)
  library(tidygraph)
  library(ggraph)
  library(scales)
  library(viridis)
})

g <- readRDS(file.path(base_dir, "outputs/graph_raw.rds"))
edges_raw <- read_csv(file.path(base_dir, "working_data/SriLanka_Aviation_SNA_Dataset.csv"), show_col_types=FALSE)
cent <- read_csv(file.path(base_dir, "metrics/node_centrality.csv"), show_col_types=FALSE)
comm <- read_csv(file.path(base_dir, "metrics/communities.csv"), show_col_types=FALSE)

# Enrich graph
V(g)$degree_total <- cent$degree_total[match(V(g)$name, cent$node)]
V(g)$betweenness <- cent$betweenness[match(V(g)$name, cent$node)]
V(g)$pagerank <- cent$pagerank[match(V(g)$name, cent$node)]
V(g)$strength <- cent$strength_total[match(V(g)$name, cent$node)]
V(g)$louvain <- comm$louvain[match(V(g)$name, comm$node)]
V(g)$label_short <- sapply(V(g)$name, function(x) {
  # Smart short labels for BIA/MRIA/CAASL
  recode <- c(
    "Bandaranaike International Airport (CMB)"="BIA (CMB)",
    "Mattala Rajapaksa International Airport (MRIA)"="MRIA",
    "Civil Aviation Authority of Sri Lanka (CAASL)"="CAASL",
    "Airport & Aviation Services SL (AASL)"="AASL",
    "Air Traffic Control (ATC)"="ATC",
    "Sri Lanka Air Force"="SL Air Force",
    "Fuel Supply Companies"="Fuel Supply",
    "Customs & Immigration"="Customs",
    "Maintenance & Engineering"="Maintenance",
    "International Airlines"="Intl Airlines"
  )
  if (x %in% names(recode)) recode[[x]] else if (nchar(x)>18) paste0(substr(x,1,16),"..") else x
})
V(g)$hub_label <- V(g)$label_short

# Enhanced palettes
rel_cols <- c(Support="#1f77b4", Commercial="#0d5c33", Regulatory="#d62728", Operational="#ff7f0e")
comm_cols <- c("1"="#1f77b4","2"="#2ca02c","3"="#ff7f0e","4"="#9467bd")
# Alternative enhanced: use muted academic palette
comm_cols <- c("1"="#2C73D2","2"="#2E8B57","3"="#E67E22","4"="#8E44AD","5"="#C0392B","6"="#16A085")

# tidygraph for ggraph
tg <- as_tbl_graph(g)
tg <- tg %>% activate(nodes) %>% mutate(
  deg = centrality_degree(mode="all"),
  btw = centrality_betweenness(weights = distance),
  comm_f = as.factor(louvain),
  pr = pagerank
)

# Helper to add enhanced theme
theme_graph_clean <- theme_graph(base_family="Helvetica") +
  theme(
    plot.title = element_text(size=18, face="bold", hjust=0, color="#1a1a1a"),
    plot.subtitle = element_text(size=11, hjust=0, color="#4a4a4a", margin=margin(b=12)),
    plot.caption = element_text(size=8, hjust=0, color="#7a7a7a"),
    plot.background = element_rect(fill="#fafafa", color=NA),
    legend.position = "bottom",
    legend.title = element_text(size=9, face="bold"),
    legend.text = element_text(size=8)
  )

# 1) Enhanced FR — Louvain communities, degree size, weight width
set.seed(42)
p1 <- ggraph(tg, layout="fr", weights=Weight, niter=8000) +
  geom_edge_link(aes(colour=Relationship, width=Weight, alpha=Weight),
                 arrow=arrow(length=unit(2.8,"mm"), type="closed"),
                 end_cap=circle(5,"mm"), start_cap=circle(4,"mm"), show.legend=TRUE) +
  geom_edge_loop(aes(colour=Relationship), alpha=0.4) +
  geom_node_point(aes(size=strength, fill=comm_f), shape=21, colour="white", stroke=1.2, alpha=0.95) +
  geom_node_text(aes(label=hub_label), repel=TRUE, size=3.2, family="Helvetica", fontface="bold",
                 bg.color="white", bg.r=0.15, max.overlaps=25, point.padding=unit(0.6,"mm")) +
  scale_edge_width(range=c(0.6,2.8), name="Tie Strength") +
  scale_edge_color_manual(values=rel_cols, name="Relationship") +
  scale_edge_alpha(range=c(0.35,0.9), guide="none") +
  scale_size_continuous(range=c(6,16), name="Weighted Degree", breaks=c(10,20,35)) +
  scale_fill_manual(values=comm_cols, name="Louvain Cluster") +
  labs(title="Sri Lanka Aviation Network — Functional Structure",
       subtitle="15 organisations · 28 directed ties · Node size = weighted degree (strength) · Edge width = tie weight (1–9) · Louvain modularity 0.33 (4 clusters)",
       caption="Source: SriLanka_Aviation_SNA_Dataset.csv (15 nodes, 28 edges) · Layout: Fruchterman-Reingold · Distance for betweenness = 10 – Weight") +
  guides(edge_width=guide_legend(order=1), edge_colour=guide_legend(order=2), size=guide_legend(order=3), fill=guide_legend(order=4)) +
  theme_graph_clean
ggsave(file.path(base_dir, "graphs/network_fruchterman.png"), p1, width=13, height=9, dpi=320, bg="#fafafa")
file.copy(file.path(base_dir, "graphs/network_fruchterman.png"), file.path(base_dir, "graphs/network_graph.png"), overwrite=TRUE)
file.copy(file.path(base_dir, "graphs/network_fruchterman.png"), file.path(base_dir, "graphs/network_louvain.png"), overwrite=TRUE)
file.copy(file.path(base_dir, "graphs/network_fruchterman.png"), file.path(base_dir, "graphs/network_ggraph_fr.png"), overwrite=TRUE)
file.remove(file.path(base_dir, "graphs/network_graph.png"))
cat("saved enhanced FR (as network_fruchterman.png / network_graph.png / network_louvain.png)\n")

# 2) Betweenness enhanced — red heatmap for bottlenecks
# Scale betweenness for size
tg <- tg %>% activate(nodes) %>% mutate(btw_s = scales::rescale(betweenness, to=c(3,14)))
p2 <- ggraph(tg, layout="fr", weights=Weight) +
  geom_edge_link(aes(colour=Relationship, width=Weight), alpha=0.5,
                 arrow=arrow(length=unit(2.5,"mm"), type="closed"),
                 end_cap=circle(5,"mm")) +
  geom_node_point(aes(size=betweenness, fill=betweenness), shape=21, colour="white", stroke=1.1) +
  geom_node_text(aes(label=hub_label), repel=TRUE, size=3, fontface="bold", bg.color="white", bg.r=0.12) +
  scale_edge_width(range=c(0.5,2.2), guide="none") +
  scale_edge_color_manual(values=rel_cols, guide="none") +
  scale_size_continuous(range=c(4,15), name="Betweenness") +
  scale_fill_viridis_c(option="magma", name="Betweenness", begin=0.2, end=0.95) +
  labs(title="Network Bottlenecks — Who Controls the Shortest Paths?",
       subtitle="Node size & fill = betweenness (Fuel Supply 12.0, Customs 11.0, ATC 6.0 dominate) · Redder/larger = more critical bridge",
       caption="Weighted shortest paths use distance = 10 – Weight · Top edges: Customs→Intl (13), Fuel→Customs (12), ATC→Maintenance (8)") +
  theme_graph_clean
ggsave(file.path(base_dir, "graphs/network_betweenness.png"), p2, width=13, height=9, dpi=320, bg="#fafafa")
cat("saved enhanced betweenness (as network_betweenness.png)\n")

# 3) Hub/Authority enhanced — split view
# Create a simple bipartite style: size by hub vs authority
p3a_data <- cent %>% pivot_longer(c(hub_score, authority_score), names_to="role", values_to="score")
# For graph, color by in vs out degree
tg <- tg %>% activate(nodes) %>% mutate(in_out = case_when(
  degree_total==0 ~ "isolate",
  cent$degree_in[match(name, cent$node)] > cent$degree_out[match(name, cent$node)] ~ "Sink (in > out)",
  cent$degree_out[match(name, cent$node)] > cent$degree_in[match(name, cent$node)] ~ "Source (out > in)",
  TRUE ~ "Balanced"
))
p3 <- ggraph(tg, layout="kk", weights=distance) +
  geom_edge_link(aes(colour=Relationship, width=Weight), alpha=0.55,
                 arrow=arrow(length=unit(2.5,"mm"), type="closed"),
                 end_cap=circle(5,"mm")) +
  geom_node_point(aes(size=degree_total, fill=in_out), shape=21, colour="white", stroke=1.1) +
  geom_node_text(aes(label=hub_label), repel=TRUE, size=3, bg.color="white", bg.r=0.12, fontface="bold") +
  scale_edge_width(range=c(0.6,2.6)) +
  scale_edge_color_manual(values=rel_cols) +
  scale_size_continuous(range=c(5,14), name="Total degree") +
  scale_fill_manual(values=c("Source (out > in)"="#2C73D2","Sink (in > out)"="#D93D2B","Balanced"="#2E8B57"), name="Flow Role") +
  labs(title="Network Roles — Sources vs Sinks",
       subtitle="BIA (5 out, 0 in) and CAASL (4 out) are pure sources · Cargo (0 out, 7 in) is pure sink · Fuel/Customs are balanced brokers",
       caption="Kamada-Kawai layout (distance = 10 – Weight) preserves tie-strength geometry") +
  theme_graph_clean
ggsave(file.path(base_dir, "graphs/network_kamada.png"), p3, width=13, height=9, dpi=320, bg="#fafafa")
file.copy(file.path(base_dir, "graphs/network_kamada.png"), file.path(base_dir, "graphs/network_kk.png"), overwrite=TRUE)
cat("saved enhanced roles KK (as network_kamada.png)\n")

# 4) Clean circular — for presentation slide (minimal)
p4 <- ggraph(tg, layout="linear", circular=TRUE) +
  geom_edge_arc(aes(colour=Relationship, width=Weight), alpha=0.7, strength=0.12,
                arrow=arrow(length=unit(2.2,"mm"), type="closed"), end_cap=circle(4,"mm")) +
  geom_node_point(aes(size=degree_total, fill=comm_f), shape=21, colour="white", stroke=1) +
  geom_node_text(aes(label=hub_label), repel=FALSE, size=2.8, fontface="bold") +
  scale_edge_width(range=c(0.7,2), guide="none") +
  scale_edge_color_manual(values=rel_cols, name="Relationship") +
  scale_size_continuous(range=c(4,12), guide="none") +
  scale_fill_manual(values=comm_cols, name="Cluster") +
  labs(title="Circular Overview — Immediate Hub Readability",
       subtitle="Cargo (7), Customs (6), Fuel/BIA (5) instantly stand out · Commercial (10 ties) dominates outer arcs",
       caption="Circular layout for slide decks · Best printed at 16:9") +
  theme_graph_clean + theme(legend.position="right")
ggsave(file.path(base_dir, "graphs/network_circle.png"), p4, width=13, height=9, dpi=320, bg="#fafafa")
cat("saved enhanced circular (as network_circle.png)\n")

# 5) Small multiples — centralities at a glance (neat dashboard)
rank_long <- cent %>% select(node, degree_total, betweenness, closeness, pagerank, strength_total) %>%
  pivot_longer(-node, names_to="metric", values_to="value") %>%
  mutate(node_short = sapply(node, function(x) {
    rec <- c("Bandaranaike International Airport (CMB)"="BIA","Mattala Rajapaksa International Airport (MRIA)"="MRIA","Civil Aviation Authority of Sri Lanka (CAASL)"="CAASL")
    if (x %in% names(rec)) rec[[x]] else substr(x,1,16)
  }))
# Make 5 small ranked bars in one figure using facet
p5 <- ggplot(rank_long, aes(x=value, y=reorder(node_short, value), fill=metric)) +
  geom_col(width=0.72, show.legend=FALSE) +
  geom_text(aes(label=round(value,2)), hjust=-0.08, size=2.3, family="Helvetica") +
  facet_wrap(~metric, scales="free_x", nrow=2) +
  scale_fill_manual(values=c(degree_total="#2C73D2", betweenness="#D93D2B", closeness="#2E8B57", pagerank="#E67E22", strength_total="#8E44AD")) +
  labs(title="Centrality Dashboard — All Metrics at a Glance",
       subtitle="Cargo dominates degree/strength/pagerank; Fuel/Customs dominate betweenness; Fuel also leads closeness",
       x=NULL, y=NULL) +
  theme_minimal(base_family="Helvetica") +
  theme(plot.title=element_text(face="bold", size=14), strip.text=element_text(face="bold", size=9),
        panel.grid.major.y=element_blank(), panel.spacing=unit(0.8,"lines")) +
  scale_x_continuous(expand=expansion(mult=c(0,0.22)))
ggsave(file.path(base_dir, "graphs/centrality_dashboard.png"), p5, width=13, height=8, dpi=320, bg="#fafafa")
cat("saved dashboard (as centrality_dashboard.png)\n")

# 6) Vulnerability storyboard — single figure showing what-if fragmentation
vuln <- read_csv(file.path(base_dir, "metrics/vulnerability_joint.csv"), show_col_types=FALSE)
vuln$label <- vuln$node_removed
# Tidy for plotting edges left / components
vuln_long <- vuln %>% select(label, edges=`edges`, comps=`weak_comps`) %>% pivot_longer(c(edges, comps), names_to="k", values_to="v")
p6 <- ggplot(vuln, aes(x=reorder(label, -`edges`), y=`edges`)) +
  geom_col(fill="#2C73D2", width=0.65) +
  geom_text(aes(label=paste0(`edges`," edges\n",`weak_comps`," comps")), vjust=-0.35, size=2.8, lineheight=0.85) +
  labs(title="What-If Removal — Resilience Storyboard",
       subtitle="Baseline 15 nodes/28 edges/1 weak component · Cargo removal fragments (2 comps, 21 edges) — the only single-point network split",
       x=NULL, y="Edges remaining") +
  theme_minimal(base_family="Helvetica") +
  theme(axis.text.x=element_text(angle=18, hjust=1, size=7.5), plot.title=element_text(face="bold", size=14)) +
  scale_y_continuous(expand=expansion(mult=c(0,0.18)), limits=c(0,30))
ggsave(file.path(base_dir, "graphs/vulnerability_storyboard.png"), p6, width=13, height=6.5, dpi=320, bg="#fafafa")
cat("saved vulnerability storyboard\n")

cat("All enhanced graphs done\n")
print(list.files(file.path(base_dir, "graphs"), pattern="enhanced", full.names=FALSE))
