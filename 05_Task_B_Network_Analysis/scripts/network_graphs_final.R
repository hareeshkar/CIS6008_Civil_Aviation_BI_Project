#!/usr/bin/env Rscript
# Task B — Enhanced v2: Professional-grade network visuals (Okabe-Ito, viridis, theme_graph)
# Context7 insights: use colorblind-friendly Okabe-Ito, perceptually uniform viridis, minimal theme_graph, ggrepel
suppressPackageStartupMessages({
  library(tidyverse)
  library(igraph)
  library(tidygraph)
  library(ggraph)
  library(scales)
})

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
g <- readRDS(file.path(base_dir, "outputs/graph_raw.rds"))
cent <- read_csv(file.path(base_dir, "metrics/node_centrality.csv"), show_col_types=FALSE)
comm <- read_csv(file.path(base_dir, "metrics/communities.csv"), show_col_types=FALSE)
edge_df <- read_csv(file.path(base_dir, "metrics/edge_metrics.csv"), show_col_types=FALSE)

# Okabe-Ito palette (colorblind safe, professional) — from ggokabeito / ggplot2 guidance
okabe <- c("#E69F00","#56B4E9","#009E73","#F0E442","#0072B2","#D55E00","#CC79A7","#000000")
rel_levels <- c("Support","Commercial","Regulatory","Operational")
rel_cols <- setNames(okabe[1:4], rel_levels)
# matching edge cols for ggraph
# Louvain palette — distinct but muted
louv_cols <- setNames(okabe[c(2,3,1,7)], sort(unique(comm$louvain)))

# Enrich nodes
V(g)$strength <- cent$strength_total[match(V(g)$name, cent$node)]
V(g)$betweenness <- cent$betweenness[match(V(g)$name, cent$node)]
V(g)$pagerank <- cent$pagerank[match(V(g)$name, cent$node)]
V(g)$louvain <- comm$louvain[match(V(g)$name, comm$node)]
V(g)$label_short <- sapply(V(g)$name, function(x){
  m <- c("Bandaranaike International Airport (CMB)"="BIA · CMB",
         "Mattala Rajapaksa International Airport (MRIA)"="MRIA",
         "Civil Aviation Authority of Sri Lanka (CAASL)"="CAASL",
         "Airport & Aviation Services SL (AASL)"="AASL",
         "Air Traffic Control (ATC)"="ATC",
         "Sri Lanka Air Force"="SL Air Force",
         "Fuel Supply Companies"="Fuel Supply",
         "Customs & Immigration"="Customs",
         "Maintenance & Engineering"="Maintenance",
         "International Airlines"="Intl Airlines")
  if (x %in% names(m)) m[[x]] else if (nchar(x)>18) paste0(substr(x,1,16),"…") else x
})
V(g)$role <- with(cent[match(V(g)$name, cent$node),], ifelse(degree_out > degree_in, "Source", ifelse(degree_in > degree_out, "Sink", "Balanced")))

tg <- as_tbl_graph(g)
tg <- tg %>% activate(nodes) %>% mutate(
  deg = centrality_degree(mode="all"),
  btw = centrality_betweenness(weights=distance),
  pr = centrality_pagerank(weights=Weight),
  comm_f = as.factor(louvain),
  degree_total = strength # dummy alias for KK plot size (will be overridden by cent join)
)
# Ensure degree_total exists in tidygraph nodes for p3
tg <- tg %>% activate(nodes) %>% left_join(cent %>% select(name=node, degree_total) %>% distinct(), by=c("name"))

# Professional theme: clean, Helvetica, light grid, caption left
theme_enhanced <- function(){
  theme_graph(base_family="Helvetica", base_size=11) +
    theme(
      plot.title = element_text(size=16, face="bold", color="#101010", hjust=0, margin=margin(b=4)),
      plot.subtitle = element_text(size=10, color="#3a3a3a", hjust=0, lineheight=1.15, margin=margin(b=10)),
      plot.caption = element_text(size=7.5, color="#7a7a7a", hjust=0, lineheight=1.05),
      plot.background = element_rect(fill="#fcfcfc", color=NA),
      panel.background = element_rect(fill="#fcfcfc", color=NA),
      legend.position = "bottom",
      legend.justification = "left",
      legend.box = "horizontal",
      legend.margin = margin(t=6),
      legend.title = element_text(size=8, face="bold"),
      legend.text = element_text(size=7.5)
    )
}

