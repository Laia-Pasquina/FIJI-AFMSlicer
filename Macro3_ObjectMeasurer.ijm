/*
 * Program to perform automated measurements on all the stack from an AFM image, obtaining Volumes of objects
 * 
 * Authors: Dr Laia Pasquina-Lemonche & Matthew J Barker, University of Sheffield, UK
 * 			
 */

//Ensure everything is closed
run("Close All");
run("Clear Results");
print("\\Clear");
wlist=getList("window.titles");
wlength=lengthOf(wlist);

for (i=0; i<wlength; i++) {
	selectWindow(wlist[i]);
	run("Close");
}

//Ask whether images are square to know how many .txt files to ask for
Dialog.create("");
Dialog.addRadioButtonGroup("Are all of your images square?", newArray("Yes", "No"), 1, 2, "Yes");
Dialog.show();

square = Dialog.getRadioButton();

//Ask for dimensions of images, preferences of analysis method, and files to be saved
Dialog.create("");
Dialog.addDirectory("Select folder to process", "");
Dialog.addFile("Select .txt file containing depths in nm", "");

if (square == "Yes"){
	Dialog.addFile("Select .txt file containing xy size in nm", "");
}
		
if (square == "No") {
	Dialog.addFile("Select .txt file containing x size in nm", "");
	Dialog.addFile("Select .txt file containing y size in nm", "");
}

Dialog.addRadioButtonGroup("How should volume be calculated?", newArray("To Watershed", "Top 50% of Image", "Total Apparent Volume"), 3, 1, "To Watershed");
Dialog.addMessage("Image save options:");
Dialog.addCheckbox("Numbered image", false);
Dialog.addCheckbox("Segmented Stack", false);
Dialog.addCheckbox("Segmented Stack Labelled by Position", false);
Dialog.addCheckbox("Segmented Stack Labelled by Volume", false);
Dialog.show();

dirMain = Dialog.getString();
depthtxt = Dialog.getString();
xtxt = Dialog.getString();
if (square == "No"){
	ytxt = Dialog.getString();
}

volume_method = Dialog.getRadioButton();
save_numbered = Dialog.getCheckbox();
save_segmented = Dialog.getCheckbox();
save_labelled = Dialog.getCheckbox();
save_volume = Dialog.getCheckbox();

//Obtain directories of images to analyse - works off the file structure created by code 1
dir0 = dirMain + File.separator + File.getName(dirMain) + "_Stacks" + File.separator;
list0 = getFileList(dir0);

dirFilt = dirMain + File.separator + File.getName(dirMain) + "_Filtered" + File.separator;
listFilt = getFileList(dirFilt);


//Create folders for saving images and data requested
if (save_segmented == true){
	File.makeDirectory(dirMain + File.separator + File.getName(dirMain) + "_SegmentedStacks");
}

File.makeDirectory(dirMain + File.separator + File.getName(dirMain) + "_LabelledStacks");

if (save_volume == true){
	File.makeDirectory(dirMain + File.separator + File.getName(dirMain) + "_VolumeStacks");
}
//File.makeDirectory(dirMain + File.separator + File.getName(dirMain) + "_ROIs");
//roisavepoint = dirMain + File.separator + File.getName(dirMain) + "_ROIs" + File.separator;
if (save_numbered == true){
	File.makeDirectory(dirMain + File.separator + File.getName(dirMain) + "_Numbered");
	numbersavepoint = dirMain + File.separator + File.getName(dirMain) + "_Numbered" + File.separator;
}

File.makeDirectory(dirMain + File.separator + File.getName(dirMain) + "_Volumecsvs");

//Select .txt file of image depths (nm) and extract values into an array
filestring=File.openAsString(depthtxt);
rows=split(filestring, "\n");
depths=newArray(rows.length);
for(i=0; i<rows.length; i++){
depths[i]=parseFloat(rows[i]);
}

//Select .txt file of image xy (nm) and extract values into an array
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

//Hide all the system processes
roiManager("Show None");
setBatchMode(true);

repeat_values = false;

