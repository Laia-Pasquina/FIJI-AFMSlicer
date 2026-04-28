# AFM_Slicer

**Location:** School of Mathematical and Physical Sciences, University of Sheffield, UK. and School of Biosciences, University of Sheffield, UK.
**Updated:** April 2026 Dr Laia Pasquina Lemonche (https://github.com/Laia-Pasquina) and Matthew J Barker (https://github.com/Mjbarker2) (cc)

## Description of the program

The typical representation of AFM images is a collection of points in a 3D matrix. 
However, they cannot be directly analysed in 3D as the currently available software is
very limited and is designed to analyse features in 2D. Here, a collection of FIJI macros 
were made to slice and analyse AFM images into tomography-like stacks that can be read and 
interpreted by most 3D visualisation software like Blender or Imaris.

**Macro 1: Slicing:**

This code allows typical AFM images to be sliced into a stack of binary 2D slices. 
The resultant image can then be further analysed using **Macro 2** or **Macro 3**. 

**Macro 2: Pore Analysis:**

This code analyses properties of the pores in each of the 2D slices and then outputs a list of 
values for each slice. It then produces a summary of the HCFA (Half cumulative fraction of Area) for the entire image.
These results were used to create the graphs of CFA vs Area in the [Science Publication](https://doi.org/10.1126/science.adn1369). 
Porosity of the material is also calculated.

**Macro 3: Volume Analysis**

This code analyses the volume of objects on a surface in an AFM image.

## Steps to follow 

1. These are **FIJI macros**, so the first step is to **Download and Install FIJI**, [here](https://imagej.net/downloads).
2. The following update sites are required within FIJI: **ImageJ**, **FIJI**, **Java-8**, **3D ImageJ Suite**, **IBMP-CNRS**, **IJPB-plugins**, **ImageScience**, **PTBIOP**. 
3. The code is currenlty composed of Macro 1, Macro 2 and Macro 3. Macro 1 should always be run first, followed by macro 2 for pore analysis, or macro 3 for volume analysis.
4. The imput file should be an AFM height image in .tif format extracted preferably from open-source software like Gwyddion or TopoStats, but other non-open source formats are accepted too. 
5. **IMPORTANT**  `The imput image should not have any scale bar, colour bar or any additional drawing, just the image without any edges` e.g. in Gwyddion you can do this by following these instructions: _File > Save as > File type (.TIFF) > Export Tiff window > Lateral scale (None) > Value scale (None) > Image draw frame (unticked)_
6. For each set of images being run, you will need a .txt file for each of the xy dimensions, and for the z-range of the images. See Example_xy.txt and Example_depths.txt for how to set up this data.
7. Open Macro 1 in FIJI and click **Run**, follow the instructions in the popup windows. Slice number should be optimised to your datasets, but we recommend 2 nm z-resolution for volumes, and 0.1 nm resolution for pores
8. For pore analysis, run Macro 2 and selecct the same folder of images that you selected for Macro 1, followed by your xy and depth .txt files.
9. For volume analysis, run Macro 3 and select the same folder of images that you selected for Macro 1 followed by your xy and depth .txt files.
10. The results can be found in the Results folder.

Follow **AFMSlicer tutorial video** for a detail step-by-step use of the two codes to analyse an image of AFM containing pores.