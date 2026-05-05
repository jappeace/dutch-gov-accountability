{-# LANGUAGE OverloadedStrings #-}

module DutchGov.Rijksfinancien.BudgetTable
  ( BudgetRow(..)
  ) where

import Data.Aeson
import Data.Text (Text)

-- | A single budget table row from the Rijksfinancien API.
-- Represents one line in the budget at a specific granularity level.
data BudgetRow = BudgetRow
  { brMinister         :: Maybe Text
  , brChapterName      :: Maybe Text
  , brChapterNumber    :: Text
  , brArticleName      :: Maybe Text
  , brArticleNumber    :: Text
  , brSubArticleName   :: Maybe Text
  , brSubArticleNumber :: Text
  , brInstrumentName   :: Maybe Text
  , brInstrumentNumber :: Text
  , brRegulationName   :: Maybe Text
  , brRegulationNumber :: Text
  , brVuo             :: Text  -- ^ U=uitgaven, O=ontvangsten, V=verplichtingen
  , brAmount          :: Int   -- ^ Amount in euros (or thousands)
  } deriving (Show, Eq)

instance FromJSON BudgetRow where
  parseJSON = withObject "BudgetRow" $ \obj -> do
    minister <- obj .:? "begrotingsnaam"
    chapName <- obj .:? "hoofdstuk_naam"
    chapNum <- obj .:? "hoofdstuk_nummer" .!= ""
    artName <- obj .:? "artikel_naam"
    artNum <- obj .:? "artikel_nummer" .!= ""
    subArtName <- obj .:? "subartikel_naam"
    subArtNum <- obj .:? "subartikel_nummer" .!= ""
    instrName <- obj .:? "instrument_naam"
    instrNum <- obj .:? "instrument_nummer" .!= ""
    regName <- obj .:? "regeling_naam"
    regNum <- obj .:? "regeling_nummer" .!= ""
    vuo <- obj .:? "vuo" .!= ""
    amount <- obj .:? "bedrag" .!= 0
    pure BudgetRow
      { brMinister = minister
      , brChapterName = chapName
      , brChapterNumber = chapNum
      , brArticleName = artName
      , brArticleNumber = artNum
      , brSubArticleName = subArtName
      , brSubArticleNumber = subArtNum
      , brInstrumentName = instrName
      , brInstrumentNumber = instrNum
      , brRegulationName = regName
      , brRegulationNumber = regNum
      , brVuo = vuo
      , brAmount = amount
      }
