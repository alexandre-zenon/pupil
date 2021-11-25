# Pupil analysis toolbox

This toolbox contains the code necessary to perform the method described in the paper:
"Time-domain analysis for extracting fast-paced pupil responses", currently under revision in Scientific Report.

## Included functions
### Main functions
`loadWithPupil.m` can be used to load data from experiments using either the eyelink or the pupil headset from PupilLabs as eyetrackers, and COSYgraphics as a toolbox for stimulus presentation and synchronization of the behavioural paradigm with the eyetrackers.

`pupilARX.m` implements the main method of applying an ARX system identification model to the pupil size data.

`averageImpulseResponse.m` takes a series of ARX models and computes their averaged impulse response while taking into account their individual variability.

### Helper functions
`fastSmooth.m` smooths a vector by applying sliding-window averaging. Runs faster than the smooth builtin function.

`downsampleVector.m` downsamples a vector by an integer ratio by taking the mean of the successive time bins.
