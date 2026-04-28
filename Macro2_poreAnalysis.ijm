/*
 * Program to perform automated measurements on all the stack from an AFM image, obtaining areas, HCFA and porosity
 * 
 * Authors: Dr Laia Pasquina-Lemonche & Matthew J Barker, University of Sheffield, UK
 * 			
 */

run("Close All");
run("Clear Results");
print("\\Clear");
wlist=getList("window.titles");
wlength=lengthOf(wlist);

for (i=0; i<wlength; i++) {
	selectWindow(wlist[i]);
	run("Close");
}

//Run initial pop-up window to get required inputs from user
Dialog.create("");
Dialog.addRadioButtonGroup("Are all of your images square?", newArray("Yes", "No"), 1, 2, "Yes");
Dialog.show();

square = Dialog.getRadioButton();

Dialog.create("");
Dialog.addDirectory("Select folder to process, THE SAME FOLDER YOU SELECTED FOR CODE 1", "");
Dialog.addFile("Select .txt file containing depths in nm", "");
if (square == "Yes"){
	Dialog.addFile("Select .txt file containing xy size in nm", "");
}
if (square == "No"){
	Dialog.addFile("Select .txt file containing x size in nm", "");
	Dialog.addFile("Select .txt file containing y size in nm", "");
}
Dialog.addRadioButtonGroup("Save individual slice data?", newArray("No", "X0 Slice Only", "All"), 3, 1, "No");
Dialog.show();

dirMain = Dialog.getString();

//Get list of stacks
dir0 = dirMain + File.getName(dirMain) + "_Stacks" + File.separator;
list0 = getFileList(dir0);

depthtxt = Dialog.getString();
xtxt = Dialog.getString();
if (square == "No"){
	ytxt = Dialog.getString();
}

saves = Dialog.getRadioButton();

//Select .txt file of image depths (nm) and extract values into an array
filestring=File.openAsString(depthtxt);
rows=split(filestring, "\n");
depths=newArray(rows.length);
for(i=0; i<rows.length; i++){
	depths[i]=parseFloat(rows[i]);
}

//Select .txt file of image x (nm) and extract values into an array
filestring1=File.openAsString(xtxt);
rows1=split(filestring1, "\n");
xs=newArray(rows1.length);
for(i=0; i<rows1.length; i++){
	xs[i]=parseFloat(rows1[i]);
}

if(square == "No"){
	//Select .txt file of image y (nm) and extract values into an array
	filestring2=File.openAsString(ytxt);
	rows2=split(filestring2, "\n");
	ys=newArray(rows2.length);
	for(i=0; i<rows2.length; i++){
		ys[i]=parseFloat(rows2[i]);
	}
}
else{
	ys=xs;
}

//Create save directory
dirsave = dirMain + File.separator + File.getName(dirMain) + "_Results" + File.separator;
File.makeDirectory(dirsave);

//YES calculates the half of cumulative fraction of total area later. NO does total number of pores. Leave as yes, code no longer functions otherwise
HCFAYN = "YES";

//Hide all the system processes
setBatchMode(true);

//Set up final results file
File.append("Image,Porosity,Exp Coefficient,X0 Depth (nm),Gaussian Width (nm),X0 HCFA (nm^2),X0 Diameter (nm)", dirsave + "Final_Results" + ".csv");

