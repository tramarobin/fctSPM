# fctSPM [![status](https://joss.theoj.org/papers/ea923a728497b806dbb59a0c4c0b76cc/status.svg)](https://joss.theoj.org/papers/ea923a728497b806dbb59a0c4c0b76cc) [![View fctSPM on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/77945-fctspm)
Using spm1d package (v.0.4.3), computes ANOVA and post-hoc tests from anova1 to anova3rm, with a non-parametric approach (permutation tests).
The type of anova (if required) and post-hoc are choosen regarding the independant or repeated measure effects given in parameters.
The function automatically adapts to 1D and 2D data.

The general usage is:
```matlab
fctSPM(data, independantEffects, repeatedMeasuresEffects, varargin)
```


## Table of contents ##
- [Warnings](#Warnings)
- [Why fctSPM](#Why-fctSPM)
- [Citing fctSPM](#Citing-fctSPM)
- [MATLAB Release Compatibility](#MATLAB-Release-Compatibility)
- [Outputs](#Outputs)
- [Examples](#Examples)
- [Using fctSPM](#Using-fctSPM)
- [Obligatory INPUTS](#Obligatory-INPUTS)
- [Optional INPUTS](#Optional-INPUTS)

## Warnings ##
- Unbalanced two- and three-way repeated-measures ANOVA results have not been verified.
Example: more subjects in Group 1 than in Group 2.
Please interpret results for these designs with caution, and recognize that they might not be valid.
- Post-hoc tests with Bonferonni correction are only approximate.
- Somes warnings are displayed if the number of iterations is automatically modified or not sufficiant to perform the analysis with the defined alpha risk.
- Effect sizes and confidence intervals are not validated and are just given as supplementary information.
- For more information, please visit : https://spm1d.org/Documentation.html

### Caution ###
- Avoid the same typo (e.g., POST, POST2) for the effect names, it affects the recognition for the multiples comparisons 
- Avoid underscore (_) or minus (-) sign. Spaces are OK
- Avoid '/' and use '\\' when defining a saving directory (`savedir` option)
- Once you are ok with the created figure, increase the number of iterations (`multiIT` or `IT` options) to achieve numerical stability. 1000 iterations are a good start but if your hardware allows it, the more is the better

## Why fctSPM ##
fctSPM allows MATLAB users to create figures of 1D and 2D SPM analysis for ANOVA and post-hoc designs.    
The statistical analysis is also saved in .mat files.   
This function synthetises the main and interaction effects to display only the significant post-hoc regarding the results of the ANOVA.   
For post-hoc for interaction effects, the main effect is also displayed if located elsewhere than the interaction effect.

## Citing fctSPM ##
- This function : under review in JOSS   
- for spm1d : Pataky TC (2010). Generalized n-dimensional biomechanical field analysis using statistical parametric mapping. Journal of Biomechanics 43, 1976-1982.   
- for permutation tests : Nichols TE, Holmes AP (2002). Nonparametric permutation tests for functional neuroimaging: a primer with examples. Human Brain Mapping 15(1), 1–25.   
- spm1d package for matlab can be downloaded at : https://github.com/0todd0000/spm1dmatlab   


## MATLAB Release Compatibility ##
Compatible from Matlab R2017b


## Outputs ##
This fonction creates two folders:
* `ANOVA` named after the type of ANOVA performed on the data (ANOVA1rm if the analysis was a one-way ANOVA with repeated measures, no ANOVA folder is created if the analysis is a t-test).  
* `Post hoc` for the post-hoc analysis.  

Each folder is composed of two different types of files : 
* `.m` files in which all data and statistical analysis can be found
* `.TIF` and `.fig` files representing the statistical analysis on different graphics.  

### ANOVA folder ###
`anova.m` file is composed of different fields (same for 1D and 2D) :  
* `type is the type of ANOVA performed
* `effectNames` is a structure (one cell for each effect) that represent the names of the effects tested (mains and interactions) 
* `alpha` is the alpha risk used for the anova
* `alphaOriginal` is the alpha risk choosen for the anova (default is 0.05 (5%)). Warning message is displayed if this value is modified.
* `nIterations` is the number of iterations performed for the anova.
* `maxIterations` is the number of maximal iterations possible for the anova.
* `Fcontinuum` is a structure that represent the F-value for each node
* `Fthreshold` is a structure that represent the statistical threshold for the F-values (statistical inference)
* `Fsignificant` is a structure that contains the logical for the significance (Fcontinuum > Fthreshold) of each effect of the ANOVA (1 if significant, 0 if not).  
* `clusterLocation` is a structure (one for each significant cluster) that contains the location (start and end as indexes) of each significant cluster.
* `clusterP` is a structure (one for each significant cluster) that contains the p-value of each significant cluster.
`clusterLocation` and `clusterP` are interpretable only for 1D data. Use figures to interpret 2D data significance.

Each effect is also display on a specific figure in `.TIF` format named after `effectNames`, a floder named FIG is also created and contains the figures in `.fig` format.   
For 1D:  The curve represents the `Fcontinuum`, the horizontal line is the `Fthreshold`, the highlighted curve(s) in blue represent(s) the significant cluster(s), and the vertical lines are the start and end indexes.
For 2D: The map represents the `Fcontinuum`, with a colorbar thresholded at `Fthreshold`, the white clusters represent the significant clusters.


### Post hoc folder ###
This folder contains additional folders (0 (for anova1), 3 (for anova2) or 7 (for anova3)) that contain figures and metrics representing the different post-hoc tests.
`posthoc.m` file is composed of different fields :
* `data.names` is a structure that contains the name of the conditions used in the analysis (\cap is the union of different conditions for interactions).
* `data.continuum` is a structure that contains the data used in the analysis.

For the following outputs, the number of cells of the structure correspond to the number of t-tests performed, one t-test corresponds to one cell.
* `differences.names` is the name of the conditions (the first minus the second) used in the differences and t-tests.
* `differences.continuum` is the data used to plot differences.
* `differences.continuumRelative` is the data used to plot relative differences
* `differences.ES` is the effect size that correspond to the differences (Hedge's g)
* `differences.ESsd` is the standard deviation of the effect size.
* `tTests.type` is the type of t-test performed (independant or paired)
* `tTests.names` is the name of the conditions (the first minus the second) used in the differences and t-tests.
* `tTests.nWarning` represents the number of warnings displyed during the analysis : 0 is OK, 1 means the number of iterations was reduced but the original alpha risk was conserved, 2 means that the number of iterations was reduced and the original alpha was reduced. In this case, more subjects are required to performed the analysis. 
* `tTests.alphaOriginal` is the alpha risk choosen for the post hoc tests (default is 0.05 (5%)/ number of comparisons). Warning message is displayed if this value is modified.
* `tTests.alpha` is the alpha risk used for the post hoc tests
* `tTests.alphaOriginal` is the alpha risk choosen for the anova (default is 0.05 (5%)). Warning message is displayed if this value is modified.
* `tTests.nIterations` is the number of iterations performed for the t-test.
* `tTests.maxIterations` is the number of maximal iterations possible for the t-test.
* `tTests.Tcontinuum` is a structure that represent the T-value for each node
* `tTests.Tthreshold` is a structure that represent the statistical threshold for the T-values (statistical inference)
* `tTests.Tsignificant` is a structure that contains the logical for the significance (Tcontinuum > Tthreshold) (1 if significant, 0 if not). This value is corrected with the result of the corresponding ANOVA and previous t-tests.
* `tTests.clusterLocation` is a structure (one for each significant cluster) that contains the location (start and end as indexes) of each significant cluster.
* `tTests.clusterP` is a structure (one for each significant cluster) that contains the p-value of each significant cluster.
`clusterLocation` and `clusterP` are interpretable only for 1D data. Use figures to interpret 2D data significance.

Interaction folders (AxB or AxBxC) contain 2 or 3 folders in which one effect is investigated.

#### Figures ####
For 1D :
A total of 5 figures with the name of the effect represent the means and standard deviations between subject for each condition (grouped in fuction of the effect investigated).  
Under this plot, a second graph display the result of the ANOVA (or ANOVAs for interaction) and the significant post-hoc tests for pairewise comparisons.  
The differences between the 5 figures are the representation of the ANOVA and the disposition of the statistical analysis (subplot or same plot, see optional inputs)

Subfolders : Contains the pairewise comparison results 
* DIFF: Differences plots. Filenames with '%' at the end are the relative differences
* ES: Effect size plots. Bold blue lines are located at the significant differences (corrected with the ANOVA).
* SPM: Tcontinuum and statistical inferences plots. Bold blue lines are located at the significant differences (corrected with the ANOVA).
* FIG folder contains the above mentionned folder with the figures in `.fig` format.


For 2D :
Means maps for each condition are represented in one figure each. 
The global effect of the post hoc precedure is display on a figure with the name of the effect. Mean maps are represented on the diagonal, pairewise differences on the top-right panel, and pairewise spm inferences on the bottom-left panel. 

Subfolders : Contains the pairewise comparison results (In one folder for ANOVA1, in 2 or 3 folders for ANOVA2 and ANOVA3)
* SD : standard deviation of the maps for each condition.
* DIFF: Differences plots. Filenames with '%' at the end are the relative differences. White clusters represent the significant effect (corrected with ANOVA)
* ES: Effect size plots. Whites clusters represent the significant effect (corrected with ANOVA)
* SPM: Tcontinuum and statistical inferences plots. Whites clusters represent the significant effect (no correction with the ANOVA)
* FIG folder contains the above mentionned folder with the figures in `.fig` format.


## Examples ##
### In one dimension ### 
Here are the outcomes for a 2way ANOVA with 1 repeated measure in 1 dimension  
.\fctSPM\Examples\D1_ANOVA2_1rm.m  
The curves represent the ratio between Quadriceps and Hamstrings during isokinetic tests for two sides (Left and Right) and for two sexes (M and F).  

ANOVA results : There is a "Side" effect, with a F-value above the significant threshold of 7.14 between 30 and 85°.
![alt text](https://github.com/tramarobin/fctSPM/blob/master/Figures/1D_ANOVA2_1RM.png)

Post-hoc results: The curves represent the means and the standard deviations.
Right > Left between 30 and 85°.
The significant differences are displayed below the curves using the curves to display the pairwise comparisons.
The ANOVA results are also displayed if wanted.
![alt text](https://github.com/tramarobin/fctSPM/blob/master/Figures/1D_Post-hoc.png)


### In two dimensions ###
Here are the outcomes for a 2way ANOVA with 2 repeated measures in 2 dimensions  
.\fctSPM\Examples\D2_ANOVA2_2rm.m   
The maps represent the time-frequency analysis of vibratory signal quantified with two devices (ACC and US), and for two muscle activations (Relaxed and Contracted).

ANOVA results : Red clusters circled in white are the zone of significant effects. There are mains and interaction effects.
![alt text](https://github.com/tramarobin/fctSPM/blob/master/Figures/2D_ANOVA2_2RM.png)

Post-hoc results for main effects: Mean maps for each condition are displayed. 
Statistical results are shown within each map of differences on the top (Device effect) and at the bottom (Activation effect).
The significant cluster are circled in white.
![alt text](https://github.com/tramarobin/fctSPM/blob/master/Figures/2D_Post-hoc_MAIN.png)

Post-hoc results for interaction effects: Mean maps for each condition are displayed. 
Statistical results are shown within each map of differences on the right (Activation effect) and at the bottom (Device effect).
The significant cluster are circled in white. Note that the main effects are also displayed.
![alt text](https://github.com/tramarobin/fctSPM/blob/master/Figures/2D_Post-hoc_INT.png)

## Using fctSPM ##

### Installation ###
Put the folder fctSPM in any directory of your choice and make sure it is added to your path.  
To add source code directory to your path use `addpath(genpath("./fctSPM/src"))`  
If your are running examples from ./fctSPM/Examples, you can use `addpath(genpath("../src"))` to add the source code directory to your path


### Usage ###
```matlab
fctSPM(data, independantEffects, repeatedMeasuresEffects, varargin)
```


### Obligatory INPUTS ###

* `data` is a x by y cell array.  
x corresponds to a subjects and y corresponds to a repeated measure.     
Each cell contains a column vector (1D) or a matrix (2D) corresponding to the mean of the subject and condition.
* `independantEffects` is a cell array defining the independent effects.  
1 cell by effect.  
Each cell contains the name ('char') of each modality for the given subject and must correspond to the number of subjects/rows (x).
* `repeatedMeasuresEffects` is a cell array defining the repeated measure effects.  
1 cell by effect.    
Each cell contains the name ('char') of each modality for the given condition and must correspond to the number of conditions/columns (y). 


### Optional INPUTS ###
Optional inputs are available to personalize the figures.  
```matlab
fctSPM(data, independantEffects, repeatedMeasuresEffects, 'Optional Input Name', value)
```


#### Utilities ####
These options act on the name of the created folders.

* `savedir` is the path to the save directory. Default create a 'RESULTS' folder in the current path. @ischar.
* `effectsNames` are the names of the effects (the independent effects must be named first). Default names the effect {'A','B','C'}. @iscell.
* `plotSub` is an option (1 to activate) to plot the individual mean for each subject. Default = 0 and don't plot the mean. @isnumeric.
* `nameSub` is an option to name the different subjects. Default names the subject '1', '2',... @iscell.

#### Statistical parameters ####
These options act at a statistical level, modifying the alpha error or the number of iterations.

* `alpha` is the alpha error risk for the ANOVA. Default is 0.05. @isnumeric.
* `multiIT` define the number of permutations as multiIT/alpha. Default is 10, corresponds to 200 iterations for 5% risk.  
**Must be increased for better reproductibility.**
* `IT` is a fixed number of iterations (override the multiIterations - not recommended).    
Specified either multiIterations or IT, but not both.
* `maximalIT` is the limit of the number of maximal permutations in case of too many multiple comparisons. Default is 10000. @isnumeric.
* `alphaT` is the original alpha used for post hoc tests (Bonferonni correction is applied after as alphaT/number of comparisons. Default is 0.05. @isnumeric. (changes are not recommended)
* `nT` is the number of post hoc tests performed (override the alphaT - not recommended). @isnumeric.    
Specified either alphaT or nT, but not both.
* `doAllInteractions` By default, all post hoc tested are made even if ANOVA did not revealed interaction. Use 0 to performed only post-hoc when interaction was found. @isnumeric.
* `ignoreAnova` By default, consider the ANOVA significant location to interpret post-hoc. Use 1 to interpret only post-hoc tests (not recommended). @isnumeric.


#### General plot parameters ####
These options can modify the general aspect of the figures for 1D and 2D.

* `ylabel` are the labels of Y-axis. Default is empty. @ischar.
* `xlabel` are the labels of X-axis. Default is empty. @ischar.
* `samplefrequency` changes the xticks to correspond at the specified frequency. Default is 1. @isnumeric.
* `xlimits` changes the xticks to correspond to the specified range (can be negative). @isnumeric (e.g., [0 100]).   
Specified either samplefrequency or xlimits, but not both.
* `ylimits` changes the yticks to correspond to the specified range (can be negative). @isnumeric (e.g., [0 100]). 
* `nTicksX` is the number of xticks displayed. @isnumeric.
* `nTicksY` is the number of yticks displayed. @isnumeric.
* `imageresolution` is the resolution in ppp of the tiff images. Default is 300ppp. @isnumeric.
* `imageSize` is the size of the image in cm. y default the unit is normalized [0 0 1 1]. @isnumeric (e.g., X creates X by X cm images, [X Y] creates X by Y cm images.
* `imageFontSize` is the font size of images. Default is 12. @isnumeric.

#### 2D plot parameters ####
These option are specific to 2D plots.
  
* `colorMap` is the colormap used for means, standard deviations, ANOVA and effect sizes plots. Default is cbrewer('Reds').
* `colorMapDiff` is the colormap used for differences, relative differences and post-hoc spm plots. Default is cbrewer('RdBu').
  
Colormaps can be defined with cbrewer (included in this funtion): Charles (2020). cbrewer : colorbrewer schemes for Matlab (https://www.mathworks.com/matlabcentral/fileexchange/34087-cbrewer-colorbrewer-schemes-for-matlab), MATLAB Central File Exchange. Retrieved December 11, 2020.

* `colorbarLabel` is the name of the colorbar label. Default is empty. @ischar
* `limitMeanMaps` defines limit of the colorbar. By default, the maps wont necessary be with the same range but will be automatically scaled at their maximum.
A value of X will make the colorbar going from 0 to X for all plots (easier to compare). @isnumeric.
* `displaycontour` displays contour map on differences and size effect maps. 0 to not display (not recommended). @isnumeric.
* `contourcolor` is the color of the line for the contour plot. Default is white. RGB or 'color' is accepted.
* `linestyle` is the linestyle of the contour plot. Default is continuous line '-'.
* `dashedColor` is the color of the non-significant zones of the contour plot (default is black). Use RGB triplet [0 0 0].
* `transparancy` is the transparency of the non-significant zones. Default is 50. 0=transparent, 255=opaque. @isnumeric.
* `lineWidth` is the linewidth of the contour plot. Default is 2.5. @isnumeric.
* `diffRatio` scales the difference maps at limitMeanMaps*diffRatio. Default is 0.33. @isnumeric.
* `relativeRatio` scales the relative differences maps at +-relativeRatio. By default, the maps wont necessary be with the same range but will be automatically scaled at their maximum.

#### 1D plot parameters ####
These option are specific to 1D plots.

* `CI` is the confidence interval used instead of standard deviation. By default, standard deviations are displayed. @isnumeric (0.7 to 0.999 to display 70% to 99.9% condidence interval, or 0 to display SEM).
* `colorLine` is the colorline for plots (default  is "lines"). Use rgb triplet. If in cell, apply each color to each effect (independant effect first).
* `transparancy1D` is the transparency for the SD, CI or SEM. Default is 0.1. @isnumeric.
* `ratioSPM` is the ratio of SPM subplot relative to total figure (default if 1/3 of the figure). @isnumeric (e.g., [1 3]).
* `yLimitES` is the y-axis limits for ES representation. By default, the maps wont necessary be with the same range but will be automatically scaled at their maximum.
* `spmPos` is the position of SPM plot, default SPM analysis is displayed at the bottom of the figure. Any value will set the position to up.
* `aovColor` is the color of ANOVA on SPM plot. Default is black. Use 'color' or rgb.