for (g=0; g<list0.length; g++){
	
	//Select stack folder and get list of images
	dir1 = dir0 + list0[g];
	list = getFileList(dir1);
	number_slices = list.length;
	
	//Generate base name of save files
	dirname = substring(File.getName(dir1),0,lengthOf(File.getName(dir1))-6);
	
	//Create sub-save folders for each image
	dirsegsave = dirMain + File.separator + File.getName(dirMain) + "_LabelledStacks" + File.separator + dirname + "_SegmentedLabelled" + File.separator;
	File.makeDirectory(dirsegsave);
	
	if(save_segmented == true){
		BWdirsegsave = dirMain + File.separator + File.getName(dirMain) + "_SegmentedStacks" + File.separator + dirname + "_Segmented" + File.separator;
		File.makeDirectory(BWdirsegsave);
	}
	
	if (save_volume == true){
		voldirsegsave = dirMain + File.separator + File.getName(dirMain) + "_VolumeStacks" + File.separator + dirname + "_VolumeLabelled" + File.separator;
		File.makeDirectory(voldirsegsave);
	}
	
	//Use depth of image to calculate depth per slice
	Depth = depths[g];
	XSize = xs[g];
	YSize = ys[g];
	PercDepth = 0.5;
	SlicePercDepth = round(PercDepth*number_slices);
	
	x_pos = newArray();
	y_pos = newArray();
	
	for (j = 0; j <= SlicePercDepth; j++) {
		print("\\Clear");
		print("Generating watershed for stack #" + g+1 + ", " + parseInt(j/SlicePercDepth*100) + "%");
		
		//reset ROI manager, images and results
		if (roiManager("count")>0) {
			roiManager("Deselect");
			roiManager("Delete");
		}
		
		run("Close All");
		run("Clear Results");
		
		//Open image
		open(dir1 + list[j]);
		title = getTitle();
		
		//Convert pixels to nm
		//run("Properties...", "channels=1 slices=1 frames=1 unit=nm pixel_width="+XYconversion+" pixel_height="+XYconversion+" voxel_depth="+Depthconversion+"");
		
		//Threshold the image to convert into the right format
		setAutoThreshold("Otsu dark");
		
		//Apply threshold. true puts holes in white, false puts them in black
		setOption("BlackBackground", true);
		run("Convert to Mask");
		
		//Obtain the table using ROIManager, measure
		run("Set Measurements...", "area centroid redirect=None decimal=1");
		run("Analyze Particles...", "size=50-Infinity include add label");
		resetThreshold();
		
		if (roiManager("count")>0) {
			number_of_rois = roiManager("count");
			
			for (i = 0; i < number_of_rois; i++) {
				//Select an ROI
				roiManager("select", i);
				
				x_posi = getResult("X", i);
				y_posi = getResult("Y", i);
					
				//Check against if any already recorded seeds are within that ROI
				for (k=0; k < x_pos.length; k++) {
					is_contained = Roi.contains(x_pos[k], y_pos[k]);
					if (is_contained == true){
						repeat_values = true;
					}
				}
				if (repeat_values == false){
					x_pos = Array.concat(x_pos, x_posi);
					y_pos = Array.concat(y_pos, y_posi);
				}
				repeat_values = false;
			}
		}
	}
	roiManager("reset");
	
	getDimensions(width, height, channels, slices, frames);
	
	setColor(255);

	//Generate image of seeds of objects
	newImage("Seeds", "8-bit black", width, height, 1);
	l=4;
	for (j = 0; j < x_pos.length; j++) {
		if(x_pos[j] != width/2 && y_pos[j] != width/2){
			fillOval(x_pos[j]-2, y_pos[j]-2, l, l);
		}
	}
	//saveAs("tiff", dirMain + "seeds");
	
	//Convert to single pixels
	run("Find Maxima...", "prominence=200 output=[Single Points]");
	
	//Rename Image
	selectImage("Seeds Maxima");
	//saveAs("tiff", dirMain + "seeds");
	rename("Maxima");
	
	//Open Filtered image from Code 1
	open(dirFilt + listFilt[g]);
	rename("filtered");
	//saveAs("tiff", dirMain + "FilterCheck");
	
	//Run 3D watershed - IF WATERSHED IS CONSTANTLY TOO HIGH OR TOO LOW, ADJUST IMAGE_THRESHOLD HERE
	if(bitDepth() == 16){
		run("3D Watershed", "seeds_threshold=1 image_threshold=10000 image=filtered seeds=Maxima radius=2");
	}
	else{
		run("3D Watershed", "seeds_threshold=100 image_threshold=100 image=filtered seeds=Maxima radius=2");
	}
	print("\\Clear");
	print("Applying labels for stack #" + g+1);
	//saveAs("tiff", dirMain + "labels");
	
	setBatchMode(false);
	
	//Generate ROIs from the watershed image
	selectImage("watershed");
	run("Label image to composite ROIs");
	roiManager("Show None");
	
	setBatchMode(true);
	raw_number_of_WSrois = roiManager("count");
	
	//Remove any ROIs touching the edge of the image
	getDimensions(width, height, channels, slices, frames);
	for(i=roiManager("count");i>0;i--){
		roiManager("select", i-1);
		getSelectionBounds(x, y, width1, height1);
		if ((x==0)||(y==0)||((x+width1)==width)||((y+height1)==height)) roiManager("delete");
	}
	number_of_WSrois = roiManager("count");
	
	//Label each cell on filtered image - number associates with number is results csv file
	open(dirFilt + listFilt[g]);
	rename("filtered_temp");
	for(i=0; i<number_of_WSrois; i++){
		roiManager("select", i);
		roiManager("rename", i+1);
		Roi.setStrokeWidth(0);
		Overlay.useNamesAsLabels(true);
		Overlay.drawLabels(true);
		Overlay.addSelection();
		Overlay.setLabelColor("black");
	}
	if (save_numbered == true){
		saveAs("png", numbersavepoint+ dirname + "_Numbered");
	}
	close("filtered_temp");
	selectImage("watershed");
	
	final_volumes = newArray(number_of_WSrois);
	final_radius = newArray(number_of_WSrois);
	check_filled = newArray(number_of_WSrois);
	
	//labels = newArray(number_of_WSrois);
	
	//Measure areas of all ROIs to know when watershed is hit
	run("Set Measurements...", "area centroid redirect=None decimal=1");
	roiManager("deselect");
	roiManager("measure");
	final_areas = Table.getColumn("Area");
	close("Results");
	//roiManager("Save", roisavepoint + "WSROI.zip");
	
	//Inverse watershed to subtract from each slice
	setAutoThreshold("Otsu dark");
	setThreshold(1, 65535, "raw");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Analyze Particles...", "size=1-Infinity show=Masks exclude include");
	run("Invert");
	rename("watershed_inverted");
	
	close("filtered");
	close("Maxima");
	close("Seeds");
	close("watershed");
	close(title);
	
	for (j=0; j<list.length; j++) {
		run("Clear Results");
		print("\\Clear");
		
		//Print progress
		if(volume_method == "Top 50% of Image"){
			print("Analysing stack #" + g+1 + ", " + parseInt(2*j/list.length*100) + "% complete");
		}
		else{
			print("Analysing stack #" + g+1 + ", " + parseInt(j/list.length*100) + "% complete");
		}
		
		//Reset whether all objects at watershed depth
		all_matched = false;
		
		//Skip bottom half of image for top 50%
		if(volume_method == "Top 50% of Image"){
			for(k=0; k<number_of_WSrois; k++){
				if (j < list.length/2){
					all_matched = false;
					break;
				}
				else{
					all_matched = true;
				}
			}
		}
		
		//Check if each object has hit watershed area, and break if so
		else{
			for(k=0; k<number_of_WSrois; k++){
				if (check_filled[k] == 0){
					all_matched = false;
					break;
				}
				else{
					all_matched = true;
				}
			}
		}
		
		if(all_matched == false) {
			//Open slice and subtract watershed
			open(dir1 + list[j]);
			name = getTitle();
			imageCalculator("Subtract create", name, "watershed_inverted");
			savename = substring(name,0,lengthOf(name)-4);
			savename1 = substring(name,0,lengthOf(name)-4);
			if(save_segmented == true){
				saveAs("tiff", BWdirsegsave+savename+"_Segmented");
			}
			name2 = getTitle();
			
			//Measure area and centroid position of each object
			run("Set Measurements...", "area centroid redirect=None decimal=1");
			run("Analyze Particles...", "size=1-Infinity include add label");
			roiManager("Show None");
			
			//Check any objects are present, and calculate number of them. Then apply labels to each
			if (roiManager("count")>number_of_WSrois) {
				number_of_labels = roiManager("count")-number_of_WSrois;
				run("Connected Components Labeling", "connectivity=4 type=[8 bits]");
				name1 = getTitle();
				
				//Find coordinates and label of each object
				for(l=0; l<number_of_labels; l++) {
					x_posi = round(getResult("X", l));
					y_posi = round(getResult("Y", l));
					pix_value = getPixel(x_posi, y_posi);
					
					//Get area of object
					area = getResult("Area", l);
					
					//If pixel value = 0 (can happen if only single pixel point), search nearby pixels to locate label
					if (pix_value == 0) {
						for (a=-1; a<=1; a++){
							for (b=-1; b<=1; b++){
								x = x_posi + a;
								y = y_posi + b;
								pix_value = getPixel(x, y);
								if (pix_value > 0){
									break;
								}
							}
							if (pix_value > 0){
								break;
							}
						}
					}
					
					//Reassign label to the same value throughout the stack. Then add volume (area x slice depth) to an array to sum later, and update final radius, so that the last run gives the last radius
					for(k=0; k < number_of_WSrois; k++){
						roiManager("select", k);
						contained = Roi.contains(x_posi, y_posi);
						if (contained == true) {
							run("Replace/Remove Label(s)", "label(s)="+pix_value+" final="+raw_number_of_WSrois+k+4+"");
							if(area < final_areas[k]){
								getDimensions(width, height, channels, slices, frames);
								final_volumes[k] += (parseFloat(area)*((XSize*YSize)/(width*height)))*(parseFloat(Depth)/list.length);
								final_radius[k] = sqrt((parseFloat(area)*((XSize*YSize)/(width*height)))/PI);
								//labels[k] = raw_number_of_WSrois+k+4;
							}
							else{
								check_filled[k] = 1;
							}
							break;
						}
					}
					//If object is not within already defined objects, remove label
					if (contained == false) {
						run("Replace/Remove Label(s)", "label(s)="+pix_value+" final=0");
					}
				}
				
				//Remove extra items from ROI Manager - leaving only the ROIs from the original image
				run("Remove Overlay");
				roiManager("Deselect");
				for (i=0; i<number_of_labels; i++){
					roiManager("select", roiManager("count")-1);
					roiManager("delete");
				}
				
				//Save labelled image, and close everything
				saveAs("tiff", dirsegsave+savename+"_Labelled");
				close();
				close(name);
				close(name1);
				close(name2);
				close("Result of " + name);
			}
			else{
				//If no detected objects, save image and move on
				run("Remove Overlay");
				saveAs("tiff", dirsegsave+savename+"_Labelled");
				if (save_segmented == true){
					saveAs("tiff", BWdirsegsave+savename+"_Segmented");
				}
				close();
				close(name);
			}
			end_slice = j;
		}
		
		//If all matched already true, save previous image with updated name to finish the stack
		if (volume_method == "Total Apparent Volume"){
			if (all_matched == true) {
				if(save_labelled == true){
					if(list.length < 1000){
						open(dirsegsave+savename+"_Labelled.tif");
						name = getTitle();
						if(j >= 10){
							if(j >= 100){
								savename = substring(name,0,lengthOf(name)-16) + j;
							}
							else{
								savename = substring(name,0,lengthOf(name)-16) + "0" + j;
							}
						}
						else{
							savename = substring(name,0,lengthOf(name)-16) + "00" + j;
						}
						saveAs("tiff", dirsegsave+savename+"_Labelled");
					}
					else{
						open(dirsegsave+savename+"_Labelled.tif");
						name = getTitle();
						if(j >= 10){
							if(j >= 100){
								if(j >= 1000){
									savename = substring(name,0,lengthOf(name)-17) + j;
								}
								else{
									savename = substring(name,0,lengthOf(name)-17) + "0" + j;
								}
							}
							else{
								savename = substring(name,0,lengthOf(name)-17) + "00" + j;
							}
						}
						else{
							savename = substring(name,0,lengthOf(name)-17) + "000" + j;
						}
						saveAs("tiff", dirsegsave+savename+"_Labelled");
					}
				}
				if(save_segmented == true){
					if(list.length < 1000){
						open(BWdirsegsave+savename1+"_Segmented.tif");
						name = getTitle();
						if(j >= 10){
							if(j >= 100){
								savename1 = substring(name,0,lengthOf(name)-17) + j;
							}
							else{
								savename1 = substring(name,0,lengthOf(name)-17) + "0" + j;
							}
						}
						else{
							savename1 = substring(name,0,lengthOf(name)-17) + "00" + j;
						}
						saveAs("tiff", BWdirsegsave+savename1+"_Segmented");
					}
					else{
						open(BWdirsegsave+savename1+"_Segmented.tif");
						name = getTitle();
						if(j >= 10){
							if(j >= 100){
								if(j >= 1000){
									savename1 = substring(name,0,lengthOf(name)-18) + j;
								}
								else{
									savename1 = substring(name,0,lengthOf(name)-18) + "0" + j;
								}
							}
							else{
								savename1 = substring(name,0,lengthOf(name)-18) + "00" + j;
							}
						}
						else{
							savename1 = substring(name,0,lengthOf(name)-18) + "000" + j;
						}
						saveAs("tiff", BWdirsegsave+savename1+"_Segmented");
					}
				}
			}
		}
	}
	run("Close All");
	run("Clear Results");
	close("ROI Manager");
	print("\\Clear");
	print("Compiling data for stack #"+g+1+", please be patient. This may take a while if doing a lot of slices and/or pixels");
	
	//Open labelled stack, assign dimensions and calculate volume
	File.openSequence(dirsegsave);
	getDimensions(width, height, channels, slices, frames);
	run("Properties...", "channels=1 slices="+slices+" frames=1 pixel_width="+XSize/width+" pixel_height="+YSize/height+" voxel_depth="+Depth/list.length+"");
	run("Analyze Regions 3D", "volume euler_connectivity=6");
	
	//Remove any stray objects that sometimes appear
	rows_to_delete = 0;
	for(i=0; i<Table.size; i++) {
		value = parseFloat(Table.getString("Label", i));
		if(value < raw_number_of_WSrois+4) {
			rows_to_delete += 1;
		}
		else {
			Table.set("Label", i, i-(rows_to_delete-1));
		}
	}
	if(rows_to_delete > 0) {
		Table.deleteRows(0, rows_to_delete-1);
	}
	
	//Save volumes as csv
	Table.save(dirMain + File.separator + File.getName(dirMain) + "_Volumecsvs" + File.separator + dirname + "_Results" + ".csv");
	//}
	//else{
	//	Table.create("volumes");
	//	Table.setColumn("Volume", final_volumes);
	//	Table.save(dirMain + File.separator + File.getName(dirMain) + "_Volumecsvs" + File.separator + dirname + "_Results" + ".csv");
	//	//saveAs("Results", dirMain + File.separator + File.getName(dirMain) + "_Volumecsvs" + File.separator + "final_volumes" + g + ".csv");
	//}
	
	//If requested, reassign labels of objects sorted by volume
	if(save_volume == true){
	
		final_volumes = Table.getColumn("Volume");
		labels = newArray(number_of_WSrois);
		for (i=0; i<number_of_WSrois; i++){
			labels[i] = i+1;
		}
		
		labels1 = Array.copy(labels);
		
		Array.sort(final_volumes, labels);
	
		Array.sort(labels, labels1);
		
		Table.create("labeltable");
		Table.setColumn("labels", labels1);
		
		call("inra.ijpb.plugins.LabelToValuePlugin.process", "Table=labeltable", "Column=labels", "Min=1", "Max="+number_of_WSrois+"");
		run("Assign Measure to Label");
		run("Image Sequence... ", "format=TIFF name="+substring(name,0,lengthOf(name)-8)+"_ByVolume_"+" digits="+lengthOf(""+number_slices)+" save=["+voldirsegsave+"]");
	}
	
	wlist=getList("window.titles");
	wlength=lengthOf(wlist);
   
	for (i=0; i<wlength; i++) {
   		selectWindow(wlist[i]);
   		run("Close");
	}
	run("Close All");
	run("Clear Results");
	print("\\Clear");
	
	//If not wanting to save labelled images, delete them to save storage
	if (save_labelled == false) {
		list_todelete = getFileList(dirsegsave);
		for(a = 0; a < list_todelete.length; a++){
			File.delete(dirsegsave + list_todelete[a]);
		}
	File.delete(dirsegsave);
	}
}

//If not wanted to save labelled, delete folder created for them
if(save_labelled == false){
	File.delete(dirMain + File.separator + File.getName(dirMain) + "_LabelledStacks");
}


//Close all and end!
run("Close All");
run("Clear Results");
print("\\Clear");
wlist=getList("window.titles");
wlength=lengthOf(wlist);

for (i=0; i<wlength; i++) {
	selectWindow(wlist[i]);
	run("Close");
}

Dialog.create("");
Dialog.addMessage("Finished! Thank you for using AFMSlicer :)");
Dialog.show();