# Layouts — use consistent FR with weights for reproducibility
set.seed(42)
layout_fr <- create_layout(tg, layout="fr", weights=Weight, niter=4000)
layout_kk <- create_layout(tg, layout="kk", weights=distance)
# Manual aviation hierarchy: BIA/CAASL top, ATC middle, Cargo/Tourism bottom — for storytelling
# Build manual coords: x from KK, y adjusted by role
layout_hier <- layout_kk
# Shift sources up, sinks down
role_y_adj <- c(Source=1.2, Sink=-1.2, Balanced=0)
for(i in seq_len(nrow(layout_hier))){
  r <- V(g)$role[i]
  layout_hier$y[i] <- layout_hier$y[i] + role_y_adj[[r]]*0.25
}

# Helper: save with consistent DPI and white border
save_p <- function(p, path, w=12, h=8.2) {
  ggsave(path, p, width=w, height=h, dpi=340, bg="#fcfcfc", limitsize=FALSE)
  cat("saved", path, "\n")
}

# 1) MAIN: Fruchterman-Reingold — Louvain clusters, degree sizing, clean Okabe
p1 <- ggraph(tg, layout="fr", weights=Weight) +
  geom_edge_link(aes(colour=Relationship, width=Weight),
                 alpha=0.62, lineend="round",
                 arrow=arrow(length=unit(2.6,"mm"), type="closed"),
                 end_cap=circle(5.5,"mm"), start_cap=circle(4.5,"mm")) +
  geom_node_point(aes(size=strength, fill=comm_f), shape=21, colour="white", stroke=1.15, alpha=0.96) +
  geom_node_text(aes(label=label_short), repel=TRUE, size=3.1, family="Helvetica", fontface="bold",
                 colour="#1a1a1a", bg.colour="#ffffff", bg.r=0.18, segment.colour="#9a9a9a",
                 segment.size=0.22, point.padding=unit(0.7,"mm"), box.padding=unit(0.9,"mm"),
                 max.overlaps=28, force=1.4, force_pull=1) +
  scale_edge_width(range=c(0.45, 2.6), name="Tie weight (1–9)") +
  scale_edge_color_manual(values=rel_cols, name="Tie type") +
  scale_size_continuous(range=c(5,15), name="Weighted degree", breaks=c(10,20,35)) +
  scale_fill_manual(values=louv_cols, name="Louvain cluster (mod 0.33)") +
  labs(title="Sri Lanka Aviation Stakeholder Network",
       subtitle="15 organisations · 28 directed ties · Node size = weighted degree (Cargo 35, Fuel/Customs 32) · Edge width = weight · 4 functional clusters",
       caption="Data: SriLanka_Aviation_SNA_Dataset.csv · Directed: Source → Target · FR layout weighted by tie strength · Distance for metrics = 10 – Weight") +
  guides(edge_width=guide_legend(order=1, nrow=1), edge_colour=guide_legend(order=2, nrow=1),
         size=guide_legend(order=3), fill=guide_legend(order=4)) +
  theme_enhanced()
save_p(p1, file.path(base_dir, "graphs/network_fruchterman.png"))
file.copy(file.path(base_dir, "graphs/network_fruchterman.png"), file.path(base_dir, "graphs/network_graph.png"), overwrite=TRUE)
file.copy(file.path(base_dir, "graphs/network_fruchterman.png"), file.path(base_dir, "graphs/network_louvain.png"), overwrite=TRUE)
file.copy(file.path(base_dir, "graphs/network_fruchterman.png"), file.path(base_dir, "graphs/network_ggraph_fr.png"), overwrite=TRUE)

