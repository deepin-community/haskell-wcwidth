#!/usr/bin/env runhaskell
{-# LANGUAGE OverloadedStrings
  #-}


module CompileRanges where

import Prelude hiding (concat, lines, unlines, takeWhile)
import Data.List (foldl')
import Data.Char hiding (isDigit)
import Data.Maybe
import Data.Either
import Control.Applicative hiding (empty)
import System.IO (stdin, stdout, stderr)
import Data.ByteString.Char8 hiding (takeWhile, count, foldl', reverse)

import Data.Attoparsec (parseOnly)
import Data.Attoparsec.Char8




main                         =  compile_ranges stdin stdout


compile_ranges i o           =  do
  ranges                    <-  rights . parse' . lines <$> hGetContents i
  --sequence_ . (hPut o . display <$>) $ collate ranges
  hPut o preamble
  (sequence_ . (hPut o . compile <$>) . collate) ranges
  hPut o postamble
 where
  parse'                     =  (parseOnly range <$>)
  display ((a,z),w)          =  a `append` pack ".." `append` z `snoc` '\n'
  compile ((a,z),w)          =  guard `append` eq `append` w `snoc` '\n'
   where
    guard                    =  pack "  | i <= " `append` z
    eq                       =  pack "              =  "
  preamble                   =  (unlines . fmap pack) [warning, mod, sig, f]
   where
    warning                  =  "\n\n--  This file was autogenerated.\n"
    mod                      =  "\nmodule Data.Char.Cols.Generated where\n\n"
    sig                      =  "cols                        ::  Char -> Int\n"
    f                        =  "cols c\n"
  postamble                  =  otherwise_clause `append` where_clause
   where
    otherwise_clause         =  pack "  | otherwise                =  -1\n"
    where_clause             =  pack " where\n" `append` pack i `snoc` '\n'
     where
      i                      =  "  i                          =  fromEnum c\n"




range                        =  do
  start                     <-  short_hex
  string ".."
  end                       <-  short_hex
  some (char ' ')
  columns                   <-  little_int
  return ((start, end), columns)

short_hex                   ::  Parser ByteString
short_hex                    =  do
  ox                        <-  string "0x"
  count 4 (char '0')
  append ox . pack <$> count 4 (satisfy isHexDigit)

little_int                  ::  Parser ByteString
little_int                   =  do
  sign                      <-  maybe empty id <$> optional minus
  digits                    <-  takeWhile isDigit
  return (append sign digits)
 where
  minus                      =  string "-"




collate                      =  reverse . foldl' collate' []
 where
  collate' [] range          =  [range]
  collate' (((a,z),w):t) ((a',z'),w')
    | w == w'                =  ((a,z'),w) : t
    | otherwise              =  ((a',z'),w') : ((a,z),w) : t

