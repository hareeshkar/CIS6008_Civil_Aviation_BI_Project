graph [
  directed 1
  node_default [
  ]
  edge_default [
  ]
  node [
    id 0
    label "n0"
    name "Air Traffic Control (ATC)"
    louvain 1.0
    walktrap 3.0
  ]
  node [
    id 1
    label "n1"
    name "Airport &#38; Aviation Services SL (AASL)"
    louvain 2.0
    walktrap 1.0
  ]
  node [
    id 2
    label "n2"
    name "Bandaranaike International Airport (CMB)"
    louvain 3.0
    walktrap 1.0
  ]
  node [
    id 3
    label "n3"
    name "Cargo Operators"
    louvain 2.0
    walktrap 1.0
  ]
  node [
    id 4
    label "n4"
    name "Civil Aviation Authority of Sri Lanka (CAASL)"
    louvain 1.0
    walktrap 3.0
  ]
  node [
    id 5
    label "n5"
    name "Customs &#38; Immigration"
    louvain 3.0
    walktrap 1.0
  ]
  node [
    id 6
    label "n6"
    name "Fuel Supply Companies"
    louvain 3.0
    walktrap 1.0
  ]
  node [
    id 7
    label "n7"
    name "Ground Handling Unit"
    louvain 3.0
    walktrap 1.0
  ]
  node [
    id 8
    label "n8"
    name "International Airlines"
    louvain 3.0
    walktrap 1.0
  ]
  node [
    id 9
    label "n9"
    name "Maintenance &#38; Engineering"
    louvain 4.0
    walktrap 1.0
  ]
  node [
    id 10
    label "n10"
    name "Mattala Rajapaksa International Airport (MRIA)"
    louvain 2.0
    walktrap 2.0
  ]
  node [
    id 11
    label "n11"
    name "Mihin Lanka"
    louvain 1.0
    walktrap 3.0
  ]
  node [
    id 12
    label "n12"
    name "Sri Lanka Air Force"
    louvain 4.0
    walktrap 1.0
  ]
  node [
    id 13
    label "n13"
    name "SriLankan Airlines"
    louvain 2.0
    walktrap 2.0
  ]
  node [
    id 14
    label "n14"
    name "Tourism Authority"
    louvain 2.0
    walktrap 2.0
  ]
  edge [
    source 0
    target 9
    Relationship "Commercial"
    Weight 4.0
    distance 6.0
  ]
  edge [
    source 1
    target 3
    Relationship "Operational"
    Weight 7.0
    distance 3.0
  ]
  edge [
    source 2
    target 11
    Relationship "Support"
    Weight 7.0
    distance 3.0
  ]
  edge [
    source 2
    target 12
    Relationship "Commercial"
    Weight 5.0
    distance 5.0
  ]
  edge [
    source 2
    target 6
    Relationship "Regulatory"
    Weight 8.0
    distance 2.0
  ]
  edge [
    source 2
    target 5
    Relationship "Commercial"
    Weight 5.0
    distance 5.0
  ]
  edge [
    source 2
    target 3
    Relationship "Operational"
    Weight 1.0
    distance 9.0
  ]
  edge [
    source 4
    target 11
    Relationship "Operational"
    Weight 4.0
    distance 6.0
  ]
  edge [
    source 4
    target 12
    Relationship "Commercial"
    Weight 2.0
    distance 8.0
  ]
  edge [
    source 4
    target 0
    Relationship "Commercial"
    Weight 6.0
    distance 4.0
  ]
  edge [
    source 4
    target 6
    Relationship "Regulatory"
    Weight 2.0
    distance 8.0
  ]
  edge [
    source 5
    target 8
    Relationship "Commercial"
    Weight 9.0
    distance 1.0
  ]
  edge [
    source 5
    target 3
    Relationship "Regulatory"
    Weight 4.0
    distance 6.0
  ]
  edge [
    source 6
    target 5
    Relationship "Operational"
    Weight 9.0
    distance 1.0
  ]
  edge [
    source 6
    target 3
    Relationship "Commercial"
    Weight 9.0
    distance 1.0
  ]
  edge [
    source 7
    target 6
    Relationship "Operational"
    Weight 4.0
    distance 6.0
  ]
  edge [
    source 8
    target 14
    Relationship "Support"
    Weight 2.0
    distance 8.0
  ]
  edge [
    source 9
    target 3
    Relationship "Support"
    Weight 6.0
    distance 4.0
  ]
  edge [
    source 10
    target 13
    Relationship "Commercial"
    Weight 3.0
    distance 7.0
  ]
  edge [
    source 10
    target 5
    Relationship "Operational"
    Weight 2.0
    distance 8.0
  ]
  edge [
    source 10
    target 14
    Relationship "Regulatory"
    Weight 4.0
    distance 6.0
  ]
  edge [
    source 10
    target 3
    Relationship "Commercial"
    Weight 7.0
    distance 3.0
  ]
  edge [
    source 11
    target 0
    Relationship "Support"
    Weight 7.0
    distance 3.0
  ]
  edge [
    source 12
    target 9
    Relationship "Regulatory"
    Weight 7.0
    distance 3.0
  ]
  edge [
    source 12
    target 5
    Relationship "Support"
    Weight 3.0
    distance 7.0
  ]
  edge [
    source 12
    target 8
    Relationship "Support"
    Weight 1.0
    distance 9.0
  ]
  edge [
    source 13
    target 0
    Relationship "Support"
    Weight 1.0
    distance 9.0
  ]
  edge [
    source 14
    target 3
    Relationship "Commercial"
    Weight 1.0
    distance 9.0
  ]
]
