{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import qualified Data.Text as Text
import Database.Persist.Sqlite (runSqlPool)

import DutchGov.CLI
import DutchGov.Database (withDatabase, getSyncMeta)
import DutchGov.Collector (collectAll)

main :: IO ()
main = do
  cmd <- parseCommand
  case cmd of
    Collect opts -> do
      withDatabase (collectDb opts) $ \pool ->
        collectAll (collectSource opts) pool
    Status opts -> do
      withDatabase (statusDb opts) $ \pool -> do
        cbsTime <- runSqlPool (getSyncMeta "cbs_last_sync") pool
        rfjTime <- runSqlPool (getSyncMeta "rijksfinancien_last_sync") pool
        putStrLn "Database status:"
        putStrLn $ "  CBS last sync: " ++ maybe "never" Text.unpack cbsTime
        putStrLn $ "  Rijksfinancien last sync: " ++ maybe "never" Text.unpack rfjTime
