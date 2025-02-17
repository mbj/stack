{-# LANGUAGE NoImplicitPrelude  #-}
{-# LANGUAGE OverloadedStrings  #-}
{-# LANGUAGE RecordWildCards    #-}

-- | Casa configuration types.

module Stack.Types.Casa
  ( CasaOptsMonoid (..)
  ) where

import           Casa.Client ( CasaRepoPrefix )
import           Generics.Deriving.Monoid ( mappenddefault, memptydefault )
import           Pantry.Internal.AesonExtended
                   ( FromJSON (..), WithJSONWarnings, (..:?), withObjectWarnings
                   )
import           Stack.Prelude

-- | An uninterpreted representation of Casa configuration options.
-- Configurations may be "cascaded" using mappend (left-biased).
data CasaOptsMonoid = CasaOptsMonoid
  { casaMonoidEnable :: !FirstTrue
  , casaMonoidRepoPrefix :: !(First CasaRepoPrefix)
  , casaMonoidMaxKeysPerRequest :: !(First Int)
  }
  deriving (Generic, Show)

-- | Decode uninterpreted Casa configuration options from JSON/YAML.
instance FromJSON (WithJSONWarnings CasaOptsMonoid) where
  parseJSON = withObjectWarnings "CasaOptsMonoid"
    ( \o -> do
        casaMonoidEnable <- FirstTrue <$> o ..:? casaEnableName
        casaMonoidRepoPrefix <- First <$> o ..:? casaRepoPrefixName
        casaMonoidMaxKeysPerRequest <-
          First <$> o ..:? casaMaxKeysPerRequestName
        pure CasaOptsMonoid {..}
    )

-- | Left-biased combine Casa configuration options
instance Semigroup CasaOptsMonoid where
  (<>) = mappenddefault

-- | Left-biased combine Casa configurations options
instance Monoid CasaOptsMonoid where
  mempty = memptydefault
  mappend = (<>)

-- | Casa configuration enable setting name.
casaEnableName :: Text
casaEnableName = "enable"

-- | Casa configuration repository prefix setting name.
casaRepoPrefixName :: Text
casaRepoPrefixName = "repo-prefix"

-- | Casa configuration maximum keys per request setting name.
casaMaxKeysPerRequestName :: Text
casaMaxKeysPerRequestName = "max-keys-per-request"
