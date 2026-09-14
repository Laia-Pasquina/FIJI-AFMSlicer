run("Close All");
print("\\Clear");

//Set pore colour to white
setColor(255, 255, 255);

//Get required parameters for the simulations
shapes = newArray("Cones", "Oval Cones", "Cylinders", "Oval Cylinders", "Spheres", "Elongated Spheres", "Tip Sin", "Sin", "Internal", "Exponentials", "Logarithmic");
Dialog.create("Required Parameters");
	Dialog.addNumber("Number of Slices", 255);
	Dialog.addChoice("Pore Shape:", shapes, shapes[0]);
	Dialog.addNumber("Number of Pores:", 80);
	Dialog.addString("Name of Stack Folder:", "sim_stacks");
	Dialog.addNumber("Number of Images", 20);
Dialog.show()

slices = Dialog.getNumber();
shape = Dialog.getChoice();
pores = Dialog.getNumber();
name1 = Dialog.getString();
repeats = Dialog.getNumber();

//Create a folder to save in the desired location
dir1 = getDirectory("Where should the stacks be saved?");
dir2 = dir1 + name1 + File.separator;
File.makeDirectory(dir2);

//Repeat for the number of images required
for (k = 0; k < repeats; k++) {
	//Create destination folder
	dir3 = dir2 + "Repeat_" + k + File.separator;
	File.makeDirectory(dir3);
	
	//Set up empty arrays for the various random numbers required
	rand = newArray(pores);
	xcoords = newArray(pores);
	ycoords = newArray(pores);
	width_scale = newArray(pores);
	width_scale2 = newArray(pores);
	phimax = newArray(pores);
	tip = newArray(pores);
	
	//Randomiese the values for each pore
	for (j = 0; j < pores; j++) {
		xcoords[j] = random * 520; //Randomises x location
		ycoords[j] = random * 520; // Randomises y location
		width_scale[j] = 0.4 * random; //Randomises x length
		width_scale2[j] = 0.4 * random; //Randomises y length if oval option chosen
		rand[j] = random * 255; //Randomises the depth of the pore
		phimax[j] = random * PI / 2;
	}
	
	if (shape == "Cones") {
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height and shape
					l = 2 * width_scale[j] * (i - rand[j]);
					x = xcoords[j] - 0.5 * (l - 1);
					y = ycoords[j] - 0.5 * (l - 1);
					fillOval(x, y, l, l);
				}
			}
		}
	}
	
	if (shape == "Oval Cones") {
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height and shape
					l1 = 2 * width_scale[j] * (i - rand[j]);
					l2 = 2 * width_scale2[j] * (i - rand[j]);
					x = xcoords[j] - 0.5 * (l1 - 1);
					y = ycoords[j] - 0.5 * (l2 - 1);
					fillOval(x, y, l1, l2);
				}
			}
		}
	}
	
	if (shape == "Cylinders") {
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height and shape
					l = 1.5 * width_scale[j] * rand[j];
					x = xcoords[j] - 0.5 * (l - 1);
					y = ycoords[j] - 0.5 * (l - 1);
					fillOval(x, y, l, l);
				}
			}
		}
	}
	
	if (shape == "Oval Cylinders") {
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height and shape
					l1 = 1.5 * width_scale[j] * rand[j];
					l2 = 1.5 * width_scale2[j] * rand[j];
					x = xcoords[j] - 0.5 * (l1 - 1);
					y = ycoords[j] - 0.5 * (l2 - 1);
					fillOval(x, y, l1, l2);
				}
			}
		}
	}
	
	if (shape == "Sin") {
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height and shape
					l = 3.5 * rand[j] * sin(phimax[j] * (i - rand[j]) / (slices - rand[j]));
					x = xcoords[j] - 0.5 * (l - 1);
					y = ycoords[j] - 0.5 * (l - 1);
					fillOval(x, y, l, l);
				}
			}
		}
	}
	
	if (shape == "Tip Sin") {
		//WORK IN PROGRESS DO NOT USE
		for (i = slices; i >= 1; i--) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (tip[j] == 0) {
					if (i >= rand[j]) {
						//Randomise size and position and create pore. Size and position scales with height and shape
						l = 3.5 * rand[j] * sin(phimax[j] * (i - rand[j]) / (slices - rand[j]));
						x = xcoords[j] - 0.5 * (l - 1);
						y = ycoords[j] - 0.5 * (l - 1);
						if (l > 13) {
							fillOval(x, y, l, l);
							}
						else {
							tip[j] = i;
						}
					}
				}
				else{
					tipstart = tip[j] - 1;
					tipend = tip[j] - 21;
					R = 6.5;
					z = 1 - ((i - tipend)/21);
					theta = acos(z);
					r = R * sin(theta);
					l = 2*r;
					x = xcoords[j] - 0.5 * (l - 1);
					y = ycoords[j] - 0.5 * (l - 1);
					if (z <= 1) {
						fillOval(x, y, l, l);
					}	
				}
			}
		}
	}
	
	if (shape == "Internal") {
		//WORK IN PROGRESS DO NOT USE
		top = (random * 30) + 135;
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			if (i >= top) {
				fillRect(0, 0, 520, 520);
			}
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height and shape
					l = 1.5 * rand[j] * sin(phimax[j] * (i - rand[j]) / (slices - rand[j]));
					x = xcoords[j] - 0.5 * (l - 1);
					y = ycoords[j] - 0.5 * (l - 1);
					fillOval(x, y, l, l);
				}
			}
		}
	}
	
	if (shape == "Spheres") {
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height and shape
					R = (slices-rand[j]);
					z = 1 - ((i - rand[j]) / (slices - rand[j]));
					theta = acos(z);
					r = R * sin(theta);
					l = 2*r;
					x = xcoords[j] - 0.5 * (l - 1);
					y = ycoords[j] - 0.5 * (l - 1);
					fillOval(x, y, l, l);
				}
			}
		}
	}
	
	if (shape == "Elongated Spheres") {
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height and shape
					R = 0.3 * (slices-rand[j]);
					z = 1 - ((i - rand[j]) / (slices - rand[j]));
					theta = acos(z);
					r = R * sin(theta);
					l = 2*r;
					x = xcoords[j] - 0.5 * (l - 1);
					y = ycoords[j] - 0.5 * (l - 1);
					fillOval(x, y, l, l);
				}
			}
		}
	}
	
	if (shape == "Exponentials") {
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height and shape
					l = 0.5 * width_scale[j] * exp((i - rand[j])*0.03);
					x = xcoords[j] - 0.5 * (l - 1);
					y = ycoords[j] - 0.5 * (l - 1);
					fillOval(x, y, l, l);
				}
			}
		}
	}	
	
	if (shape == "Logarithmic") {
		for (i = 1; i <= slices; i++) {
			//Create the image for this slice
			newImage("Untitled", "8-bit black", 520, 520, 1);
			for (j = 0; j < pores; j++) {
				//Start at random depth
				if (i >= rand[j]) {
					//Randomise size and position and create pore. Size and position scales with height
					l = 100 * width_scale[j] * log(width_scale[j]*(i - rand[j]));
					x = xcoords[j] - 0.5 * (l - 1);
					y = ycoords[j] - 0.5 * (l - 1);
					fillOval(x, y, l, l);
				}
			}
		}
	}
	
	//Convert images to stack
	run("Images to Stack", "name=Stack2 title=[] use");
	
	//Convert from bottom up to top down
	run("Flip Z");
	
	//Save the stack
	run("Image Sequence... ", "format=TIFF name="+name1+" digits=3 save=["+dir3+"]");
}

run("Close All");
