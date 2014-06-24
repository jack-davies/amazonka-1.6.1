{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TemplateHaskell   #-}

-- Module      : Generator.AST
-- Copyright   : (c) 2013-2014 Brendan Hay <brendan.g.hay@gmail.com>
-- License     : This Source Code Form is subject to the terms of
--               the Mozilla Public License, v. 2.0.
--               A copy of the MPL can be found in the LICENSE file or
--               you can obtain it at http://mozilla.org/MPL/2.0/.
-- Maintainer  : Brendan Hay <brendan.g.hay@gmail.com>
-- Stability   : experimental
-- Portability : non-portable (GHC extensions)

module Generator.AST where

import           Control.Lens
import           Data.Default
import           Data.Function
import           Data.HashMap.Strict       (HashMap)
import           Data.List
import           Data.Maybe
import           Data.Monoid
import           Data.Ord
import           Data.String
import           Data.Text                 (Text)
import qualified Data.Text                 as Text
import           Data.Text.Util
import           GHC.Generics
import           Network.HTTP.Types.Method

newtype Abbrev = Abbrev { unAbbrev :: Text }
    deriving (Eq, Ord, Show, Generic)

instance IsString Abbrev where
    fromString = abbrev . Text.pack

instance Default Abbrev where
    def = Abbrev "AWS"

abbrev :: Text -> Abbrev
abbrev = Abbrev . mconcat . Text.words . strip "AWS" . strip "Amazon"

newtype NS = NS { unNS :: [Text] }
    deriving (Eq, Ord, Show, Generic)

instance Monoid NS where
    mempty      = NS []
    mappend a b = NS (on mappend unNS a b)

instance Default NS where
    def = mempty

instance IsString NS where
    fromString = NS . filter (/= "") . Text.split (== '.') . Text.pack

namespace :: Abbrev -> Version -> NS
namespace a v = NS
    [ "Network"
    , "AWS"
    , unAbbrev a
    , unVersion v
    ]

rootNS :: NS -> NS
rootNS (NS []) = NS []
rootNS (NS xs) = NS (init xs)

typeNS :: NS -> NS
typeNS = (<> "Types")

newtype Version = Version { unVersion :: Text }
    deriving (Eq, Ord, Show, Generic)

version :: Text -> Version
version = Version . mappend "V" . Text.replace "-" "_"

newtype Doc = Doc { unDoc :: Text }
    deriving (Eq, Show, Generic)

documentation :: Text -> Doc
documentation = Doc

instance Default Doc where
    def = Doc mempty

data Time
    = RFC822
    | ISO8601
      deriving (Eq, Show, Generic)

instance Default Time where
    def = ISO8601

data Checksum
    = MD5
    | SHA256
      deriving (Eq, Show, Generic)

instance Default Checksum where
    def = SHA256

data ServiceType
    = RestXml
    | RestJson
    | RestS3
    | Json
    | Query
      deriving (Eq, Show, Generic)

instance Default ServiceType where
    def = Query

data Signature
    = V2
    | V3
    | V4
      deriving (Eq, Show, Generic)

newtype JSONV = JSONV { unJSONV :: Text }
    deriving (Eq, Show)

instance Default JSONV where
    def = JSONV "1.0"

newtype Cabal = Cabal [Service]
    deriving (Show)

data Service = Service
    { _svcName             :: Abbrev
    , _svcFullName         :: Text
    , _svcNamespace        :: NS
    , _svcVersionNamespace :: NS
    , _svcTypesNamespace   :: NS
    , _svcVersion          :: Version
    , _svcType             :: ServiceType
    , _svcWrapped          :: Bool
    , _svcSignature        :: Signature
    , _svcDocumentation    :: Doc
    , _svcEndpointPrefix   :: Text
    , _svcGlobalEndpoint   :: Maybe Text
    , _svcXmlNamespace     :: Maybe Text
    , _svcTimestamp        :: Time
    , _svcChecksum         :: Checksum
    , _svcJsonVersion      :: JSONV
    , _svcTargetPrefix     :: Maybe Text
    , _svcOperations       :: [Operation]
    } deriving (Eq, Show, Generic)

instance Ord Service where
    compare a b = f _svcNamespace <> f _svcVersion
      where
        f :: Ord a => (Service -> a) -> Ordering
        f g = compare (g a) (g b)

current :: [Service] -> [Service]
current = mapMaybe latest . groupBy identical
  where
    identical x y = EQ == comparing _svcName x y

    latest [] = Nothing
    latest xs = Just . head $ sortBy (comparing _svcVersion) xs

data Operation = Operation
    { _opName          :: Text
    , _opService       :: Abbrev
    , _opAlias         :: Maybe Text
    , _opNamespace     :: NS
    , _opImports       :: [NS]
    , _opDocumentation :: Doc
    , _opUrl           :: Maybe Text
    , _opRequest       :: Request
    , _opResponse      :: Response
    , _opErrors        :: [Shape]
    , _opPagination    :: Maybe Pagination
    } deriving (Eq, Show, Generic)

data Request = Request
    { _rqName     :: Text
    , _rqPayload  :: Maybe Field
    , _rqFields   :: [Field]
    , _rqRequired :: [Field]
    , _rqHeaders  :: [Field]
    , _rqShape    :: Shape
    , _rqHttp     :: HTTP
    } deriving (Eq, Show, Generic)

data Response = Response
    { _rsName   :: Text
    , _rsFields :: [Field]
    , _rsShape  :: Shape
    } deriving (Eq, Show, Generic)

data Location
    = LUri
    | LQuery
    | LHeader
    | LBody
      deriving (Eq, Ord, Show, Generic)

instance Default Location where
    def = LBody

data Common = Common
    { _cmnName          :: Maybe Text
    , _cmnXmlName       :: Maybe Text
    , _cmnLocation      :: Location
    , _cmnLocationName  :: Maybe Text
    , _cmnRequired      :: Bool
    , _cmnDocumentation :: Maybe Doc
    , _cmnStreaming     :: Bool
    } deriving (Eq, Show, Generic)

instance Ord Common where
    compare a b =
        if _cmnLocation a == LBody
            then GT
            else comparing _cmnLocation a b <> comparing _cmnName a b

instance Default Common where
    def = Common Nothing Nothing def Nothing False Nothing False

data Shape
    = SStruct
      { shpFields    :: [Shape]
      , _shpCommon   :: Common
      }

    | SList
      { shpItem      :: Shape
      , shpFlattened :: Bool
      , shpMinLength :: Int
      , shpMaxLength :: Int
      , _shpCommon   :: Common
      }

    | SMap
      { shpKey       :: Shape
      , shpValue     :: Shape
      , _shpCommon   :: Common
      }

    | SEnum
      { shpValues    :: HashMap Text Text
      , _shpCommon   :: Common
      }

    | SPrim
      { shpType      :: Prim
      , shpMinLength :: Int
      , shpMaxLength :: Int
      , shpPattern   :: Maybe Text
      , _shpCommon   :: Common
      }

      deriving (Eq, Show, Generic)

instance Default Shape where
    def = SPrim PText 0 0 Nothing def

fields :: Shape -> [Field]
fields s = case s of
    SStruct{..} -> map f shpFields
    _           -> []
  where
    f x = Field (typeof x) (prefixed s) (_shpCommon x)

prefixed :: Shape -> Text
prefixed s = let n = fromName "prefixed" s in prefix n <> n

fromName :: String -> Shape -> Text
fromName loc s = case _cmnName (_shpCommon s) of
    Nothing -> error $ loc ++ " - Shape has no name: " ++ (show s)
    Just x  -> x

required :: Shape -> Bool
required s = let Common{..} = _shpCommon s in _cmnRequired || _cmnLocation == LBody

data Prim
    = PText
    | PInteger
    | PDouble
    | PBool
    | PByteString
    | PUTCTime
      deriving (Eq, Show, Generic)

data Ann = Ann
   { anRequired :: !Bool
   , anType     :: Text
   } deriving (Eq, Show, Generic)

typeof :: Shape -> Ann
typeof s = Ann (required s) $
    case s of
        SStruct {..} -> name s
        SList   {..} -> "[" <> ann shpItem <> "]"
        SMap    {..} -> "HashMap " <> ann shpKey <> " " <> ann shpValue
        SEnum   {..} -> name s
        SPrim   {..} -> Text.pack . drop 1 $ show shpType
  where
    name = fromName "typeof"
    ann  = anType . typeof

data Field = Field
    { fldType   :: Ann
    , fldBrief  :: Text
    , fldCommon :: Common
    } deriving (Eq, Show)

instance Ord Field where
    compare = compare `on` fldCommon

data HTTP = HTTP
    { hMethod :: !StdMethod
    , hPath   :: [PathPart]
    , hQuery  :: [QueryPart]
    } deriving (Eq, Show, Generic)

instance Default HTTP where
    def = HTTP GET [] []

data PathPart
    = PConst Text
    | PVar   Text
      deriving (Eq, Show)

data QueryPart = QueryPart
    { qpKey :: Text
    , qpVal :: Maybe Text
    } deriving (Eq, Show, Generic)

data Pagination = Pagination
    { pgMoreKey     :: Maybe Text
    , pgLimitKey    :: Maybe Text
    , pgInputToken  :: Text
    , pgOutputToken :: Text
    , pgResultKeys  :: Text
    } deriving (Eq, Show, Generic)

makeLenses ''Service
makeLenses ''Operation
makeLenses ''Request
makeLenses ''Response
makeLenses ''Common
makeLenses ''Shape
