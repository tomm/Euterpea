{-# LINE 8 "MUI.lhs" #-}
--  This code was automatically generated by lhs2tex --code, from the file 
--  HSoM/MUI.lhs.  (See HSoM/MakeCode.bat.)
{-# LINE 19 "MUI.lhs" #-}
{-#  LANGUAGE Arrows, CPP  #-}

module Euterpea.Examples.MUI where
import Euterpea
{-# LINE 25 "MUI.lhs" #-}
import Data.Maybe (mapMaybe)
import Euterpea.Experimental
#if MIN_VERSION_UISF(0,4,0)
import FRP.UISF.Graphics (withColor', rgbE, rectangleFilled)
#else
import FRP.UISF.SOE (withColor', rgb, polygon)
#endif
import FRP.UISF.Widget (mkWidget)
{-# LINE 585 "MUI.lhs" #-}
ui0  ::  UISF () ()
ui0  =   proc _ -> do
    ap <- hiSlider 1 (0,100) 0 -< ()
    display -< pitch ap
{-# LINE 605 "MUI.lhs" #-}
mui0 = runMUI' ui0
{-# LINE 686 "MUI.lhs" #-}
ui1 ::  UISF () ()
ui1 =   setSize (150,150) $ 
  proc _ -> do
    ap <- title "Absolute Pitch" (hiSlider 1 (0,100) 0) -< ()
    title "Pitch" display -< pitch ap

mui1  =  runMUI' ui1
{-# LINE 708 "MUI.lhs" #-}
ui2   ::  UISF () ()
ui2   =   leftRight $
  proc _ -> do
    ap <- title "Absolute Pitch" (hiSlider 1 (0,100) 0) -< ()
    title "Pitch" display -< pitch ap

mui2  =  runMUI' ui2
{-# LINE 837 "MUI.lhs" #-}
ui3  ::  UISF () ()
ui3  =   proc _ -> do
    devid <- selectOutput -< ()
    ap <- title "Absolute Pitch" (hiSlider 1 (0,100) 0) -< ()
    title "Pitch" display -< pitch ap
    uap <- unique -< ap
    midiOut -< (devid, fmap (\k-> [ANote 0 k 100 0.1]) uap)

mui3  = runMUI' ui3
{-# LINE 871 "MUI.lhs" #-}
ui4   :: UISF () ()
ui4   = proc _ -> do
    mi  <- selectInput   -< ()
    mo  <- selectOutput  -< ()
    m   <- midiIn        -< mi
    midiOut -< (mo, m)

mui4  = runMUI' ui4
{-# LINE 885 "MUI.lhs" #-}
getDeviceIDs = topDown $
  proc () -> do
    mi    <- selectInput   -< ()
    mo    <- selectOutput  -< ()
    outA  -< (mi,mo)
{-# LINE 935 "MUI.lhs" #-}
mui'4 = runMUI  (defaultMUIParams 
                    {  uiTitle  = "MIDI Input / Output UI", 
                       uiSize   = (200,200)})
                ui4
{-# LINE 1111 "MUI.lhs" #-}
ui5 ::  UISF () ()
ui5 =   proc _ -> do
    devid   <- selectOutput -< ()
    ap      <- title "Absolute Pitch" (hiSlider 1 (0,100) 0) -< ()
    title "Pitch" display -< pitch ap
    f       <- title "Tempo" (hSlider (1,10) 1) -< ()
    tick    <- timer -< 1/f
    midiOut -< (devid, fmap (const [ANote 0 ap 100 0.1]) tick)

--  Pitch Player with Timer
mui5  = runMUI' ui5
{-# LINE 1233 "MUI.lhs" #-}
chordIntervals :: [ (String, [Int]) ]
chordIntervals = [  ("Maj",     [4,3,5]),    ("Maj7",    [4,3,4,1]),
                    ("Maj9",    [4,3,4,3]),  ("Maj6",    [4,3,2,3]),
                    ("min",     [3,4,5]),    ("min7",    [3,4,3,2]),
                    ("min9",    [3,4,3,4]),  ("min7b5",  [3,3,4,2]),
                    ("mMaj7",   [3,4,4,1]),  ("dim",     [3,3,3]),
                    ("dim7",    [3,3,3,3]),  ("Dom7",    [4,3,3,2]),
                    ("Dom9",    [4,3,3,4]),  ("Dom7b9",  [4,3,3,3]) ]
{-# LINE 1250 "MUI.lhs" #-}
toChord :: Int -> MidiMessage -> [MidiMessage]
toChord i m = 
  case m of 
    Std (NoteOn c k v)   -> f NoteOn c k v
    Std (NoteOff c k v)  -> f NoteOff c k v
    _ -> []
  where f g c k v = map  (\k' -> Std (g c k' v)) 
                         (scanl (+) k (snd (chordIntervals !! i)))
{-# LINE 1277 "MUI.lhs" #-}
buildChord :: UISF () ()
buildChord = leftRight $ 
  proc _ -> do
    (mi, mo)  <- getDeviceIDs -< ()
    m         <- midiIn -< mi
    i         <- topDown $ title "Chord Type" $ 
                   radio (fst (unzip chordIntervals)) 0 -< ()
    midiOut -< (mo, fmap (concatMap $ toChord i) m)

chordBuilder = runMUI  (defaultMUIParams 
                           {  uiTitle  = "Chord Builder", 
                              uiSize   = (600,400)})
                       buildChord
{-# LINE 1338 "MUI.lhs" #-}
grow :: Double -> Double -> Double
grow r x = r * x * (1-x)
{-# LINE 1370 "MUI.lhs" #-}
popToNote :: Double -> [MidiMessage]
popToNote x =  [ANote 0 n 64 0.05] 
               where n = truncate (x * 127)
{-# LINE 1380 "MUI.lhs" #-}
bifurcateUI :: UISF () ()
bifurcateUI = proc _ -> do
    mo    <- selectOutput -< ()
    f     <- title "Frequency" $ withDisplay (hSlider (1, 10) 1) -< ()
    tick  <- timer -< 1/f
    r     <- title "Growth rate" $ withDisplay (hSlider (2.4, 4.0) 2.4) -< ()
    pop   <- accum 0.1 -< fmap (const (grow r)) tick
    _     <- title "Population" $ display -< pop
    midiOut -< (mo, fmap (const (popToNote pop)) tick)

bifurcate = runMUI  (defaultMUIParams 
                        {  uiTitle  = "Bifurcate!", 
                           uiSize   = (300,500)})
                    bifurcateUI
{-# LINE 1434 "MUI.lhs" #-}
echoUI :: UISF () ()
echoUI = proc _ -> do
    (mi, mo) <- getDeviceIDs -< ()
    m <- midiIn -< mi
    r <- title "Decay rate" $ withDisplay (hSlider (0, 0.9) 0.5) -< ()
    f <- title "Echoing frequency" $ withDisplay (hSlider (1, 10) 10) -< ()

    rec s <- vdelay -< (1/f, fmap (mapMaybe (decay 0.1 r)) m')
        let m' = m ~++ s

    midiOut -< (mo, m')

echo = runMUI' echoUI
{-# LINE 1451 "MUI.lhs" #-}
decay :: Time -> Double -> MidiMessage -> Maybe MidiMessage
decay dur r m = 
  let f c k v d =   if v > 0 
                    then  let v' = truncate (fromIntegral v * r)
                          in Just (ANote c k v' d)
                    else  Nothing
  in case m of
       ANote c k v d       -> f c k v d
       Std (NoteOn c k v)  -> f c k v dur
       _                   -> Nothing
{-# LINE 1712 "MUI.lhs" #-}
gAndPUI :: UISF () ()
gAndPUI = proc _ -> do
    (mi, mo) <- getDeviceIDs -< ()
    m <- midiIn -< mi
    settings <- addNotation -< defaultInstrumentData
    outG  <- guitar sixString 1   -< (settings, Nothing)
    outP  <- piano defaultMap0 0  -< (settings, m)
    midiOut -< (mo, outG ~++ outP)

gAndP = runMUI  (defaultMUIParams {  uiSize=(1050,700), 
                                     uiTitle="Guitar and Piano"})
                gAndPUI
{-# LINE 1783 "MUI.lhs" #-}
colorSwatchUI :: UISF () ()
colorSwatchUI = setSize (300, 220) $ pad (4,0,4,0) $ leftRight $ 
    proc _ -> do
        r <- newColorSlider "R" -< ()
        g <- newColorSlider "G" -< ()
        b <- newColorSlider "B" -< ()
        e <- unique -< (r,g,b)
#if MIN_VERSION_UISF(0,4,0)
        let rect = withColor' (rgbE r g b) (rectangleFilled ((0,0),d))
#else
        let rect = withColor' (rgb r g b) (box ((0,0),d))
#endif
        pad (4,8,0,0) $ canvas d -< fmap (const rect) e
  where
    d = (170,170)
    newColorSlider l = title l $ withDisplay $ viSlider 16 (0,255) 0
#if MIN_VERSION_UISF(0,4,0)
#else
    box ((x,y), (w, h)) = 
        polygon [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]
#endif

colorSwatch = runMUI' colorSwatchUI
{-# LINE 1898 "MUI.lhs" #-}
ui6 = topDown $ proc _ -> do
  b1 <- button "Button 1" -< ()
  (b2, b3) <- leftRight (proc _ -> do
    b2 <- button "Button 2" -< ()
    b3 <- button "Button 3" -< ()
    returnA -< (b2, b3)) -< ()
  b4 <- button "Button 4" -< ()
  display -< b1 || b2 || b3 || b4
{-# LINE 1916 "MUI.lhs" #-}
ui'6 = topDown $ proc _ -> do
  b1 <- button "Button 1" -< ()
  (b2, b3) <- leftRight (proc b1 -> do
    b2 <- button "Button 2" -< ()
    display -< b1
    b3 <- button "Button 3" -< ()
    returnA -< (b2, b3)) -< b1
  b4 <- button "Button 4" -< ()
  display -< b1 || b2 || b3 || b4
{-# LINE 1947 "MUI.lhs" #-}
ui''6 = proc () -> do
  b1 <- button "Button 1" -< ()
  (b2, b3) <- (| leftRight (do
    b2 <- button "Button 2" -< ()
    display -< b1
    b3 <- button "Button 3" -< ()
    returnA -< (b2, b3)) |)
  b4 <- button "Button 4" -< ()
  display -< b1 || b2 || b3 || b4