# 2) Betweenness — bottleneck view, viridis sequential, not Okabe (continuous)
p2 <- ggraph(tg, layout="fr", weights=Weight) +
  geom_edge_link(aes(colour=Relationship, width=Weight), alpha=0.48,
                 arrow=arrow(length=unit(2.4,"mm"), type="closed"),
                 end_cap=circle(5,"mm")) +
  geom_node_point(aes(size=betweenness, fill=betweenness), shape=21, colour="white", stroke=1.05) +
  geom_node_text(aes(label=label_short), repel=TRUE, size=3, fontface="bold",
                 bg.colour="white", bg.r=0.14, max.overlaps=28) +
  scale_edge_width(range=c(0.45,2.1), guide="none") +
  scale_edge_color_manual(values=rel_cols, guide="none") +
  scale_size_continuous(range=c(4.5,14), name="Betweenness") +
  scale_fill_viridis_c(option="magma", begin=0.18, end=0.92, name="Betweenness\n(Fuel 12 · Customs 11)") +
  labs(title="Bottlenecks — Who Bridges the Network?",
       subtitle="Larger & warmer = higher betweenness · Fuel Supply and Customs control most shortest paths · ATC/Intl Airlines secondary",
       caption="Betweenness on directed weighted shortest paths (distance = 10 – Weight) · Zero betweenness for pure sources/sinks (BIA, Cargo) is expected") +
  theme_enhanced()
save_p(p2, file.path(base_dir, "graphs/network_betweenness.png"))

# 3) Roles — KK layout, source/sink encoding (most user-friendly for non-technical)
p3 <- ggraph(tg, layout="kk", weights=distance) +
  geom_edge_link(aes(colour=Relationship, width=Weight), alpha=0.58,
                 arrow=arrow(length=unit(2.5,"mm"), type="closed"),
                 end_cap=circle(5,"mm")) +
  geom_node_point(aes(size=deg, fill=role), shape=21, colour="white", stroke=1.1) +
  geom_node_text(aes(label=label_short), repel=TRUE, size=3, fontface="bold",
                 bg.colour="white", bg.r=0.14, max.overlaps=28) +
  scale_edge_width(range=c(0.5,2.5), name="Weight") +
  scale_edge_color_manual(values=rel_cols, name="Relationship") +
  scale_size_continuous(range=c(5,14), name="Total degree") +
  scale_fill_manual(values=c(Source="#2C73D2", Sink="#D93D2B", Balanced="#009E73"), name="Flow role") +
  labs(title="Flow Roles — Sources vs Sinks",
       subtitle="Blue = net sources (BIA 5→0, CAASL 4→0) · Red = net sinks (Cargo 0→7, Tourism 1→2) · Teal = brokers (Fuel 3→2, Customs 4→2)",
       caption="Kamada-Kawai layout preserves tie-strength distances · Balanced brokers are the vulnerability points") +
  theme_enhanced()
save_p(p3, file.path(base_dir, "graphs/network_kamada.png"))
file.copy(file.path(base_dir, "graphs/network_kamada.png"), file.path(base_dir, "graphs/network_kk.png"), overwrite=TRUE)

# 4) Circular — for slide decks, minimal but publication crisp
p4 <- ggraph(tg, layout="linear", circular=TRUE) +
  geom_edge_arc(aes(colour=Relationship, width=Weight), alpha=0.68, strength=0.11,
                arrow=arrow(length=unit(2.1,"mm"), type="closed"), end_cap=circle(4,"mm")) +
  geom_node_point(aes(size=deg, fill=comm_f), shape=21, colour="white", stroke=0.9) +
  geom_node_text(aes(label=label_short), repel=FALSE, size=2.9, fontface="bold", colour="#1a1a1a") +
  scale_edge_width(range=c(0.55,1.9), guide="none") +
  scale_edge_color_manual(values=rel_cols, name="Relationship") +
  scale_size_continuous(range=c(4,11), guide="none") +
  scale_fill_manual(values=louv_cols, name="Cluster") +
  labs(title="Circular Overview — Hubs at a Glance",
       subtitle="Immediate visual rank: Cargo (7), Customs (6), BIA/Fuel/SLAF (5) · Commercial ties (10) dominate outer ring",
       caption="Best for 16:9 slides · Labels placed outside ring for legibility") +
  theme_enhanced() + theme(legend.position="right")
