{-# LANGUAGE OverloadedStrings #-}

module DutchGov.Rijksfinancien.Client
  ( Phase(..)
  , phaseToText
  , fetchBudgetTable
  , rijksfinancienBaseUrl
  ) where

import Control.Monad.IO.Class (MonadIO, liftIO)
import Data.Aeson (eitherDecode)
import qualified Data.ByteString.Lazy.Char8 as LBS
import Data.Text (Text)
import Network.HTTP.Client
import Network.HTTP.Types.Status (statusCode)

import DutchGov.Rijksfinancien.BudgetTable

rijksfinancienBaseUrl :: String
rijksfinancienBaseUrl = "https://www.rijksfinancien.nl/open-data/api/json/budgettaire_tabellen"

-- | Budget phases in the Dutch budget cycle
data Phase
  = OWB  -- ^ Ontwerpbegroting (draft budget)
  | O1   -- ^ Eerste suppletoire (1st supplementary)
  | O2   -- ^ Tweede suppletoire (2nd supplementary)
  | JV   -- ^ Jaarverslag (annual report / actuals)
  deriving (Show, Eq, Enum, Bounded)

phaseToText :: Phase -> Text
phaseToText OWB = "OWB"
phaseToText O1  = "O1"
phaseToText O2  = "O2"
phaseToText JV  = "JV"

-- | Fetch budget table data for a specific year and phase.
-- Returns Nothing on 404 (phase not available for that year),
-- Left on other errors, Right on success.
fetchBudgetTable :: MonadIO m
                 => Manager
                 -> Int   -- ^ Year
                 -> Phase -- ^ Budget phase
                 -> m (Either String (Maybe [BudgetRow]))
fetchBudgetTable manager year phase = liftIO $ do
  let url = rijksfinancienBaseUrl
              ++ "?year=" ++ show year
              ++ "&phase=" ++ show phase
  request <- parseRequest url
  response <- httpLbs request manager
  case statusCode (responseStatus response) of
    200 -> case eitherDecode (responseBody response) of
      Right rows -> pure (Right (Just rows))
      Left err   -> pure (Left $ err ++ "\n  Response body (first 500 chars): "
                                ++ take 500 (LBS.unpack (responseBody response)))
    404 -> pure (Right Nothing)
    code -> pure (Left $ "HTTP " ++ show code ++ " fetching budget table year="
                        ++ show year ++ " phase=" ++ show phase)
