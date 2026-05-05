[![Github actions build status](https://img.shields.io/github/actions/workflow/status/jappeace/dutch-gov-accountability/ci.yaml?branch=master)](https://github.com/jappeace/dutch-gov-accountability/actions)

# dutch-gov-accountability

Collects Dutch government spending data from public APIs (CBS and Rijksfinancien) into a local SQLite database for analysis and accountability.

## Entity Relationship Diagram

```
┌─────────────────┐       ┌─────────────────┐
│  GovFunction    │       │ CbsTransaction  │
├─────────────────┤       ├─────────────────┤
│ cbsKey (PK)     │       │ cbsKey (PK)     │
│ title           │       │ title           │
│ description?    │       │ description?    │
│ categoryGroupId?│       │ categoryGroupId?│
└────────┬────────┘       └────────┬────────┘
         │ functionKey              │ transactionKey
         │                         │
         ▼                         ▼
┌──────────────────────────────────────────────┐
│                Expenditure                    │
├──────────────────────────────────────────────┤
│ transactionKey  ─────────────────────────────┤──► CbsTransaction.cbsKey
│ functionKey     ─────────────────────────────┤──► GovFunction.cbsKey
│ sectorKey       ─────────────────────────────┤──► Sector.cbsKey
│ periodKey       ─────────────────────────────┤──► Period.cbsKey
│ amountMlnEur?   (Double, millions of euros)  │
│ UNIQUE(transactionKey, functionKey,          │
│        sectorKey, periodKey)                 │
└──────────────────────────────────────────────┘
         ▲                         ▲
         │ sectorKey               │ periodKey
         │                         │
┌─────────────────┐       ┌─────────────────┐
│     Sector      │       │     Period      │
├─────────────────┤       ├─────────────────┤
│ cbsKey (PK)     │       │ cbsKey (PK)     │
│ title           │       │ title           │
│ description?    │       │ description?    │
│ categoryGroupId?│       │ status?         │
└─────────────────┘       └─────────────────┘


┌──────────────────────────────────────────────┐
│              BudgetEntry                      │
├──────────────────────────────────────────────┤
│ year             (Int)                        │
│ phase            (OWB/O1/O2/JV)              │
│ minister?                                    │
│ chapterName?     / chapterNumber             │
│ articleName?     / articleNumber              │
│ subArticleName?  / subArticleNumber          │
│ instrumentName?  / instrumentNumber          │
│ regulationName?  / regulationNumber          │
│ vuo              (U=uitgaven/O=ontvangsten/  │
│                   V=verplichtingen)           │
│ amount           (Int, euros)                │
│ UNIQUE(year, phase, chapterNumber,           │
│        articleNumber, subArticleNumber,       │
│        instrumentNumber, regulationNumber,   │
│        vuo)                                  │
└──────────────────────────────────────────────┘


┌─────────────────┐
│    SyncMeta     │
├─────────────────┤
│ key (PK)        │
│ value           │
└─────────────────┘
```

### Data sources

- **CBS 84122NED** — Government expenditures by function, transaction type, sector, and period. The four dimension tables (`GovFunction`, `CbsTransaction`, `Sector`, `Period`) are lookup tables; `Expenditure` is the fact table.
- **Rijksfinancien** — Budget tables at chapter/article/sub-article/instrument/regulation granularity, per year and budget phase.
- **SyncMeta** — Tracks last sync timestamps.

## Usage

```bash
nix-shell

# Collect all data
cabal run exe -- collect --db spending.db --source all

# Collect only CBS
cabal run exe -- collect --db spending.db --source cbs

# Collect only Rijksfinancien
cabal run exe -- collect --db spending.db --source rijksfinancien

# Check sync status
cabal run exe -- status --db spending.db
```
