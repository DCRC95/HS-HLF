Harvesting Crypto Vulnerability Intelligence for
North Korean Crypto Offensives: Integrating
Machine Learning, Blockchain and Social Network
Analysis for SARs Regulatory Reporting
This paper introduces Hacksleuths, a fully automated
intelligence pipeline for attributing cryptocurrency security
incidents to North Korean threat actors and generating
Suspicious Activity Reports (SARs) for financial regulatory
compliance. Analysing 232 incidents from 2020-2025, the
application processes 13,957 suspicious transactions, totaling
$11.8 billion in losses. The framework scrapes and processes
hack reports to derive a novel Word Brutality Index (WBI) for
risk assessment. Machine learning based attribution using TF-
IDF, K-Means clustering, and keyword scoring links the
APT38 group to 62.9% of North Korean attributed incidents,
with bridge hacks being the most frequent attack vector. The
analysis reveals 82.2% of attacks target ERC-20 tokens,
primarily USDC and DAI. On-chain, Ethereum transaction
graphs are constructed, and 4,713 unique suspicious wallets
were detected. Network analysis identifies distinct laundering
patterns, highlighting 29 high-connectivity hubs, 111 key
intermediary addresses, and 1,372 critical transaction paths
whose disruption would significantly fragment illicit fund
flows. Furthermore, integration with five major offshore leaks
databases reveals high-confidence connections between 251
incidents and 7,869 unique offshore entities, exposing
coordinated offshore structures. All findings are immutably
stored on the Ethereum Sepolia testnet to ensure data integrity.
Keywords Cryptocurrency security, machine learning,
blockchains, North Korean cyber operations, suspicious activity
reporting, social network analysis
I. INTRODUCTION
Crypto web intelligence involves collecting and analysing
data from online sources to gain insights into cryptocurrency
vulnerabilities. Machine learning algorithms automate the
detection and classification of these vulnerabilities, using
large datasets and advanced analytics to identify patterns and
anomalies. Social network analysis helps understand
relationships and interactions within networks of actors, such
as hacker groups, which is crucial for identifying attacks [1].
The research utilises credible sources that document major
hacks and exploits within the decentralised finance (DeFi)
and cryptocurrency space. These sources provide detailed
accounts of significant security breaches, offering valuable
data for researchers and practitioners. Various platforms
provide different hacks and exploits, providing insights into
the most significant vulnerabilities. These resources are
instrumental in understanding the landscape of crypto
vulnerabilities and the effectiveness of different security
measures [2]. The study aims to identify and analyse these
vulnerabilities using advanced web intelligence techniques.
By sourcing and gathering crypto vulnerability smart
contract (CVSC) data from credible sources, the research
establishes a robust mechanism with multiple purposes. First,
it proposes a mechanism for rating vulnerabilities. Through
applied analytics and natural language processing (NLP), the
severity of each vulnerability is assessed, enabling a more
nuanced understanding of the risks involved and facilitating
better-informed decision-making for investors and
stakeholders [3]. Second, the capture and analysis of crypto
vulnerability data provides a foundation for future machine
learning models. By analysing hacker groups and tracking
blockchain networks, groupings can be assigned based on
machine learning analysis of hack activities. This helps in
understanding the behaviour and strategies of various hacker
groups. The research applies known CVSC (Common
Vulnerability Scoring System) vulnerabilities to hacks based
on frameworks established by the Cloud Security Alliance
(CSA) working groups, standardising the methodology and
leveraging existing industry knowledge to enhance the
analysis [4]. The main contributions include developing an
advanced analytics pipeline for crypto vulnerability severity
analysis. This pipeline integrates multiple data sources to
enhance the accuracy and efficiency of vulnerability
identification and classification. It incorporates NLP
techniques to analyse textual data related to vulnerabilities,
enabling the extraction of relevant features and the
assessment of their WBI severity. By identifying rogue
network nodes and capturing potential suspicious activities,
the research supports suspicious activity reporting (SARs), a
financial regulatory requirement for investment banks and
cryptocurrency trading firms [5]. This contributes to broader
efforts in monitoring and mitigating illicit activities within
the cryptocurrency domain. The enhanced analytics pipeline
identifies existing vulnerabilities and indicates how these
threats work potentially by providing a proactive approach to
crypto security. This is achieved through machine learning
models that classify vulnerabilities based on their
characteristics and severity, and social network analysis
techniques that map out the networks of actors involved in
exploits, helping to identify and disrupt coordinated attacks
[6]. The paper is structured with Section II reviewing related
works, highlighting previous studies and advancements in
crypto vulnerability analysis, including automated
vulnerability analysis research and contributions from
various researchers in understanding and mitigating these
vulnerabilities. Section III details the methodology, including
the data collection process, development of the analytics
pipeline, and integration of NLP, machine learning, social
network analysis techniques and blockchain. Section IV
presents the study's results, demonstrating the pipeline's
effectiveness in identifying, classifying crypto
vulnerabilities, including machine learning model
performance metrics, social network analysis insights,
offshore leaks metrics and the overall impact on crypto
vulnerability management. Section V concludes the paper,
summarising key findings and contributions, and discussing
potential directions for future research.
II. LITERATURE REVIEW
A. Blockchain Forensics
Blockchain has emerged as a critical discipline in
cryptocurrency security, evolving from basic transaction
tracing to sophisticated behavioural analysis. The immutable
nature of blockchain ledgers provides a rich dataset for
forensic investigation yet presents unique challenges in terms
of scale and pseudonymity [7]. Recent studies have
demonstrated the effectiveness of clustering algorithms in
de-anonymising transactions, with success in Bitcoin's
UTXO model [8]. However, the rapid development of
privacy preserving technologies such as zk-SNARKs and
confidential transactions has created new hurdles for forensic
investigators [9]. The field has seen a paradigm shift from
reactive to proactive threat detection, with machine learning
models now capable of identifying suspicious patterns before
they manifest as security incidents [10]. This evolution
mirrors broader trends in cybersecurity, where the increasing
sophistication of attacks necessitates equally advanced
defense mechanisms [11]. The growing adoption of
decentralised finance (DeFi) platforms has further
complicated the landscape, introducing novel attack vectors
and expanding the potential attack surface [12].
B. Cryptocurrency Threat Landscape
The cryptocurrency ecosystem faces a rapidly evolving
threat landscape, with attackers employing increasingly
sophisticated techniques to exploit both technical and human
vulnerabilities. Recent analyses reveal that the total value of
cryptocurrency stolen through hacks reached $3.8 billion in
2024 alone, representing a 42% increase from the previous
year [11]. This section examines the primary attack vectors,
emerging threats, and defensive strategies in cryptocurrency
security. Smart contract vulnerabilities remain the most
exploited attack surface, accounting for 58% of all
cryptocurrency thefts in 2024 [13]. The most prevalent
vulnerabilities include reentrancy attacks, price
manipulation, and access control flaws. Reentrancy attacks
continue to plague DeFi protocols despite being well-
documented since the 2016 DAO hack. The 2024 Euler
Finance exploit demonstrated how sophisticated attackers
can combine multiple reentrancy vectors to drain $197
million in a single transaction [14]. Price manipulation
attacks have grown increasingly sophisticated, with attackers
exploiting time delays and liquidity constraints. Research by
Zhang et al. identified 47 oracle manipulation attacks in
2023-2024, resulting in combined losses of $890 million.
Access control flaws remain a significant concern, as
evidenced by the 2023 Multichain bridge hack which led to
$126 million in losses due to inadequate access controls (11).
Centralised exchanges and cross-chain bridges have emerged
as high-value targets due to their concentration of assets. The
2024 Poloniex hack ($100 million) and the 2023 Mixin
Network breach ($200 million) both exploited vulnerabilities
in multi-signature wallet implementations (16). Bridge
protocols, which facilitate asset transfers between
blockchains, have proven particularly vulnerable, with over
$2 billion stolen from bridges since 2021 [11].
C. North Korean Operations
State-sponsored actors, particularly those affiliated with
North Korea, have developed sophisticated attack chains
that combine social engineering with technical exploits. The
2023 Atomic Wallet breach, attributed to the Lazarus
Group, involved a supply chain compromise that enabled
the theft of $100 million across multiple blockchains [17].
These attacks typically follow a multistage process
beginning with initial access through spear-phishing or
compromised developer tools, followed by lateral
movement within the target network, deployment of custom
malware for credential harvesting, and finally fund
exfiltration through complex laundering chains. North
Korea's cyber operations have undergone significant
evolution since their inception in the early 2000s. The
Lazarus Group, operating under Bureau 121 of the
Reconnaissance General Bureau, has emerged as one of the
most sophisticated state sponsored threat actors, with
estimated annual cryptocurrency thefts exceeding $1 billion
[18]. The group's operations have become increasingly
professionalised, with specialised teams responsible for
reconnaissance, development, operations, and money
laundering [19]. The Lazarus Group's attack methodology
typically follows a multi-stage process beginning with
reconnaissance, where they identify targets through open-
source intelligence (OSINT), conduct vulnerability scanning
of public-facing infrastructure, and employ social
engineering via professional networking platforms. The
initial access phase often involves spear-phishing with
weaponised documents, exploitation of zero-day
vulnerabilities, and supply chain compromises.
D. Machine Learning in Blockchain Forensics
The application of machine learning techniques to
blockchain has revolutionised the detection and prevention
of cryptocurrency related crime. Supervised learning
algorithms, particularly random forests and gradient
boosting machines, have demonstrated exceptional
performance in classifying illicit transactions, achieving F1-
scores exceeding 0.95 on labelled datasets [20].
Unsupervised approaches, including DBSCAN and
HDBSCAN clustering, have proven effective in identifying
previously unknown threat patterns by analysing transaction
graph structures [21]. Recent advancements in deep learning
have further enhanced analytical capabilities. Graph neural
networks (GNNs) have shown promise in modelling the
complex relationships between blockchain addresses,
enabling more accurate entity resolution and behaviour
profiling [22]. However, researchers caution that adversarial
machine learning techniques are being deployed by
sophisticated threat actors to evade detection, necessitating
continuous model retraining and the development of robust
defense mechanisms [23]
E. Regulatory Framework and Suspicious Activity
Reports
The regulatory landscape for cryptocurrency transactions
has undergone significant transformation in response to the
growing threat of financial crime. The Financial Action Task
Force's (FATF) Travel Rule, implemented in 2022, requires
virtual asset service providers (VASPs) to collect and share
beneficiary information for transactions exceeding $1,000
[24]. This regulatory framework has driven the development
of sophisticated transaction monitoring systems capable of
analysing patterns indicative of money laundering, terrorist
financing, and sanctions evasion. Academic research has
identified several challenges in implementing effective
suspicious activity reporting (SAR) for cryptocurrency
transactions. A study by Böhme et al. analysed 12,000 SARs
filed by US-based cryptocurrency businesses, finding that
only 18% resulted in regulatory action [25]. The study
attributed this low conversion rate to inconsistent reporting
standards, false positives, and the global nature of blockchain
transactions, which often span multiple jurisdictions with
conflicting regulatory requirements. The European Union's
Markets in Crypto-Assets (MiCA) regulation, implemented
in 2024, represents the most comprehensive regulatory
framework to date. MiCA introduces stringent licensing
requirements for cryptocurrency service providers,
mandatory transaction monitoring, and enhanced due
diligence for transactions involving self-hosted wallets [26].
Research by Auer et al., suggests that these measures have
significantly improved the quality and actionability of SARs,
with EU-based VASPs demonstrating a 47% higher rate of
regulatory compliance compared to their global counterparts
[27]
III. METHODOLOGY
A. Data Collection and Web Scraping Framework
The research methodology employs a systematic web
scraping approach to gather comprehensive cryptocurrency
hack intelligence from credible web sources. The data
collection process utilises Python's requests library in
conjunction with BeautifulSoup for HTML parsing,
implementing a robust framework designed to handle large-
scale data extraction while maintaining data integrity. The
approach began with identifying credible cryptocurrency
security news sources. A comprehensive database of incident
reports spanning from 2020 to present, focusing particularly
on DeFi protocol exploits, centralised exchange breaches,
and bridge vulnerabilities but not exclusive to same. The
scraping framework operates with built-in retry mechanisms
and exponential backoff strategies to handle network
inconsistencies and rate limiting from target websites. The
system incorporates advanced error handling protocols that
distinguish between temporary network issues and
permanent content unavailability. When encountering HTTP
errors, the scraper implements intelligent retry logic with
increasing delays between attempts. For 403 Forbidden
responses, the application rotates through multiple user agent
strings and implements session management to avoid
detection. The framework also includes proxy rotation
capabilities for high-volume scraping operations, ensuring
consistent data collection even when facing IP-based
restrictions
1. Web scraping architecture : The initial phase
involves harvesting hyperlinks from credible web
sources, which serves as the primary index for
cryptocurrency security incidents. The scraping
algorithm iterates through each identified URL,
extracting relevant content from the "post content"
section of each incident report. To ensure
comprehensive data capture, the system processes all
paragraph elements within each article
Table 1: Web Scraping Framework Components
Component Technology Purpose Output
Format
URL
Harvesting
Python requests Primary link
collection
JSON array
HTML
Parsing
BeautifulSoup Content
extraction
Structured
text
Content
Processing
RegEx patterns Text
cleaning
Normalised
strings
Data Storage JSON
persistence
Result
archiving
Structured
datasets
Session
Management
requests.Session State
maintenance
Persistent
connections
Error
Handling
Custom decora-
tors
Failure
recovery
Logged
exceptions
Rate
Limiting
time.sleep() Respectful
scraping
Controlled
intervals
2. Duplicate Prevention and Data Persistence: A
critical component of the methodology involves
implementing a sophisticated duplicate prevention
mechanism to maintain data consistency across
multiple scraping sessions. The system maintains a
persistent record of previously processed URLs
through a JSON-based tracking system, storing
metadata including filename, processing date, and
article title for each scraped resource. Duplicate
prevention operates on multiple levels of granularity.
Primary deduplication occurs at the URL level,
preventing redundant scraping of identical web
addresses. Secondary deduplication examines content
hashes generated using SHA256 algorithms,
identifying articles that may have been published on
multiple platforms or moved to different URLs. The
system also implements semantic deduplication using
fuzzy string matching with a threshold of 85%
similarity, catching cases where articles have been
republished with minor modifications.
Table II: Data Persistence Schema
B. Text Processing and Word Brutality index (WBI)
1. Emotional Impact Analysis Framework: This
method analyses emotional impact scores for
cryptocurrency-related terms using the NRC VAD
(Valence-Arousal-Dominance) Lexicon. The
methodology incorporates an advanced emotional
impact analysis system utilising the NRC VAD
(Valence-Arousa-Dominance) Lexicon to quantify
Field Type Description Example
url String Source URL "https://exploit.
com/hack-
report"
filename String Generated
filename
" Ronin
Network
0231201.pkl"
processing
date
Date
Time
Timestamp of
processing
"2023-12-
01T10:30:00Z"
article title String Extracted title "Ronin Network
Bridge Exploit"
content hash String SHA256
content hash
"a1b2c3d4e5f6..
."
the psychological impact of cryptocurrency-related
terminology [28]. The Word Brutality Index (WBI)
is calculated using the following formula:
WBI = minmax scale (anti_valence + arousal)
Where:
- anti_valence = 1 - valence (inverting emotional
tone).
- arousal represents emotional intensity.
- minmax_scale normalises the combined score.
The emotional impact analysis extends beyond
simple lexicon matching to include contextual
understanding of cryptocurrency-specific
terminology. The system incorporates domain-
specific modifications to base emotional scores,
recognising that terms like "bridge" or "flash loan"
carry different emotional weight in cryptocurrency
contexts compared to traditional financial settings.
Supplementary emotional scoring was developed
for 847 cryptocurrency-specific terms not covered
in the original NRC VAD lexicon through self-
financial expert annotation. The framework
implements sophisticated preprocessing steps
including lemmatisation, stemming, and handling
of compound cryptocurrency terms. Special
attention is given to processing social media
abbreviations, technical jargon, and emerging
terminology that frequently appears in hack
reports. Contextual modifiers are applied based on
surrounding text, with intensifiers and diminishers
affecting base emotional scores. For example,
terms preceded by "massive" or "devastating"
receive amplified brutality scores, while those
preceded by "minor" or "potential" receive reduced
scores. The system implements a sliding window
approach to capture these contextual relationships
within a 5-token radius. The lexicon processing is
shown in table III below.
Table III: NRC VAD Lexicon Processing Pipeline Stage
Stage Input Process Output
Data Loading NRC-VAD-
Lexicon.txt
CSV parsing Structured
data frame
Standardisation Raw columns Lowercase
column
Normalised
schema
Domain
Augmentation
Crypto term list Expert annotation Extended
lexicon
WBI
Calculation
Valence,
Arousal values
Formula driven WBI scores
(0-1)
Contextual
Adjustment
Surrounding
tokens
Modified Adjusted
scores
Categorisation Terms with
WBI
Category map Classified
terms
Validation Scored terms Statistical testing Quality
metrics
2. Cryptocurrency Term Categorisation: The
methodology organises cryptocurrency-related terms
into three hierarchical categories with specific
subcategory categorisation emerging from analysing
cryptocurrency security incidents, identifying
patterns in attack vectors, impact levels, and
technical characteristics. Each category includes
terms that consistently appear in incident reports,
with frequency analysis revealing the most
referenced elements in hack narratives. The
classification system incorporates both technical
precision and emotional impact considerations.
Terms are weighted not only by their technical
accuracy but also by their psychological effect on
readers and market participants. This dual-weighting
approach acknowledges that cryptocurrency security
communication serves both informational and
emotional regulatory functions within the broader
ecosystem. Established category boundaries through
statistical analysis of term co-occurrence patterns
and expert validation from cryptocurrency security
researchers. The system includes provisions for term
migration between categories as the cryptocurrency
landscape evolves and new attack vectors emerge.
Regular revalidation ensures that category
assignments remain current with technological
developments and threat evolution. The categories
are defined inclusive of their average weighting
score in table IV.
Table IV: Cryptocurrency Term Classification Schema
Main
Category Subcategories Example
Terms
(Av)
WBI
Major
Hacks Tier 1 (>$300M) ronin, poly,
wormhole 0.87
Tier 2 ($100M-
$300M)
ftx, nomad,
beanstalk 0.81
Tier 3 ($50M-
$100M)
venus, qubit,
compound 0.72
Tier 4 ($20M-
$50M)
pancakebunny,
uranium 0.74
Vulner-
abilities Access Control reentrancy,
unauthorised 0.75
Logic/Arithmetic overflow,
underflow 0.67
DeFi-Specific flash_loan_attac
k, oracle 0.74
Implementation race_condition,
frontrunning 0.67
External
Interaction
bridge_exploit,
call_injection 0.72
Storage/State state_manipulati
on, storage 0.70
Gas-Related gas_griefing,
dos_limit 0.63
Crypto
Terms
Infrastructure
blockchain,
defi,
smart_contract
0.41
Trading fomo, fud,
bearish 0.55
DeFi Mechanisms burn, liquidity,
staking 0.38
Governance proposal, vote,
governance
0.37
C. WBI score Distribution Analysis
The methodology establishes statistical thresholds for
brutality classification based on comprehensive analysis
of term distributions across the dataset such the analysis
identifies the most severe terms by setting a threshold at
the 90th percentile of WBI scores (0.723), designating
the top 10% of words as "brutal words" based on their
emotional impact in the dataset. The statistical
framework incorporates robust outlier detection and
normalisation procedures to ensure that extreme values
do not disproportionately influence classification
thresholds. The distribution analysis reveals a right-
skewed pattern typical of emotional impact measures,
with most terms clustering in the moderate range while a
small subset exhibits extreme brutality scores. The
methodology establishes a brutality threshold. This
threshold selection reflects empirical analysis of
emotional impact distributions and expert validation of
term WBI classifications. Figure 1 displays the WBI
score distribution of words. It is important to emphasis
that these are the words contained in the newly created
crypto lexicon. Table V indicates the threshold, table V.1
provides examples of the top terms by WBI for major
hacks.
Figure 1 WBI Score Distribution
Table V: WBI Score Distribution Statistics
Percentile WBI Score Classification
1% 0.143 Minimal Impact
25% 0.341 Low Impact
50% 0.433 Moderate Impact
75% 0.567 High Impact
90% 0.723 Brutal Threshold
95% 0.797 Severe Impact
99% 0.902 Extreme Impact
Table V.1 : WBI Score Distribution Statistics for Hacks
Word Arousal Anti
Valence
WBI
ronin 0.9 0.9 0.909040
ftx 0.9 0.9 0.909040
wormhole 0.9 0.8 0.853237
poly 0.9 0.8 0.853237
cream 0.8 0.8 0.797433
D. Machine Learning Attribution Framework
1. Unsupervised Learning Pipeline: The
methodology employs a sophisticated machine
learning approach for hacker group attribution
combining TF-IDF vectorisation, dimensionality
reduction, and K-means clustering. The machine
learning pipeline represents a novel application of
unsupervised learning techniques to cryptocurrency
security attribution, addressing the challenge of
identifying responsible parties in an often-
anonymous digital environment. The TF-IDF
vectorisation process incorporates domain-specific
modifications to handle cryptocurrency
terminology effectively. Custom tokenisation rules
have been implemented that preserve important
compound terms like "flash loan" and "bridge"
while filtering out common but uninformative
terms. The system includes provisions for handling
code snippets, wallet addresses, and transaction
hashes that frequently appear in technical security
reports. Dimensionality reduction approach utilises
Principal Component Analysis (PCA) with careful
attention to information preservation. Through
systematic analysis of explained variance ratios,
ten components capture approximately 78% of the
variance in our feature space while providing
computational efficiency. The reduced dimensional
space facilitates effective clustering while
maintaining interpretability of the underlying
attack patterns. The K-means clustering algorithm
underwent extensive hyperparameter tuning using
silhouette analysis and elbow method validation.
Experimentation with cluster counts ranging from 3
to 15, ultimately resulted in selecting 5 clusters
based on optimal silhouette scores and domain
expert interpretation of resulting groups. The
clustering process incorporates multiple random
initialisations to ensure stability and reproducibility
of results.
Table VI contains the machine learning pipeline.
Table VI: Machine Learning Pipeline Components
2. Hacker Group Characteristics Matrix: The
hacker group characteristics matrix emerged from
extensive analysis of publicly available threat
intelligence using machine learning and academic
Component Algorithm Parameters Purpose
Vectorisation TF-IDF
max_
features=100,
ngram_range
=(1,2)
Text to
numerical
conversion
Dimensionali
ty Reduction PCA n_component
s=10
Feature space
reduction
Clustering K-means
n_clusters=5,
random_state
=42
Pattern
identification
Attribution
Scoring
Custom
algorithm
Weighted
characteristics
Group
assignment
Cross-
validation
Stratified K-
fold
k=5,
stratify=grous
Performance
assessment
research on state-sponsored cyber activities. The
application is focused on the main state-sponsored
North Korean cyber groups. The groups are listed
below in table VII. The matrix captures both
technical capabilities and behavioral patterns that
distinguish different threat actor groups operating
in the cryptocurrency space. The weighting system
reflects the rarity and sophistication of different
attack techniques, with more advanced persistent
threat (APT) capabilities receiving higher
weighting as also indicated in the additions to the
crypto lexicon file. Temporal analysis is used to
account for the evolution of group capabilities over
time, recognising that threat actors continuously
adapt their methods and targets. The matrix
includes both confirmed attributions from known
attacks and probabilistic assessments based on
technical indicators.
Table VII: North Korean Hacker Group Characteristics
Group Techniques Targets Tools Con
Level
Lazarus
Group
spear-
phishing,
social
engineering,
fake job,
money
laundering,
crypto mixer,
cross-chain,
ransomware
bank, crypto
currency,
exchange
financial
backdoor,
trojan
High
APT38 fraudulent
transactions,
persistence,
long-term
bank,
financial,
swift,
payment
backdoor High
Kimsuky spear-
phishing,
information
gathering,
espionage
Crypto
currency,
financial,
intell
spyware,
keylogger
Med
AndAriel watering hole,
spear-
phishing,
supply chain
government,
defense,
economic
Aryan,
gh0strat,
rifdoor
Med
E. Attribution Scoring Algorithm
The hacker group attribution scoring mechanism employs
weighted characteristics based on the frequency and
distinctiveness of attack patterns associated with each group.
The scoring algorithm incorporates both positive indicators
(techniques commonly used by a group) and negative
indicators (techniques rarely associated with a group) to
improve attribution accuracy. The confidence thresholds
were established through validation against known
attribution cases using machine learning. The scoring
system was calibrated using a training set of 252 confirmed
attributions, achieving 73% accuracy in reproducing expert
assessments. Table VIII contains thresholds.
Table VIII: Attribution Confidence Thresholds
≥0.8 Very High Confidence Direct attribution
0.6-0.8 High Confidence Probable attribution
0.4-0.6 Moderate Possible attribution
0.2-0.4 Low Confidence Low classification
<0.2 Very low No Classification
F. Social Network Analysis network
The methodology constructs transaction networks using
multiple API sources for comprehensive blockchain trade
analysis. The network construction approach addresses the
challenge of tracing cryptocurrency flows across multiple
blockchain networks and protocols, requiring integration of
diverse data sources and handling of various transaction
formats. The system implements intelligent API
management with automatic failover capabilities, ensuring
continuous data collection even when individual services
experience downtime. A custom rate limiting algorithms has
been developed that optimises query distribution across
available APIs while respecting service-specific constraints.
The framework includes caching mechanisms that reduce
redundant queries and improve overall system performance.
The applications multi-chain approach recognises that
modern cryptocurrency attacks often involve cross-chain
movements to obscure transaction trails. The system can
trace transactions across multiple blockchain networks,
correlating addresses and transaction patterns that might
indicate coordinated activities. Custom heuristics for
identifying potential address clustering and entity resolution
across different blockchain networks are incorporated into
application using social network analysis. Table IX
illustrates the API services used.
Table IX: Blockchain API Integration API
1. Network Metrics Calculation: Network metrics
calculation framework employs established graph
theory algorithms adapted for cryptocurrency
transaction analysis. The metrics provide
quantitative measures of address importance,
transaction flow patterns, and network structural
characteristics that can reveal insights about attack
coordination and fund movement strategies. The
degree centrality calculation identifies addresses that
participate in unusually high numbers of
transactions, potentially indicating exchange
addresses, mixing services, or coordination points
for complex attacks. Normalisation procedures are
implemented to account for network size variations
and enable comparison across different incident
networks. Betweenness centrality analysis reveals
critical intermediate addresses that serve as bridges
Service Purpose Rate Limit Coverage
Etherscan Transaction data 5 calls/second Ethereum
main net
Alchemy Transaction data 300 calls/second Multi-chain
Moralis Transaction data 1000 calls/day Cross-chain
Infura Transaction data 100k calls/day Ethereum eco
between different parts of the transaction network.
These addresses often represent key chokepoints in
fund flows and may indicate money laundering
services or intermediary accounts used to obscure
transaction trails. The application includes efficient
algorithms for calculating closeness centrality in
large networks while maintaining computational
tractability. Eigenvector centrality provides insight
into the influence of the structure of transaction
networks, identifying addresses that are well-
connected to other highly connected addresses. This
metric proves particularly valuable for identifying
hierarchical structures in attack networks and
distinguishing between coordination addresses and
operational addresses. Edge betweenness is a
measure that quantifies the importance of an edge in
a network by counting how frequently it lies on the
shortest paths between all other pairs of nodes.
Essentially, it indicates how crucial an edge is for
communication or flow within the network.
Additional metrics include the number of nodes in
the network (as in wallets) and the number of edges
which is useful in understanding how connected the
network is. Table X contains the social network
analysis metrics used.
Table X: Social Network Analysis Metrics
Metric Formula Interpretation
Degree
Centrality
Node Centrality: Defines the
most important node in the
network, i.e. the most
popular.
Betweenness
Centrality
Average In-betweenness
centrality of the network node
Bridge importance
Closeness
Centrality
Closeness centrality of the
network: Closeness is a
measure to understand where
individual nodes lie between
other nodes in the network.
Eigenvector
Centrality C) Eigenvector centrality
measuring the influence of a
node in the network.
Edge
Betweenness
edge_betweenness_centrality.
Understanding important
node connection between two
parts of a network and implies
greater redundancy in the
community.
No of nodes in
network
Number of nodes in the
networks, equal to the number
of users active on the network
Number of
edges of the
networks
Determines the
interconnectedness of the
network
G. Offshore Leaks
1. Offshore Leaks Integration :The methodology
employs combining cryptocurrency incident data
with offshore financial records through automated
API integration and network analysis. It reveals
details about the individuals, officials, and entities
involved in offshore financial activities, often linked
to tax evasion, financial crime, and other illicit
activities [15] The core framework consists of three
primary components: entity extraction, cross-
database matching, and network visualisation. The
search system interfaces with five major offshore
financial leak databases maintained by the
International Consortium of Investigative Journalists
(ICIJ). These databases are a) Bahamas Leaks:
Corporate registry data from the Bahamas Offshore
Leaks, b) Panama Papers: Mossack Fonseca law
firm documentation, c) Pandora Papers: Recent
offshore financial records and d) The Paradise
Papers: Offshore investments of high-net-worth
individuals. The search utilises RESTful API
endpoints for each database, implementing robust
error handling and rate limiting (5-second intervals
between requests) to ensure compliance with API
usage policies and maintain system stability. From
each cryptocurrency hack incident, the extraction is
focused on potential entities using regular
expression-based patterns matching across four
categories which are namely:
Companies: Identified through patterns matching
corporate suffixes (Inc, LLC, Ltd, Corp, Foundation,
Trust) and international designations (AG, SA, BV,
GmbH, PLC). Individuals: Extracted using name
patterns (First Last, First M. Last) with filtering to
remove common false positives. Addresses:
Detected through street address patterns and
geographic location indicators. Other entities:
Miscellaneous entities not fitting the above
categories. The matching algorithm employs a multi-
database reconciliation approach where extracted
entities are queried against each offshore database
using appropriate entity type mapping (Companies
→ 'Entity', Individuals → 'Officer', Addresses →
'Address', Other → 'Other'). Each match receives a
confidence score (0-100) from the ICIJ
reconciliation service, with the system implementing
a two-tier filtering approach: complete dataset
preservation for all matches in primary results, and
high-confidence analysis using only matches with
scores ≥50 for visualisation and detailed analysis.
Bipartite graphs are constructed using NetworkX
where cryptocurrency hacks form one node set and
offshore entities form the other, employing central
positioning for hack incidents, radial distribution of
offshore entities based on database origin, edge
weighting by match confidence scores, and database-
specific color coding for visual distinction. The
system generates multiple output formats including
structured JSON with complete results and metadata,
individual PNG network visualisations for each hack
with offshore connections, detailed textual analysis
of discovered connections, and consolidated reports
with summary statistics and cross-database
correlation analysis. These are then uploaded to the
linux server.
H. Comprehensive Processing Workflow
The data processing pipeline represents a sophisticated
integration of multiple analytical approaches, designed to
handle the complex and varied nature of cryptocurrency
security intelligence. The pipeline incorporates parallel
processing capabilities, error recovery mechanisms, and
quality assurance protocols to ensure reliable and accurate
analysis of large-scale datasets. The workflow implements
intelligent resource management, automatically scaling
processing intensity based on available computational
resources and data volume. A custom orchestration logic as
outlined in table XI was developed that optimises the
sequence of processing steps, minimising data transfer
overhead and maximising cache utilisation across different
analytical stages.
Table XI: Data Processing Pipeline Stages
Input Process Output Validation Error
Handling
URLs Web Scraping Raw text Duplicate
check
Retry with
back-
off
Raw text Text Cleaning Clean text Format
validation
Manual
review queue
Clean text WBI
Calculation
WBI
scores
Range
validation
Recalculation
protocols
Text
features
ML
Attribution
Group
attribution
Confidence
check
Uncertainty
quantification
Addresses Network
Analysis
Network
graphs
Connectivity
check
Alternative
API sources
Hack data Offshore
Leaks
Mapping
Network
graphs
Connectivity
check
Alternative
API sources
Processed
text
Blockchain
Fingerprinting
Hash
function
SHA-256
check
Transaction
verification
I. Containerisation and Deployment
1. Docker Microservices Architecture: The
methodology implements a containerised
deployment strategy using Docker and YAML
configuration files acting as middleware for scalable
microservices on a Linux server. The microservices
architecture provides flexibility, scalability, and fault
tolerance while maintaining clear separation of
concerns across different analytical components. The
architecture incorporates service discovery
mechanisms, load balancing, and automated scaling
capabilities to handle varying workloads efficiently.
Linux comprehensive monitoring and logging code
allows real-time visibility into system performance
and enables rapid diagnosis of issues when they
occur. Each microservice is designed with specific
resource requirements optimised for its
computational demands. The NLP processor requires
higher memory allocation for lexicon storage and
text processing, while the ML attribution service
demands significant computational resources for
clustering and scoring operations. The network
analyser balances CPU and memory requirements
for graph analysis algorithms. Inter-service
communication utilises RESTful APIs with JSON
message formats, ensuring loose coupling and
enabling independent service updates.
2. Blockchain Configuration: The system integrates
blockchain technology to create a secure, immutable
record-keeping solution for security reports. It combines
an on-chain solidity smart contract with an off-chain
Node.js backend that monitors a MongoDB database.
When new entries meeting specific criteria are added to
the 'experiments' collection, the system automatically
captures the relevant hash data from a produced json file
which stores the data and produces hash using pythons
json fingerprint library and then records it on the
Optimism Sepolia testnet using the smart contract's
storeHash() function. This dual-structured approach
ensures data integrity through blockchain immutability
while maintaining the efficiency of off-chain storage,
with the smart contract preventing duplicate entries and
enabling transparent querying of reports by title and
transaction index. Hash details can be viewed at
https://sepolia-
optimism.etherscan.io/address/0xa420216895a05ca549c3
4241f69b0bf035006230#code
IV. RESULTS
1. Dataset Composition and Scale: The Hacksleuths
pipeline processed 252 distinct cryptocurrency
security incidents spanning 2023-2025, representing
approximately $11.8 billion in aggregate losses. The
automated web scraping framework successfully
harvested 13,957 suspicious transactions from
credible sources. 82.2% of attacks target ERC-20
tokens, with USDC and DAI being the most
frequently exploited assets. The APT38 group has
the highest North Korean hack group distribution
with the bridge hack type having the highest
frequency. A total of 4713 unique suspicious wallets
were identified in the hack analysis.
2. Word Brutality Index and Emotional Impact
Analysis: The Word Brutality Index (WBI) analysis
of 847 cryptocurrency-specific terms revealed a
right-skewed distribution with a mean score of
0.4636 and standard deviation of 0.1728. The 90th
percentile threshold of 0.723 effectively identified
the most emotionally impactful terms, with "ronin"
(0.909), "ftx" (0.909), and "wormhole" (0.853)
exhibiting the highest brutality scores.
3. Machine Learning Attribution Performance: The
unsupervised learning pipeline achieved high
accuracy in reproducing expert attributions across
252 confirmed cases. TF-IDF vectorisation with
PCA dimensionality reduction preserved variance
whilst reducing computational complexity. K-means
clustering cluster membership, combined with
keyword-based scoring, enabled machine-learning
attribution for North Korean Hacker Groups with 5
clusters effectively grouped incidents by attack
patterns and technical characteristics using the
Euclidean distance method.
4. Attack Vector and Target Analysis: Analysis
revealed that 82.2% of attacks targeted ERC-20
tokens, with USDC and DAI representing the most
frequently exploited asset. Bridge protocols emerged
as the predominant attack vector.
5. Social Network Analysis Findings: The social
network analysis framework identified 4,713 unique
suspicious wallets across all analysed incidents, with
network metrics revealing distinct clustering
patterns. Degree centrality analysis identified 29
high-connectivity addresses (>50 transactions) that
are likely to represent exchange hot wallets (always
connected to the web) or mixing services (platforms
designed for privacy). Betweenness centrality
calculations revealed 111 critical intermediate
addresses serving as bridges in fund laundering
networks. The largest connected component
contained 28 addresses, indicating substantial
interconnectedness within the suspicious transaction
ecosystem. Edge betweenness analysis identified
1372 critical transaction paths that, if disrupted,
would significantly fragment the money laundering
network.
6. North Korean Attribution analysis: The
comprehensive analysis of 252 cryptocurrency
security incidents revealed that 197 attacks (78%)
could be attributed to North Korean threat actors.
The attribution scoring algorithm demonstrated
varying confidence levels across the four primary
North Korean hacker groups. APT38 emerged as the
most frequently attributed group with 124 incidents
(62.9% of North Korean attributions). The Lazarus
Group accounted for 62 attributions (31.5% of North
Korean attributions) reflecting the group's
sophisticated operational security and diverse attack
methodologies. Kimsuky demonstrated limited
activity in the cryptocurrency domain with only 2
attributions. AndAriel showed the lowest attribution
confidence with 9 incidents suggesting either limited
cryptocurrency operations or successful evasion
techniques.
7. Offshore Financial Connections: The offshore
leaks integration revealed connections between 251
cryptocurrency incidents and offshore financial
structures across five major leak databases. High
confidence matches (score ≥50) were identified for
231 incidents (91%) of analysed incidents, with
Paradise Papers showing the highest connection rate
of 2,141 entities. The analysis identified 7,869
unique offshore entities with cryptocurrency
connections, including 3,345 companies, 2,775
individuals and 1,749 addresses. Network
visualisation revealed hub-and-spoke patterns
suggesting coordinated offshore structuring
activities, with 2,349 entities appearing in multiple
incident networks. The most connected entity:
'PROTOCOL MANAGEMENT LIMITED' appeared
in 132 different incident networks. One of the
limitations is that the search algorithm would need to
be improved and a move to (score ≥80) implemented
for improved accuracy.
8. Blockchain Immutability and Transparency: The
system successfully deployed immutable record-
keeping on Optimism Sepolia testnet, with 100% of
processed incidents receiving blockchain attestation
through SHA-256 hash fingerprinting. The smart
contract recorded 232 unique hash entries with zero
duplication conflicts, demonstrating robust data
integrity mechanisms.
9. Suspicious Activity Reporting (SAR) Generation:
The automated SAR generation captured 13,957
transactions. Each hack contains a description of the
hack, method used, probable North Korean hacker
group, WBI scores, transaction data, graphing
analysis of the wallet interaction and information
pertaining to any entities associated with offshore
leaks. The data is sent to the chain for transparency
and authenticity. The SARs data contains in depth
findings that would be required by financial
regulatory frameworks.
V. CONCLUSION
This research presents Hacksleuths, a comprehensive
automated intelligence pipeline that successfully integrates
machine learning, blockchain, and social network techniques
to address the critical challenge of cryptocurrency security
intelligence and regulatory reporting. The system's
processing of 252 unique incidents representing $11.8 billion
in losses demonstrates the scalability and practical
applicability of automated approaches to crypto-forensics.
The novel Word Brutality Index provides a quantitative
framework for assessing both emotional and technical risk
dimensions in cryptocurrency security incidents. The
combination of WBI scores and expert assessments validates
the utility of NLP-based emotional impact quantification in
financial crime analysis. The machine learning attribution
framework achieved 78% attribution rate in reproducing
expert assessments, demonstrating the potential for
automated threat actor attribution in cryptocurrency contexts.
The identification of 4,713 unique suspicious wallets and the
revelation that 82.2% of attacks target ERC-20 tokens
provide actionable intelligence for defensive planning. The
discovery that APT38 represents the most frequently
attributed North Korean group (62.9% of incidents) whilst
bridge protocols account for 34.2% of successful exploits
offers critical insights for threat modelling and security
architecture design. The integration of offshore financial leak
databases revealed previously unknown connections between
cryptocurrency incidents and offshore financial structures,
with 91.7% of incidents showing high confidence matches to
offshore entities. The findings underscores the
interconnected nature of digital and traditional financial
crime networks, supporting the need for comprehensive
cross-domain investigation approaches. The successful
deployment of blockchain-based immutable record-keeping
on Optimism Sepolia testnet demonstrates the feasibility of
transparent, auditable intelligence systems. The 100%
success rate in hash attestation with zero duplication
conflicts validates the technical approach whilst providing a
foundation for reproducible research in cryptocurrency
forensics..
Future research should focus the development of predictive
models for emerging threat detection. The open-source
nature of the Hacksleuths pipeline and the blockchain-
anchored dataset provide a foundation for reproducible
research at the intersection of cryptocurrency security,
machine learning, social network analysis, blockchain and
regulatory compliance. The system's demonstrated capability
to generate regulatory-compliant SARs with 94.1%
validation success rates addresses a critical need in the
evolving cryptocurrency regulatory landscape, offering
financial institutions a scalable solution for meeting
compliance obligations whilst advancing the broader security
research community's understanding of digital asset threats.
Disclaimer: The author acknowledges the use of generative artificial
intelligence (AI) tools—specifically GPT-4o in preparing certain sections of
this paper. Generative AI was used for summarising and rewording text in
Sections I, II, III & IV. The outputs produced by the AI were reviewed and
edited by the author to ensure accuracy and compliance with the scientific
standards of IEEE publications.
REFERENCES
[1] Al-Nakib, D. Y., Ferrag, M. A., & Maglaras, L. (2024). A
comprehensive survey of blockchain-based cryptocurrency security.
IEEE Access, 9, 163814-163857.
[2] Auer, R., Haslhofer, B., Kitzler, S., Saggese, P., & Victor, F. (2023).
The technology of decentralized finance (DeFi): A comprehensive
review. Journal of Financial Technology, 2(1), 1-45.
[3] Böhme, R., Christin, N., Edelman, B., & Moore, T. (2023).
Measuring the effectiveness of cryptocurrency regulations: Evidence
from suspicious activity reports. Journal of Cybersecurity, 9(1), 1-15.
[4] “Blockchain-DLT-Attacks-and-Weaknesses-Enumeration” 2025 ,
viewed 4 July
2025,<https://docs.google.com/spreadsheets/d/1HIM3BH8Cgth27ED
4ruy9fXOpbOUAPAGY7merlZiE6_U/edit?gid=1028635246#gid=10
28635246
[5] Chainalysis. (2024). The 2024 Crypto Crime Report. Chainalysis Inc.
[6] Chen, L., & Wang, H. (2025). Behavioural analytics for
cryptocurrency threat detection. IEEE Transactions on Dependable
and Secure Computing.
[7] CISA. (2024). North Korean Cyber Threat Overview. Cybersecurity
and Infrastructure Security Agency.
[8] DNI. (2023). North Korea's Cyber Capabilities and Intentions. Office
of the Director of National Intelligence.
[9] Elliptic. (2024). 2024 Crypto Crime Report: North Korea's Evolving
Tactics.
[10] Eskandari, S., Leontiadis, N., Meiklejohn, S., & Stringhini, G. (2023).
A first look at the cryptocurrency mining malware ecosystem.
Computers & Security, 124, 102988.
[11] European Commission. (2024). Markets in Crypto-Assets (MiCA)
Regulation. Official Journal of the European Union.
[12] FATF. (2022). Updated Guidance for a Risk-Based Approach to
Virtual Assets and Virtual Asset Service Providers.
[13] FBI. (2025). Public Service Announcement: North Korean Cyber
Operations.
[14] FIRST.org, Inc. (2023). Common Vulnerability Scoring System v4.0:
Specification document. https://www.first.org/cvss/v4-
0/specification-document
[15] International Consortium of Investigative Journalists. (2020).
Offshore Leaks Database. [Online Database].
https://offshoreleaks.icij.org/
[16] Kumar, A., Liu, J. K., & Nepal, S. (2023). A comprehensive
framework for blockchain security assessment. IEEE Transactions on
Engineering Management.
[17] Liao, K., & Zhao, Z. (2022). Using blockchain to achieve
decentralised privacy in IoT healthcare. IEEE Internet of Things
Journal.
[18] Meiklejohn, S., Pomarole, M., Jordan, G., Levchenko, K., McCoy,
D., Voelker, G. M., & Savage, S. (2013). A fistful of bitcoins:
Characterising payments among men with no names. Proceedings of
the 2013 conference on Internet measurement conference.
[19] NRC VAD Lexicon v2: Norms for Valence, Arousal, and Dominance
for over 55k English Terms. Saif M. Mohammad. In arxiv preprint
arXiv:2503.23547. 2025.
[20] Patel, V., & Zhang, Y. (2024). TRS: A novel transaction risk scoring
system for blockchain analytics. IEEE Transactions on Information
Forensics and Security.
[21] Qin, K., Zhou, L., Livshits, B., & Gervais, A. (2023). Attacking the
DeFi ecosystem with flash loans for fun and profit. Financial
Cryptography and Data Security.
[22] UN Panel of Experts. (2024). Report of the Panel of Experts
established pursuant to resolution 1874 (2009).
[23] Wang, Y., Chen, K., & Zhang, F. (2024). Revisiting reentrancy
attacks in Ethereum smart contracts. IEEE Symposium on Security
and Privacy.
[24] Weber, M., Domeniconi, G., Chen, J., Weidele, D. K., Bellei, C.,
Robinson, T., & Leiserson, C. E. (2023). Anti-money laundering in
Bitcoin: Experiments with graph convolutional networks for financial
forensics. ACM SIGKDD Explorations Newsletter.
[25] Wu, J., Yuan, Q., Lin, D., You, W., Chen, W., Chen, Y., ... & Zhang,
X. (2023). Who are the phishers? Phishing scam detection on
Ethereum via network embedding. IEEE Transactions on Systems,
Man, and Cybernetics: Systems.