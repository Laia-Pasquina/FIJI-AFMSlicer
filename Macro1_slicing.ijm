/*
 * Convert an AFM image into a stack of binary images
 * 
 * Authors: Dr Laia Pasquina-Lemonche & Matthew Barker, University of Sheffield, UK
 * 
 */

run("Close All");

//Retrieve required parameters for the processing
Dialog.create("");
Dialog.addMessage("Welcome to AFMSlicer!");
Dialog.addDirectory("Select folder containing images", "");
Dialog.addNumber("Number of slices to make from the image (>256 requires 16-bit image)", 256);
Dialog.addChoice("Represent Pores or Surface? (Pores required for Code 2, Surface for Code 3)", newArray("Pores", "Surface"));
Dialog.addCheckbox("Are all images square?", false);
Dialog.addCheckbox("Save filtered? (Required for code 3)", true);
Dialog.addCheckbox("Save .obj wavefront?", false);
Dialog.addMessage("Saving .obj wavefront requires selection of .txt files containing depths and xy dimensions in nm");

Dialog.show();

dir1 = Dialog.getString();
number_slices = Dialog.getNumber();
represent = Dialog.getChoice();
square = Dialog.getCheckbox();
SaveFiltered = Dialog.getCheckbox();
D3 = Dialog.getCheckbox();

list = getFileList(dir1);
dir2 = dir1 + File.getName(dir1) + "_Stacks" + File.separator;
File.makeDirectory(dir2);

if (D3 == true){
	//If saving 3D .obj is selected, create folder to save them in
	dir3 = dir1 + File.getName(dir1) + "_objs" + File.separator;
	File.makeDirectory(dir3);
	
	Dialog.create("");
	Dialog.addFile("Select .txt file containing depths in nm", "");
	if (square == true){
		Dialog.addFile("Select .txt file containing xy size in nm", "");
	}
	if (square == false){
		Dialog.addFile("Select .txt file containing x size in nm", "");
		Dialog.addFile("Select .txt file containing y size in nm", "");
	}
	Dialog.show();
	
	depthtxt = Dialog.getString();
	xtxt = Dialog.getString();
	if (square == false){
		ytxt = Dialog.getString;
	}
	
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
	x=newArray(rows1.length);
	for(i=0; i<rows1.length; i++){
		x[i]=parseFloat(rows1[i]);
	}
	
	if(square == false){
		//Select .txt file of image y (nm) and extract values into an array
		filestring2=File.openAsString(ytxt);
		rows2=split(filestring2, "\n");
		y=newArray(rows2.length);
		for(i=0; i<rows2.length; i++){
			y[i]=parseFloat(rows2[i]);
		}
	}
	else{
		y=x;
	}
}

//Create save diretory for filtered images
dirFilt = dir1 + File.getName(dir1) + "_Filtered" + File.separator;
File.makeDirectory(dirFilt);

//Hide most processes
setBatchMode(true);

for (j=0; j<list.length; j++) {
	run("Close All");
	
	//Open image from the list
	open(dir1 + list[j]);

	//File name in form image.tif
	name0 = File.name;
	//File name in form image_filtered
	name1 = File.nameWithoutExtension +"_filtered";
	//File name in form image
	name2 = File.nameWithoutExtension;
	//File name in form image_
	name3 = File.nameWithoutExtension + "_";
	
	//set default to 16-bit
	zdepth = 65535;
	
	//If needed, convert from RGB to greyscale
	if(bitDepth() == 24) {
		//Change to 8-bit
		zdepth = 255;
		
		//Split channels into RGB
		run("Split Channels");
		
		//find the titles of all images, and then close green and blue
		titles = newArray(nImages());
		
		for(i=1; i<=nImages(); i++) {
			//Get the titles from the images
			selectImage(i);
			titles[i-1] = getTitle();
			NaM = titles[i-1];
			
			//Find Blue channel and close it
			A = endsWith(NaM, "blue)");
			if(A == 0) {
				run("Close");
			}
			
			//Find green channel and close it
			B = endsWith(NaM, "green)");
			if(B == "0") {
				run("Close");
			}
		}
	}
	
	//Filter image and save
	run("Despeckle");
	//run("Remove Outliers...", "radius=10 threshold=50 which=Bright");
	run("Median...", "radius=2");
	saveAs("tiff", dirFilt+name1);
	
	run("Close All");
	
	for(i = 0; i < number_slices; i++) {
			print("\\Clear");
			print("Image #" + j+1 + ", " + parseInt(i/number_slices*100) + "% complete");
			//Open greyscale image
			open(dirFilt + name1 + ".tif");
			
			//Threshold image
			setAutoThreshold("Otsu");
			
			//Reverse threshold depending on requirements
			if (represent == "Pores") {
				a = 0;
				b = zdepth - round((i/number_slices)*zdepth);
			}
			if (represent == "Surface") {
				a = round((i/number_slices)*zdepth);
				b = zdepth;
			}
			
			setThreshold(a, b);
	
			setOption("BlackBackground", true);
	
			run("Convert to Mask");
		
		}
	
	//Stack images
	name4 = name2+"_stack";
	run("Images to Stack", "title=[] use");
	
	//Flip the stack to be top-down
	if (represent == "surface"){
		run("Reverse");
	}
	
	//Save the stack as Image Sequence for further analysis. Saves in a folder named Filename_stack in stacks folder
	savepoint = dir2 + name2 + "_stack";
	File.makeDirectory(savepoint);
	run("Image Sequence... ", "format=TIFF name="+name3+" digits="+lengthOf(""+number_slices)+" save=["+savepoint+"]");
	

	
	if (D3 == true){
		//Save .obj files if requested
		print("\\Clear");
		print("Saving .obj for Image #"+j+1);
		save2 = dir3 + name2 + "_3D" + ".obj";
		selectWindow("Stack");
		getDimensions(width, height, channels, slices, frames);
		run("Properties...", "channels=1 slices="+number_slices+" frames=1 pixel_width="+x[j]/width+" pixel_height="+y[j]/height+" voxel_depth="+depths[j]/number_slices+"");
		run("Wavefront .OBJ ...", "stack=Stack threshold=50 resampling=2 red green blue save=["+save2+"]");
	}
}
	
if (SaveFiltered == false) {
	//Delete filtered image (and folder) if not needed
	listFilt = getFileList(dirFilt);
	for(a = 0; a < listFilt.length; a++){
		File.delete(dirFilt + listFilt[a]);
	}
	File.delete(dirFilt);
}

//Close everything
print("\\Clear");
run("Close All");
wlist=getList("window.titles");
wlength=lengthOf(wlist);
for (i=0; i<wlength; i++) {
	selectWindow(wlist[i]);
	run("Close");
}

//Final dialogue
Dialog.create("");
Dialog.addMessage("Finished! Thank you for using AFMSlicer :)");
Dialog.show();