{-# LANGUAGE OverloadedStrings #-}

module DutchGov.DatabaseTest (tests) where

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Logger (runNoLoggingT)
import Database.Persist.Sqlite
import Test.Tasty
import Test.Tasty.HUnit

import DutchGov.CBS.Client (CbsExpenditure(..))
import DutchGov.Database
import DutchGov.Rijksfinancien.BudgetTable (BudgetRow(..))
import DutchGov.Schema

-- | Run a database action in an in-memory SQLite database.
withTestDb :: (ConnectionPool -> IO a) -> IO a
withTestDb action = runNoLoggingT $
  withSqlitePool ":memory:" 1 $ \pool -> do
    liftIO $ runSqlPool (runMigration migrateAll) pool
    liftIO $ action pool

tests :: TestTree
tests = testGroup "Database raw SQL upserts"
  [ testCase "expenditure insert and retrieve" $ withTestDb $ \pool -> do
      let row = CbsExpenditure
            { ceTransactionKey = "T001"
            , ceFunctionKey = "F001"
            , ceSectorKey = "S001"
            , cePeriodKey = "2023JJ00"
            , ceAmountMlnEur = Just 42.5
            }
      runSqlPool (upsertExpenditures [row]) pool
      results <- runSqlPool (selectList [] []) pool
      let entities = map entityVal results :: [Expenditure]
      length entities @?= 1
      expenditureTransactionKey (entities !! 0) @?= "T001"
      expenditureFunctionKey (entities !! 0) @?= "F001"
      expenditureSectorKey (entities !! 0) @?= "S001"
      expenditurePeriodKey (entities !! 0) @?= "2023JJ00"
      expenditureAmountMlnEur (entities !! 0) @?= Just 42.5

  , testCase "expenditure with null amount" $ withTestDb $ \pool -> do
      let row = CbsExpenditure
            { ceTransactionKey = "T002"
            , ceFunctionKey = "F002"
            , ceSectorKey = "S002"
            , cePeriodKey = "2022JJ00"
            , ceAmountMlnEur = Nothing
            }
      runSqlPool (upsertExpenditures [row]) pool
      results <- runSqlPool (selectList [] []) pool
      let entities = map entityVal results :: [Expenditure]
      length entities @?= 1
      expenditureAmountMlnEur (entities !! 0) @?= Nothing

  , testCase "expenditure upsert replaces amount" $ withTestDb $ \pool -> do
      let row1 = CbsExpenditure
            { ceTransactionKey = "T001"
            , ceFunctionKey = "F001"
            , ceSectorKey = "S001"
            , cePeriodKey = "2023JJ00"
            , ceAmountMlnEur = Just 10.0
            }
          row2 = row1 { ceAmountMlnEur = Just 99.9 }
      runSqlPool (upsertExpenditures [row1]) pool
      runSqlPool (upsertExpenditures [row2]) pool
      results <- runSqlPool (selectList [] []) pool
      let entities = map entityVal results :: [Expenditure]
      length entities @?= 1
      expenditureAmountMlnEur (entities !! 0) @?= Just 99.9

  , testCase "budget entry insert and retrieve" $ withTestDb $ \pool -> do
      let row = BudgetRow
            { brMinister = Just "Defensie"
            , brChapterName = Just "Defensie"
            , brChapterNumber = "X"
            , brArticleName = Just "Inzet"
            , brArticleNumber = "01"
            , brSubArticleName = Just "Gereedstelling"
            , brSubArticleNumber = "01.01"
            , brInstrumentName = Just "Bekostiging"
            , brInstrumentNumber = "01.01.01"
            , brRegulationName = Just "Materieel"
            , brRegulationNumber = "01.01.01.01"
            , brVuo = "U"
            , brAmount = 1500000
            }
      runSqlPool (upsertBudgetEntries 2024 "OWB" [row]) pool
      results <- runSqlPool (selectList [] []) pool
      let entities = map entityVal results :: [BudgetEntry]
      length entities @?= 1
      budgetEntryYear (entities !! 0) @?= 2024
      budgetEntryPhase (entities !! 0) @?= "OWB"
      budgetEntryMinister (entities !! 0) @?= Just "Defensie"
      budgetEntryChapterNumber (entities !! 0) @?= "X"
      budgetEntryArticleNumber (entities !! 0) @?= "01"
      budgetEntryAmount (entities !! 0) @?= 1500000
      budgetEntryVuo (entities !! 0) @?= "U"

  , testCase "budget entry upsert replaces amount" $ withTestDb $ \pool -> do
      let row1 = BudgetRow
            { brMinister = Just "Defensie"
            , brChapterName = Just "Defensie"
            , brChapterNumber = "X"
            , brArticleName = Nothing
            , brArticleNumber = "01"
            , brSubArticleName = Nothing
            , brSubArticleNumber = ""
            , brInstrumentName = Nothing
            , brInstrumentNumber = ""
            , brRegulationName = Nothing
            , brRegulationNumber = ""
            , brVuo = "U"
            , brAmount = 1000
            }
          row2 = row1 { brAmount = 2000 }
      runSqlPool (upsertBudgetEntries 2024 "OWB" [row1]) pool
      runSqlPool (upsertBudgetEntries 2024 "OWB" [row2]) pool
      results <- runSqlPool (selectList [] []) pool
      let entities = map entityVal results :: [BudgetEntry]
      length entities @?= 1
      budgetEntryAmount (entities !! 0) @?= 2000

  , testCase "budget entry with null optional fields" $ withTestDb $ \pool -> do
      let row = BudgetRow
            { brMinister = Nothing
            , brChapterName = Nothing
            , brChapterNumber = "IX"
            , brArticleName = Nothing
            , brArticleNumber = "02"
            , brSubArticleName = Nothing
            , brSubArticleNumber = "02.01"
            , brInstrumentName = Nothing
            , brInstrumentNumber = "02.01.01"
            , brRegulationName = Nothing
            , brRegulationNumber = "02.01.01.01"
            , brVuo = "O"
            , brAmount = 500
            }
      runSqlPool (upsertBudgetEntries 2025 "JV" [row]) pool
      results <- runSqlPool (selectList [] []) pool
      let entities = map entityVal results :: [BudgetEntry]
      length entities @?= 1
      budgetEntryMinister (entities !! 0) @?= Nothing
      budgetEntryChapterName (entities !! 0) @?= Nothing
      budgetEntryVuo (entities !! 0) @?= "O"
      budgetEntryAmount (entities !! 0) @?= 500
  ]
