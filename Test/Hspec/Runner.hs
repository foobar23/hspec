{-# OPTIONS_GHC -fno-warn-deprecations #-}
-- | This module contains the runners that take a set of specs, evaluate their examples, and
-- report to a given handle.
--
module Test.Hspec.Runner (
  Specs, hspec, hspecX, hspecB, hHspec, hHspecWithFormat, describe, it, toExitCode
) where

import           Test.Hspec.Internal
import           Test.Hspec.Core (EvaluatedSpec, Specs)
import           Test.Hspec.Formatters
import           Test.Hspec.Formatters.Internal
import           System.IO
import           System.Exit

-- | Evaluate and print the result of checking the spec examples.
runFormatter :: Formatter -> Spec -> FormatM EvaluatedSpec
runFormatter formatter = go 0 "" . unSpec
  where
    go nesting _ (SpecGroup group xs) = do
      exampleGroupStarted formatter nesting group
      ys <- mapM (go (succ nesting) group) xs
      return (SpecGroup group ys)
    go nesting group (SpecExample requirement e) = do
      result <- liftIO $ safeEvaluateExample e
      case result of
        Success -> do
          increaseSuccessCount
          exampleSucceeded formatter nesting requirement
        Fail err -> do
          increaseFailCount
          exampleFailed  formatter nesting requirement err
          n <- getFailCount
          addFailMessage $ failureDetails group requirement err n
        Pending reason -> do
          increasePendingCount
          examplePending formatter nesting requirement reason
      return (SpecExample requirement result)

failureDetails :: String -> String -> String -> Int -> String
failureDetails group requirement err i =
  concat [ show i, ") ", group, " ",  requirement, " FAILED", if null err then "" else "\n" ++ err ]

-- | Use in place of `hspec` to also exit the program with an @ExitCode@
hspecX :: Specs -> IO a
hspecX ss = hspecB ss >>= exitWith . toExitCode

-- | Use in place of hspec to also give a @Bool@ success indication
hspecB :: Specs -> IO Bool
hspecB ss = success `fmap` hspec ss
  where
    success :: [EvaluatedSpec] -> Bool
    success = not . failure

    failure :: [EvaluatedSpec] -> Bool
    failure = any p
      where
        p (SpecGroup _ xs) = any p xs
        p (SpecExample _ x) = isFailure x

    isFailure :: Result -> Bool
    isFailure (Fail _) = True
    isFailure _        = False

-- | Create a document of the given specs and write it to stdout.
hspec :: Specs -> IO [EvaluatedSpec]
hspec = hHspec stdout

-- | Create a document of the given specs and write it to the given handle.
--
-- > writeReport filename specs = withFile filename WriteMode (\h -> hHspec h specs)
--
hHspec :: Handle -> Specs -> IO [EvaluatedSpec]
hHspec h specs = do
  useColor <- hIsTerminalDevice h
  hHspecWithFormat specdoc useColor h specs

-- | Create a document of the given specs and write it to the given handle.
-- THIS IS LIKELY TO CHANGE
hHspecWithFormat :: Formatter -> Bool -> Handle -> Specs -> IO [EvaluatedSpec]
hHspecWithFormat formatter useColor h ss = runFormatM useColor h $ do
  specList <- mapM (runFormatter formatter) ss
  failedFormatter formatter
  footerFormatter formatter
  return specList

toExitCode :: Bool -> ExitCode
toExitCode True  = ExitSuccess
toExitCode False = ExitFailure 1
