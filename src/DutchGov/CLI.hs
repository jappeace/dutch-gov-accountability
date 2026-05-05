{-# LANGUAGE OverloadedStrings #-}

module DutchGov.CLI
  ( Command(..)
  , CollectOptions(..)
  , StatusOptions(..)
  , parseCommand
  ) where

import Data.Text (Text)
import Options.Applicative

import DutchGov.Collector (Source(..))

data Command
  = Collect CollectOptions
  | Status StatusOptions
  deriving (Show)

data CollectOptions = CollectOptions
  { collectDb     :: Text
  , collectSource :: Source
  } deriving (Show)

data StatusOptions = StatusOptions
  { statusDb :: Text
  } deriving (Show)

parseCommand :: IO Command
parseCommand = execParser opts
  where
    opts = info (commandParser <**> helper)
      ( fullDesc
      <> progDesc "Dutch government public spending data collector"
      <> header "dutch-gov-accountability - CBS + Rijksfinancien open data collector"
      )

commandParser :: Parser Command
commandParser = subparser
  ( command "collect" (info collectParser (progDesc "Collect data from public government APIs"))
  <> command "status" (info statusParser (progDesc "Show database status"))
  )

collectParser :: Parser Command
collectParser = Collect <$> (CollectOptions
  <$> dbOption
  <*> sourceOption)

statusParser :: Parser Command
statusParser = Status <$> (StatusOptions <$> dbOption)

dbOption :: Parser Text
dbOption = strOption
  ( long "db"
  <> metavar "FILE"
  <> help "SQLite database file path"
  <> value "spending.db"
  <> showDefault
  )

sourceOption :: Parser Source
sourceOption = option readSource
  ( long "source"
  <> metavar "SOURCE"
  <> help "Data source to collect: cbs, rijksfinancien, or all"
  <> value SourceAll
  <> showDefault
  )

readSource :: ReadM Source
readSource = eitherReader $ \s -> case s of
  "cbs"             -> Right SourceCbs
  "rijksfinancien"  -> Right SourceRijksfinancien
  "all"             -> Right SourceAll
  other             -> Left $ "Unknown source: " ++ other
                           ++ ". Expected cbs, rijksfinancien, or all."
