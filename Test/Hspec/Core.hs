{-# OPTIONS_GHC -fno-warn-deprecations #-}
-- |
-- This module contains the core types, constructors, classes, instances, and
-- utility functions common to hspec.
module Test.Hspec.Core (
  SpecTree (..)
, Example (..)
, Result (..)
, descriptions

, describe
, it
, Spec
, Specs
, UnevaluatedSpec
, EvaluatedSpec

, quantify

-- * Deprecated types and functions
-- | The following types and functions are deprecated and will be removed with
-- the next release.
--
-- If you still need any of those, please open an issue and describe your use
-- case: <https://github.com/hspec/hspec/issues>
, AnyExample
, safeEvaluateExample

, success
, failure
, isFailure
, failedCount
) where

import           Test.Hspec.Internal hiding (safeEvaluateExample)
import qualified Test.Hspec.Internal as Internal

{-# DEPRECATED UnevaluatedSpec "use Spec instead" #-}
type UnevaluatedSpec = Spec

-- | DEPRECATED: This is no longer needed (it's just an alias for `id` now).
descriptions :: Specs -> Specs
descriptions = id
{-# DEPRECATED descriptions "this is no longer needed, and will be removed in a future release" #-}

type Specs = [Spec]

type EvaluatedSpec = SpecTree Result

{-# DEPRECATED success "This will be removed with the next major release.  If you still need this, raise your voice!" #-}
success :: [EvaluatedSpec] -> Bool
success = not . failure

{-# DEPRECATED failure "This will be removed with the next major release.  If you still need this, raise your voice!" #-}
failure :: [EvaluatedSpec] -> Bool
failure = any p
  where
    p (SpecGroup _ xs) = any p xs
    p (SpecExample _ x) = isFailure x

{-# DEPRECATED isFailure "This will be removed with the next major release.  If you still need this, raise your voice!" #-}
isFailure :: Result -> Bool
isFailure (Fail _) = True
isFailure _        = False

{-# DEPRECATED failedCount "This will be removed with the next major release.  If you still need this, raise your voice!" #-}
failedCount :: [EvaluatedSpec] -> Int
failedCount = sum . map count
  where
    count (SpecGroup _ xs) = sum (map count xs)
    count (SpecExample _ x) = if isFailure x then 1 else 0

{-# DEPRECATED AnyExample "This will be removed with the next major release.  If you still need this, raise your voice!" #-}
type AnyExample  = IO Result

{-# DEPRECATED safeEvaluateExample "This will be removed with the next major release.  If you still need this, raise your voice!" #-}
safeEvaluateExample :: AnyExample -> IO Result
safeEvaluateExample = Internal.safeEvaluateExample