save_p(p4, file.path(base_dir, "graphs/network_circle.png"))

# 5) Degree distribution — publication style, no label clutter
deg_df <- cent %>% select(node, degree_total) %>% count(degree_total, name="n") %>% arrange(degree_total)
p5 <- ggplot(cent, aes(x=degree_total)) +
  geom_histogram(binwidth=1, fill="#2C73D2", colour="white", linewidth=0.6, boundary=0, alpha=0.92) +
  geom_text(data=deg_df, aes(x=degree_total, y=n, label=n), vjust=-0.7, size=3.4, fontface="bold", family="Helvetica") +
  scale_x_continuous(breaks=1:7, limits=c(0.5,7.5)) +
  scale_y_continuous(expand=expansion(mult=c(0,0.18))) +
  labs(title="Degree Distribution — Concentrated Leadership",
       subtitle="15 nodes · Mean degree 3.7 · Only Cargo (7) and Customs (6) exceed 5 · Long tail of peripheral actors (AASL, Ground Handling deg 1)",
       x="Total degree (in + out)", y="Number of organisations") +
  theme_minimal(base_family="Helvetica") +
  theme(plot.title=element_text(face="bold", size=13), plot.subtitle=element_text(size=9, colour="#3a3a3a"),
        panel.grid.minor=element_blank(), panel.grid.major.x=element_blank())
ggsave(file.path(base_dir, "graphs/degree_distribution.png"), p5, width=8, height=5, dpi=340, bg="#fcfcfc")
# counts variant (same but bar y=n)
p5b <- ggplot(deg_df, aes(x=as.factor(degree_total), y=n)) +
  geom_col(fill="#2C73D2", colour="white", width=0.72) +
  geom_text(aes(label=n), vjust=-0.5, size=3.4, fontface="bold") +
  labs(title="Degree Counts — Alternative View", x="Degree", y="Nodes") +
  theme_minimal(base_family="Helvetica")
ggsave(file.path(base_dir, "graphs/degree_distribution_counts.png"), p5b, width=8, height=5, dpi=340, bg="#fcfcfc")
cat("saved degree distributions\n")

# Re-create rank plots with Okabe + enhanced theme for consistency
for (metric in c("degree_total","betweenness","eigenvector","pagerank","strength_total")) {
  dfp <- cent %>% arrange(desc(.data[[metric]])) %>%
    mutate(short = sapply(node, function(x) {
      if (nchar(x)>20) paste0(substr(x,1,19),"…") else x
    }),
    short = forcats::fct_reorder(short, .data[[metric]]))
  p <- ggplot(dfp, aes(x=.data[[metric]], y=short, fill=.data[[metric]])) +
    geom_col(width=0.62, show.legend=FALSE) +
    geom_text(aes(label=round(.data[[metric]],2)), hjust=-0.08, size=3, fontface="bold", family="Helvetica") +
    scale_fill_viridis_c(option="Blues", begin=0.35, end=0.92, guide="none") +
    labs(title=paste0("Ranked — ", metric),
         subtitle=ifelse(metric=="betweenness","Fuel Supply 12.0 is the critical bridge · Cargo 0 sits on no paths (sink)",
                  ifelse(metric=="degree_total","Cargo 7 leads · 2 nodes degree 1 (periphery)",
                  ifelse(metric=="eigenvector","Only Cargo 1.0 — DAG sink artefact (see text)",""))),
         x=metric, y=NULL) +
    theme_minimal(base_family="Helvetica") +
    theme(plot.title=element_text(face="bold", size=11), plot.subtitle=element_text(size=8, colour="#3a3a3a"),
          panel.grid.major.y=element_blank()) +
    scale_x_continuous(expand=expansion(mult=c(0,0.20)))
  ggsave(file.path(base_dir, "graphs", paste0("rank_", metric, ".png")), p, width=8, height=5.8, dpi=340, bg="#fcfcfc")
  cat("rank", metric, "saved\n")
}

