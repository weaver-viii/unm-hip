{-# LANGUAGE ViewPatterns, FlexibleInstances, TypeFamilies, FlexibleContexts #-}
{-# OPTIONS -O2 #-}
module Data.Image.Complex(Complexable(..),
                          realPart,
                          imagPart,
                          magnitude,
                          angle,
                          polar,
                          complexImageToRectangular,
                          makeFilter,
                          fft, ifft) where

import Data.Image.Imageable
import qualified Data.Complex as C
import qualified Data.Image.FFT as FFT
import qualified Data.Vector as V

realPart :: (Imageable img,
             Imageable img',
             RealFloat (Pixel img'),
             Pixel img ~ C.Complex (Pixel img')) => img -> img'
realPart = imageMap C.realPart

imagPart :: (Imageable img,
             Imageable img',
             RealFloat (Pixel img'),
             Pixel img ~ C.Complex (Pixel img')) => img -> img'
imagPart = imageMap C.imagPart

magnitude :: (Imageable img,
             Imageable img',
             RealFloat (Pixel img'),
             Pixel img ~ C.Complex (Pixel img')) => img -> img'
magnitude = imageMap C.magnitude

angle :: (Imageable img,
          Imageable img',
          RealFloat (Pixel img'),
          Pixel img ~ C.Complex (Pixel img')) => img -> img'
angle = imageMap C.phase

polar :: (Imageable img,
          Imageable img',
          RealFloat (Pixel img'),
          Pixel img ~ C.Complex (Pixel img')) => img -> [img']
polar img@(dimensions -> (rows, cols)) = [mkImg mag, mkImg phs] where
  mkImg = makeImage rows cols
  ref' r c = C.polar $ (ref img r c)
  mag r c = fst (ref' r c)
  phs r c = snd (ref' r c)

complexImageToRectangular :: (Imageable img,
                              Imageable img',
                              RealFloat (Pixel img'),
                              Pixel img ~ C.Complex (Pixel img')) => img -> [img']
complexImageToRectangular img = [realPart img, imagPart img]


makeFilter :: (Imageable img) => Int -> Int -> (PixelOp (Pixel img)) -> img
makeFilter rows cols func = makeImage rows cols func' where
  mR = rows `div` 2
  mC = cols `div` 2
  func' r c = func ((r+mR) `mod` rows) ((c+mC) `mod` cols)

class Complexable c where
  toComplex :: c -> C.Complex Double

instance Complexable (C.Complex Double) where
  toComplex = id

instance Complexable Double where
  toComplex = (C.:+ 0)

fft :: (Imageable img,
        Imageable img',
        Complexable (Pixel img),
        Pixel img' ~ C.Complex Double) => img -> img'
fft img@(dimensions -> (rows, cols)) = makeImage rows cols fftimg where
  fftimg r c = fft' V.! (r*cols + c)
  vector = V.map toComplex . V.fromList . pixelList $ img
  fft' = FFT.fft rows cols vector

ifft :: (Imageable img,
        Pixel img ~ C.Complex Double) => img -> img
ifft img@(dimensions -> (rows, cols)) = makeImage rows cols fftimg where
  fftimg r c = fft' V.! (r*cols + c)
  vector = V.fromList . pixelList $ img
  fft' = FFT.ifft rows cols vector