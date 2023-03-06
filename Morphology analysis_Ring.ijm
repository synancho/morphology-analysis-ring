//Measure the diameter of protein clusters in a ring shape
//Last updated on 2022-08-03
//Contact SoYeon Kim for question: soyeon.kim@ucsf.edu

//Number of lines to measure
numLine = 6;
dAngle = 180/numLine;
lineLength = 20;

//Choose folder for output images and excel files
waitForUser("Select or create destination directory for output images and data!");
outDir=getDirectory("Select or create destination directory for output images and data");

//Initial variable
run("Set Measurements...", "area mean centroid display redirect=None decimal=3");
imgName = getTitle();
getPixelSize(unit, pw, ph, pd);
pixelSize = 1/pw;
print("Pixel number per micron = " + pixelSize);

i = 1;

//Clear the previous works
run("Enhance Contrast", "saturated=0.35");
run("Clear Results");
run("Select All");
roiManager("Add");
roiManager("Delete");
stat = true;

while (stat==true) {
	measureCluster(imgName);
	i = i + 1;
	
	selectWindow("Results");
	roiManager("Save", outDir + "/" + imgName + ".roi");
	saveAs("Results", outDir + "/" + imgName + ".csv");
	Dialog.create("Protein cluster diameter measurement!");
	Dialog.addMessage("Wnat to measure another cluster? Click cancel if the measurement is done for the image!");
	Dialog.show();			
}

function measureCluster(imgName) {
	//Thresholding the image for cluster detection
	data = "Cluster" + i;
	startRow = (i-1)*(2 + numLine);
	run("Duplicate...", "title=" + data);
	run("Duplicate...", "title=Copy");
	
	selectWindow(data);
	setAutoThreshold("Otsu dark");
	setTool("wand");
	waitForUser("Choose the cluster!");
	roiManager("Add");
	
	//Sava the image showing the selection
	selectWindow("Copy");
	run("Restore Selection");
	run("Draw", "slice");
	run("RGB Color");
	saveAs("PNG", outDir + "/" + data + ".png");
	close();
	
	selectWindow(data);
	
	run("Measure");
	cluster_centerX = getResult("X",startRow);
	cluster_centerY = getResult("Y",startRow);
	
	//Detect the center part of the cluster
	setAutoThreshold("Triangle");
	roiManager("Show None");
	doWand(cluster_centerX*pixelSize, cluster_centerY*pixelSize);
	waitForUser("Confirm the center part of the cluster!");
	run("Measure");
	
	//Get the centroid coordinates of the cluster
	centerX = getResult("X",startRow + 1);
	centerY = getResult("Y",startRow + 1);
	
	//Make a line based on the centroid position (centroid positions are in micron unit so converted to pixel unit)
	lineStartX = centerX*pixelSize - lineLength;
	lineEndX = centerX*pixelSize + lineLength;
	lineStartY = centerY*pixelSize;
	lineEndY = centerY*pixelSize;
	makeLine(lineStartX, lineStartY, lineEndX, lineEndY);
	
	//Looping through all the angles 
	for (j = 0; j < numLine; j++) {
		angle = j*dAngle;
		lineInt = getProfile();
		run("Plot Profile");
		
		//Utilized 'Find Peaks' tool (https://imagej.net/plugins/find-peaks)
		run("Find Peaks", "min._peak_amplitude=5 min._peak_distance=0 min._value=[] max._value=[] exclude list");
		
		//Get the peak positions and calculate the distance (absolute value)
		peakX1 = Table.get("X1",0);
		peakX2 = Table.get("X1",1);
		peakX3 = Table.get("X1",2);
		print(peakX3);
		print(isNaN(peakX3));
		if(isNaN(peakX2) == 1) {
			setResult("Number of peaks", startRow + j + 2, 1);
			waitForUser("Check the data - just one peak!");
		}
		else {
			if(isNaN(peakX3) == 0) {
				setResult("Number of peaks", startRow + j + 2, 3);
				waitForUser("Check the plot Profile - more than 2 peaks!");
			}
			else {
				setResult("Number of peaks", startRow + j + 2, 2);				
			}
		}
		
		peakDist = abs(peakX2 - peakX1);
		setResult("Angle", startRow + j + 2, angle);
		setResult("Peak distance", startRow + j + 2, peakDist);
		updateResults();
		
		//Older version of script reporting all the plot values
		/*Plot.getValues(x,y);
		startRow = i*x.length + 1;
		for (j=0; j<x.length; j++) {
			setResult("Angle", startRow+j, angle);
			setResult("Position", startRow+j, x[j]);
			setResult("Intensity", startRow+j, y[j]);
			updateResults();
		}	
		*/
		
		selectWindow(data);
		run("Rotate...", "  angle="+dAngle);
		//waitForUser("test");
	}
	
	//Show the cluster processed
	selectWindow(imgName);
	roiManager("Show All");
	close("\\Others");
	

}