for (g=0; g<list0.length; g++){
	//Select stack folder and get list of images
	dir1 = dir0 + list0[g];
	list = getFileList(dir1);
	
	filename = substring(File.getName(dir1), 0, lengthOf(File.getName(dir1))-6);
	
	//Create results folder for single stack in the total results folder
	dir2 = dirsave + filename + "_results" + File.separator;
	File.makeDirectory(dir2);
	
	if(saves != "No"){
		dirlabel = dir2 + "Labelled Images" + File.separator;
		File.makeDirectory(dirlabel);
	}
	
	number_of_repetitions = list.length - 1;
	
	//Create the array for the final result to be stored in and the file to store this in
	HCFA = newArray(number_of_repetitions+1);
	headline = "Depth_slice_number,HCFA";
	File.append(headline, dir2 + "HCFA" + ".csv");
	
	//Create arrays to number of pores of different sizes and a file to save these in
	Yellow = newArray(number_of_repetitions);
	Green = newArray(number_of_repetitions);
	Magenta = newArray(number_of_repetitions);
	Blue = newArray(number_of_repetitions);
	DepthArray = newArray(number_of_repetitions); //Counts slice number
	Total_count = newArray(number_of_repetitions); //Counts total pores per slice
	slice_pore_volume = newArray(number_of_repetitions); // Collects total volume of each slice
	
	headline2 = "Depth_slice_number,Yellow_pores,Green_pores,Magenta_pores,Blue_pores,Total_number_pores";
	File.append(headline2, dir2 + "ColourCount" + ".csv");
	
	for (j = 0; j <= number_of_repetitions; j++) {
		print("\\Clear");
		print("Processing stack #" + g+1 + ", " + round(j/(number_of_repetitions+1)*100) + "%");
		
		//reset ROI manager, images and results
		if (roiManager("count")>0) {
			roiManager("Deselect");
			roiManager("Delete");
		}
		run("Close All");
		run("Clear Results");
		
		//Open image
		open(dir1 + list[j]);
		
		//Use depth of image to calculate depth per slice
		Depth = depths[g];
		XSize = xs[g];
		YSize = ys[g];
		getDimensions(width, height, channels, slices, frames);
		XConversion = XSize / width;
		YConversion = YSize / height;
		ZConversion = Depth/list.length;
		
		//Convert pixels to nm
		run("Properties...", "channels=1 slices=1 frames=1 unit=nm pixel_width="+XConversion+" pixel_height="+YConversion+" voxel_depth="+ZConversion+"");
		
		//Threshold the image to convert into the right format
		setAutoThreshold("Otsu dark");
		
		//Apply threshold.
		setOption("BlackBackground", true);
		run("Convert to Mask");
		
		//Obtain the table using ROIManager, measure
		run("Set Measurements...", "area standard centroid redirect=None decimal=1");
		run("Analyze Particles...", "size=2-Infinity include add lable");
		resetThreshold();
		
		//Visualise nothing
		roiManager("Show None");
		
		if (roiManager("count")>0) {
			number_of_rois = roiManager("count");
			
			//Create variables to count pores in each slice of different colours
			yellow_rois = 0;
			green_rois = 0;
			magenta_rois = 0;
			blue_rois = 0;
			
			//Classify rois by area and count how many of each colour
			for (i = 0; i < number_of_rois; i++) {
				//Select an ROI and rename it to the number ROI on the image
				roiManager("select", i);
				roiManager("rename", i+1);
				
				Area = getResult("Area", i);
				
				//Assign a colour depending on area
				if (Area <= 20) {
					Roi.setStrokeColor("yellow");
					Roi.setStrokeWidth(5);
					yellow_rois = yellow_rois + 1;
				}
				
				if (Area > 20 && Area <= 500) {
					Roi.setStrokeColor("green");
					Roi.setStrokeWidth(5);
					green_rois = green_rois + 1;
				}
				
				if (Area > 500 && Area <= 1500) {
					Roi.setStrokeColor("magenta");
					Roi.setStrokeWidth(5);
					magenta_rois = magenta_rois + 1;
				}
				
				if (Area > 1500) {
					Roi.setStrokeColor("blue");
					Roi.setStrokeWidth(5);
					blue_rois = blue_rois + 1;
				}
				
				//Add to the Overlay
				Overlay.useNamesAsLabels(true)
				Overlay.addSelection();
			}
			
			//Save processed image
			if(saves != "No"){
				saveAs("png", dirlabel+list[j]);
			}
			
			//Allocate the count of pores to the colour arrays and total
			Yellow[j] = yellow_rois;
			Green[j] = green_rois;
			Magenta[j] = magenta_rois;
			Blue[j] = blue_rois;
			Total_count[j] = number_of_rois;
			DepthArray[j] = j;
			
			//Save all the count values from all the pores in "ColourCount.csv
			contentline2 = "" + j + "," + Yellow[j] + "," +Green[j]+","+ Magenta[j]+ ","+ Blue[j]+","+ Total_count[j];
			File.append(contentline2, dir2+"ColourCount"+".csv");
			
			//Create an array and allocate all values of area
			to_sort = newArray(number_of_rois);
			Total = 0;
			
			for (i = 0; i < number_of_rois; i++) {
				//Select an ROI
				roiManager("select", i);
				
				//Allocate values to new array
				Area = getResult("Area", i);
				to_sort[i] = Area;
				
				//Calculate total area
				Total = Total + Area;
			}
			
			slice_pore_volume[j] = Total*ZConversion;
			
			//Sort the values of area by size (small->large)
			Sorted = Array.sort(to_sort);
			
			//Define arrays needed to calculate cumulative fraction of total area per slice
			cum_value = newArray(number_of_rois + 1);
			cum_fraction = newArray(number_of_rois + 1);
			cum_value[0] = Sorted[0];
			cum_fraction[0] = cum_value[0] / Total;
			
			for (i = 1; i < number_of_rois; i++) {
				//Calculate cumulative value
				cum_value[i] = cum_value[i - 1] + Sorted[i];
				//Calculate cumulative fraction of total area
				cum_fraction[i] = cum_value[i] / Total;
				
				if (HCFAYN == "YES") {
					//Calculate half of the cumulative fraction of the total area (HCFA) nm^2
					if (cum_fraction[i] > 0.4 && cum_fraction[i] < 0.55) {
						HCFA_in = i;
						HCFA[j] = Sorted[HCFA_in];
					}
				}
				if (HCFAYN == "NO") {
					//If not HCFA, just use total pores
					HCFA[j] = Total;
				}
			}
			
			//Create final results table with the raw Area, the sorted area and the cumulative fraction for each slice
			if(saves != "No"){
				table1 = "Results_table";
				Table.create(table1);
				
				for (i = 0; i < number_of_rois; i++) {
					Area = getResult("Area", i);
					Table.set("Raw Area", i, Area);
					Table.set("Area Sorted", i, Sorted[i]);
					Table.set("Cumulative Fraction", i, cum_fraction[i]);
				}
				
				saveAs("Results", dirlabel + File.nameWithoutExtension + ".csv");
			}
		}
		
		//If no ROIs, set HCFA = 0
		else{
			HCFA[j] = 0;
		}
		
		//Save all HCFA values from all repetitions in one file (HCFA.csv)
		ValueLine = HCFA[j];
		if (ValueLine > 0) {
			contentline = "" + j + "," + HCFA[j];
			File.append(contentline, dir2 + "HCFA" + ".csv");
		}
		
		//Close random table that keeps appearing every iteration
		name = File.nameWithoutExtension + ".csv";
		isopen = isOpen(name);
		if(isopen == true) {
			selectWindow(name);
			run("Close");
		}
	}
	
	//Close results table
	name2 = "Results";
	if (isOpen(name2)) {
		selectWindow(name2);
		run("Close");
	}
	
	//Remove zero values for depth array that appears for some reason
	for (i = 0; i < DepthArray.length; i++) {
		if (DepthArray[i] == 0 && Total_count[i] == 0) {
			DepthArray = Array.deleteIndex(DepthArray, i);
			Total_count = Array.deleteIndex(Total_count, i);
			HCFA = Array.deleteIndex(HCFA, i);
			i--;
		}
	}
	
	//Fit Gaussian and retrieve parameters
	Fit.doFit("Gaussian", DepthArray, Total_count);
	x = DepthArray;
	a = Fit.p(0);
	b = Fit.p(1);
	c = Fit.p(2);
	d = Fit.p(3);
	y = newArray(DepthArray.length);
	
	//Function to calculate Gaussian values as Fit.plot didn't want to work
	for (i = 0; i < x.length; i++) {
		y[i] = a+(b-a)*Math.exp(-(x[i]-c)*(x[i]-c)/(2*d*d));
	}
	
	//Plot the data and fitted Gaussian
	Plot.create("Number of pores per slice", "Slice Number", "Number of Pores", DepthArray, Total_count);
	Plot.add("line", x, y);
	Plot.show();
	
	//Obtain xo and FWHM from the Gaussian
	xo = round(c);
	FWHM = round(2.35*d);
	top_FWHM = xo + round(FWHM/2);
	bottom_FWHM = xo - round(FWHM/2);
	two_sig = round(4*d);
	top_two_sig = xo + round(two_sig/2);
	bottom_two_sig = xo - round(two_sig/2);
	volume_in_FWHM = (FWHM*ZConversion)*XSize*YSize;
	FWHM_pore_volume = 0;
	Error = 0;
	
	//add if to make sure this works even if the image does not follow a gaussian fit
	if(top_FWHM >= number_of_repetitions){
		top_FWHM = list.length;
		Error = 2;
	}
	if(bottom_FWHM <= 0){
		bottom_FWHM = 0;
		Error = 1;
	}

	for (f=bottom_FWHM; f<=top_FWHM; f++){
		if (f < slice_pore_volume.length){
			FWHM_pore_volume = FWHM_pore_volume + slice_pore_volume[f];
		}
	}

	//Get porosity of the image
	pore_ratio = FWHM_pore_volume/volume_in_FWHM;
	
	//File.append(pore_ratio, dirsave + "Porosities" + ".csv");
	
	//Retrieve the HCFA values for xo and FWHM values
	HCFA_bottom = 0;
	HCFA_top = 0;
	k=0;
	m=0;
	
	for (i = 0; i < DepthArray.length; i++) {
		//set HCFA value
		if (DepthArray[i] == xo) {
			HCFA_xo = HCFA[i];
		}
		if (DepthArray[i] == bottom_FWHM) {
			HCFA_bottom = HCFA[i];
			k = i;
		}
		if (DepthArray[i] == top_FWHM) {
			HCFA_top = HCFA[i];
			m = i;
		}
	}
	
	Error = 0;
	//double check that the negative FWHM is not falling outside of list
	if(HCFA_bottom == 0){
		for(i=0; i < HCFA.length; i++) {
			if(HCFA[i] > 0) {
			HCFA_bottom = HCFA[i];
			bottom_FWHM = DepthArray[i];
			k = i;
			Error = 1;
			break;
			}
		}
	}
	//double check that the positive FWHM is in the list (which is an error from the way code 2 works)
	if(HCFA_top == 0){
		for (i = 0; i < DepthArray.length; i++) {
			if(DepthArray[i] == top_FWHM-1){
			m = i;
			HCFA_top = HCFA[m];
			}else{
			
			Diff_sigma = newArray(DepthArray.length);
				for(i = 0; i < DepthArray.length; i++){
				Diff_sigma[i] = abs(DepthArray[i]-top_FWHM);
				}
			Stats = Array.getStatistics(Diff_sigma, min_Diff, max_Diff, mean_Diff, stdDev_Diff);
			//print(Stats);
			//print(Stats[1]);
				for(i = 0; i < Diff_sigma.length; i++){
					if (Diff_sigma[i] == Stats[1]){
						m = i;
						HCFA_top = HCFA[m];
					}
				}
		
			}
		 Error = 2;	
		}
	}
	
	//Save gaussian and fit graph
	selectWindow("Number of pores per slice");
	saveAs(".PNG", dir2+"Gaussian_and_fit");
	
	//Set up arrays within FWHM for fitting
	tempDepthArray_FWHM = newArray(FWHM);
	tempHCFA_FWHM = newArray(FWHM);
	fitted_HCFA = newArray(FWHM);
	
	for (i=0; i<=FWHM; i++) {
		if (i+bottom_FWHM < DepthArray.length) {
			tempDepthArray_FWHM[i] = DepthArray[i+bottom_FWHM];
			tempHCFA_FWHM[i] = HCFA[i+bottom_FWHM];
		}
	}
	
	//Remove any 0 values
	for (i=0; i<FWHM; i++){
		if (i < DepthArray.length) {
			HCFAvalue = tempHCFA_FWHM[i];
			Depthvalue = tempDepthArray_FWHM[i];
			if (HCFAvalue > 0){
				if (i == 0){
					HCFA_FWHM = newArray(1);
					HCFA_FWHM[0] = HCFAvalue;
					DepthArray_FWHM = newArray(1);
					DepthArray_FWHM[0] = Depthvalue;
				}
				else{
					HCFA_FWHM = Array.concat(HCFA_FWHM, HCFAvalue);
					DepthArray_FWHM = Array.concat(DepthArray_FWHM, Depthvalue);
				}
			}
		}
	}
	
	//Array.show(DepthArray, HCFA, DepthArray_FWHM, HCFA_FWHM);
	
	//Fit exp line to HCFA
	Fit.doFit("Exponential", DepthArray_FWHM, HCFA_FWHM);
	power = Fit.p(1);
	mult = Fit.p(0);
	
	for (l=0; l<DepthArray_FWHM.length; l++) {
		fitted_HCFA[l] = mult*exp(DepthArray_FWHM[l]*power);
	}
	
	//Plot and save HCFA graph and fit
	Plot.create("HCFA per Slice", "Slice Number", "HCFA", DepthArray_FWHM, HCFA_FWHM);
	Plot.add("line", DepthArray_FWHM, fitted_HCFA);
	Plot.show();
	selectWindow("HCFA per Slice");
	saveAs(".PNG", dir2+"HCFA_Graph");
	
	//Calculate HCFA values at FWHM points
	HCFA_bottom = fitted_HCFA[0];
	HCFA_top = fitted_HCFA[fitted_HCFA.length-1];
	
	//Calculating diameter of pores if they were perfectly circular with the corresponding measured areas
	Diam_xo = 2*sqrt(HCFA_xo/PI);
	Diam_bottom = 2*sqrt(HCFA_bottom/PI);
	Diam_top = 2*sqrt(HCFA_top/PI);
	
	//Convert depths from slices to nm
	Depth_nm_bottom = bottom_FWHM*ZConversion;
	Depth_nm_xo = xo*ZConversion;
	Depth_nm_top = top_FWHM*ZConversion;
	Depth_nm_two_sig_bottom = bottom_two_sig*ZConversion;
	Depth_nm_two_sig_top = top_two_sig*ZConversion;
	
	//Setup file in designated folder
	contentline3 = " " + "," + "Slice" + "," + "Depth in Gaussian (nm)" + "," + "HCFA" + "," + "Diameter";
	contentline4 = "Bottom FWHM" + "," + bottom_FWHM + "," + Depth_nm_bottom-Depth_nm_two_sig_bottom + "," + HCFA_bottom + "," + Diam_bottom; 
	contentline5 = "xo" + "," + xo + "," + Depth_nm_xo-Depth_nm_two_sig_bottom + "," + HCFA_xo + "," + Diam_xo;
	contentline6 = "Top FWHM" + "," + top_FWHM + "," + Depth_nm_top-Depth_nm_two_sig_bottom + "," + HCFA_top + "," + Diam_top;
	
	File.append(contentline3, dir2 + "Final" + ".csv");
	File.append(contentline4, dir2 + "Final" + ".csv");
	File.append(contentline5, dir2 + "Final" + ".csv");
	File.append(contentline6, dir2 + "Final" + ".csv");
	
	//Add error message if the HCFA_bottom and/or HCFA_top couldn't be calculated with 2 sigma
	if(Error == 1){
		
		Bottom_error = "Value of Bottom FWHM not in the list so top error bar is first HCFA value";
		contentline7 = "Error message" + "," + Bottom_error;
		File.append(contentline7, dir2 + "Final" + ".csv");
	}
	
	//I doubt I will need to put this, probably remove it!
	if(Error == 2){
		
		//if(Bottom_error.length > 0){
		Top_error = "No bottom error bar because Top FWHM not in the HCFA list, I chosen the previous value";
		contentline8 = "Error message_2" + "," + Top_error;
		File.append(contentline8, dir2 + "Final" + ".csv");
		//}
		//Top_error = "No bottom error bar because sigma distance from xo not in the HCFA list";
		//contentline8 = "Error message" + "," + Top_error;
		//File.append(contentline8, dir2 + "Final" + ".csv");
		
	}
	
	//Log HCFA values as well as converting depth into nm
	for (i = 0; i < HCFA_FWHM.length; i++) {
		HCFA_FWHM[i] = log(HCFA_FWHM[i]);
		DepthArray_FWHM[i] = ((DepthArray_FWHM[i]-bottom_two_sig)*ZConversion);
	}
	
	//Fit straight line to the log graph in order to get exponential coefficient
	Fit.doFit("Straight Line", DepthArray_FWHM, HCFA_FWHM);
	A = Fit.p(0);
	B = -Fit.p(1);
	
	fitted_log = newArray(HCFA_FWHM.length);
	
	for (l=0; l<HCFA_FWHM.length; l++) {
		fitted_log[l] = (A - B*DepthArray_FWHM[l]);
	}
	
	//Plot and save the log graph
	Plot.create("Log Graph", "Depth (nm)", "log(HCFA) (nm^2)", DepthArray_FWHM, HCFA_FWHM);
	Plot.add("line", DepthArray_FWHM, fitted_log);
	Plot.show();
	selectWindow("Log Graph");
	saveAs(".PNG", dir2+"HCFA_LOG_Graph");
	
	//Set up a csv file for the log graph
	contentlineA = "Depth (nm)" + "," + "log_HCFA";
	File.append(contentlineA, dir2 + "HCFA_log" + ".csv");
	for (i = 0; i < HCFA_FWHM.length; i++) {
		contentlineC = "" + DepthArray_FWHM[i] + "," + HCFA_FWHM[i];
		File.append(contentlineC, dir2 + "HCFA_log" + ".csv");
	}
	
	File.append("", dir2 + "Final" + ".csv");
	File.append("FWHM Volume" + "," + volume_in_FWHM, dir2 + "Final" + ".csv");
	File.append("Pore Volume in FWHM" + "," + FWHM_pore_volume, dir2 + "Final" + ".csv");
	File.append("Pore Ratio" + "," + pore_ratio, dir2 + "Final" + ".csv");
	
	//Add exp coefficient to the Final.csv
	contentlineB = "exp coefficient" + "," + B;
	File.append("", dir2 + "Final" + ".csv");
	File.append(contentlineB, dir2 + "Final" + ".csv");
	
	File.append(filename + "," + pore_ratio + "," + B + "," + Depth_nm_xo-Depth_nm_two_sig_bottom + "," + Depth_nm_two_sig_top-Depth_nm_two_sig_bottom + "," + HCFA_xo + "," + Diam_xo, dirsave + "Final_Results" + ".csv");
	
	if(saves == "X0 Slice Only"){
		listlabel = getFileList(dirlabel);
		for(a = 0; a < listlabel.length; a++){
			if(a != (xo*2)+1 && a != (xo*2)){
				File.delete(dirlabel + listlabel[a]);
			}
		}
		listlabel = getFileList(dirlabel);
		for(a = 0; a < listlabel.length; a++){
			open(dirlabel+listlabel[a]);
			if(endsWith(listlabel[a], "csv")){
				saveAs("Results", dir2 + "X0_Slice.csv");
			}
			if(endsWith(listlabel[a], "png")){
				saveAs("png", dir2+"X0_Slice.png");
			}
			File.delete(dirlabel+listlabel[a]);
		}
		File.delete(dirlabel);
		close("X0_Slice.csv");
		close("X0_Slice.png");
	}
}
run("Close All");
print("\\Clear");
close(name);
close("Results_table");
close("Log");

//Final dialogue
Dialog.create("");
Dialog.addMessage("Finished! Thank you for using AFMSlicer :)");
Dialog.show();