# 6 & 7) Centrality dashboard & vulnerability storyboard — keep existing enhanced versions, just ensure Okabe/viridis
# Rebuild centrality dashboard with Okabe fills per metric
rank_long <- cent %>% select(node, degree_total, betweenness, closeness, pagerank, strength_total) %>%
  pivot_longer(-node, names_to="metric", values_to="value") %>%
  mutate(short = sapply(node, function(x) if(nchar(x)>14) substr(x,1,13) else x))
# Map each metric to its own Okabe hue
metric_cols <- c(degree_total="#0072B2", betweenness="#D55E00", closeness="#009E73", pagerank="#CC79A7", strength_total="#E69F00")
p6 <- ggplot(rank_long, aes(x=value, y=reorder(short, value), fill=metric)) +
  geom_col(width=0.68, show.legend=FALSE) +
  geom_text(aes(label=round(value,2)), hjust=-0.07, size=2.2, family="Helvetica") +
  facet_wrap(~metric, scales="free_x", nrow=2,
             labeller=as_labeller(c(degree_total="Total degree",betweenness="Betweenness",closeness="Closeness",pagerank="PageRank",strength_total="Strength"))) +
  scale_fill_manual(values=metric_cols) +
  labs(title="Centrality Dashboard — One-Glance Comparison",
       subtitle="Cargo dominates degree/strength/PageRank · Fuel & Customs dominate betweenness · Fuel leads closeness (0.189)",
       x=NULL, y=NULL) +
  theme_minimal(base_family="Helvetica") +
  theme(plot.title=element_text(face="bold", size=13), strip.text=element_text(face="bold", size=9),
        panel.grid.major.y=element_blank(), panel.spacing=unit(0.7,"lines"),
        plot.background=element_rect(fill="#fcfcfc", colour=NA)) +
  scale_x_continuous(expand=expansion(mult=c(0,0.20)))
ggsave(file.path(base_dir, "graphs/centrality_dashboard.png"), p6, width=12.8, height=7.8, dpi=340, bg="#fcfcfc")
cat("dashboard saved\n")

# Vulnerability storyboard — already good, just polish colours
vuln <- read_csv(file.path(base_dir, "metrics/vulnerability_joint.csv"), show_col_types=FALSE)
vuln <- vuln %>% mutate(label_short = gsub("Remove: ", "", node_removed),
                        is_baseline = label_short=="BASELINE (no removal)")
p7 <- ggplot(vuln, aes(x=fct_reorder(label_short, -edges), y=edges, fill=is_baseline)) +
  geom_col(width=0.62, show.legend=FALSE) +
  geom_text(aes(label=paste0(edges," edges\n", weak_comps, ifelse(weak_comps==1," comp"," comps"))),
            vjust=-0.32, size=2.9, lineheight=0.85, family="Helvetica") +
  scale_fill_manual(values=c("TRUE"="#009E73","FALSE"="#2C73D2")) +
  labs(title="What-If Removal — Resilience Under Stress",
       subtitle="Baseline 15·28·1 · Only Cargo removal fragments into 2 components (density 0.115) — single-point failure · BIA+CAASL joint 19 edges",
       x=NULL, y="Edges remaining") +
  theme_minimal(base_family="Helvetica") +
  theme(plot.title=element_text(face="bold", size=13), plot.subtitle=element_text(size=9, colour="#3a3a3a"),
        axis.text.x=element_text(angle=17, hjust=1, size=7.2), panel.grid.major.x=element_blank(),
        plot.background=element_rect(fill="#fcfcfc", colour=NA)) +
  scale_y_continuous(expand=expansion(mult=c(0,0.18)), limits=c(0,30))
ggsave(file.path(base_dir, "graphs/vulnerability_storyboard.png"), p7, width=12.5, height=6.2, dpi=340, bg="#fcfcfc")
cat("storyboard saved\n")

cat("All enhanced v2 graphs (professional Okabe/viridis) done\n")
