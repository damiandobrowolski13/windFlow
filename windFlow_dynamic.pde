/*////////////

ideas:

- temp gradient
  - based on diff btw actual temp & feels like
- field vectors sway to maintain dynamism
  - sway incr as diff btw gust (max speed) and speed (avg) incr
- alpha (trails) based on air quality / overcastness
- wind strength controlling wind bias too
- API error-handling to use default settings for display
  - can just show flow line display or constantly changing vars
- color change based on time of day
  
/*////////////

//windData vars
float temp, appTemp, windSpeed, windGusts, windDirFrom, windDirTo, relHum, precip, rain, showers, snow, clouds;
String windDirToCard;

//windFlow vars
PVector[] flowField; // Array to store flow vectors
//ArrayList<Particle> particles = new ArrayList<Particle>();
int cols, rows;
////////////////////////// BIG EFFECT ON PERFORMANCE
int numParticles = 12000;
//////////////////////////
Particle[] particles = new Particle[numParticles];
color bgColor = 0;
int bgAlpha = 10; // transparency to make trails 
color vColor = 255;
int vWeight = 2;
int scl = 60;  // Scale: size of each grid cell

// movement vars
float incr = 0.1;  // Noise step
float zOff;  // Time offset
float zIncr;  // Speed of time progression
float windBias = 0.7; // controls how much windDir vs. noiseAngle (0 is no wind influence, 1 is max)

// screen adj
float procRot = -90; // processing's degree orientation (unit circle)
float angleOff; // variable to add to angle to send flow field vectors in dir of wind

// upscaling vars
int virtualWidth = 1280;
int virtualHeight = 720;

// timer vars
int fetchInterval = 15 * 60 * 1000;  // 15 minutes in ms
int lastFetchTime = 0;
int frameRateCheckInterval = 2000;  // 2000ms = 2 seconds
int lastFrameRateCheckTime = 0;     // Stores the time of the last check

PGraphics pg;

// --- Legend Configuration Variables ---
float LEGEND_TEXT_SIZE = 25;
float LEGEND_LINE_HEIGHT_MULTIPLIER = 1.4;
float LEGEND_PADDING = 20;
float LEGEND_SCREEN_MARGIN = 30;        
color LEGEND_BACKGROUND_COLOR = color(0, 220);
color LEGEND_TEXT_COLOR = color(255);
int legendTargetCorner = 0; // 0: Top-Right, 1: Bottom-Right, 2: Bottom-Left, 3: Top-Left (Default to Top-Right)
// ------------------------------------

void setup() {
  //size(800, 800, P2D);  // optimize w/ OpenGL render for 2D
  fullScreen(P2D); // run fullscreen w/ OpenGL render for 2D
  pg = createGraphics(virtualWidth, virtualHeight);
  pg.noSmooth();
  
  // Initial data fetch
  boolean initFetch = fetchWeatherData();
  
  cols = floor((float)virtualWidth / scl) + 1;  // Ensure grid covers canvas
  rows = floor((float)virtualHeight / scl) + 1;
  flowField = new PVector[cols * rows];
  // Initialize PVector objects once
  for (int i = 0; i < flowField.length; i++) {
      flowField[i] = new PVector();
  }
  
  // Create particles
  for (int i = 0; i < numParticles; i++) {
    particles[i] = new Particle();
    particles[i].updateVarsOnFetch(windSpeed);
  }
  
  updateFlowField();
  
  // Print the snapshot if the initial fetch was successful
  if (initFetch) {
    printDataSnapshot(); 
  }
  
  noSmooth();
  
  lastFetchTime = millis(); // init timer for subsequent fetches
}

void draw() {  
  // --- Check and Print Frame Rate Periodically ---
  if (millis() - lastFrameRateCheckTime > frameRateCheckInterval) {
    // nf() function formats the float to show 2 decimal places, which looks cleaner
    println("Frame Rate: " + nf(frameRate, 0, 2));
    
    // Reset the timer to the current time
    lastFrameRateCheckTime = millis(); 
  }
  
  // fetching api data
  if (millis() - lastFetchTime >= fetchInterval) {
    boolean fetchGood = fetchWeatherData(); // Call and get status
    lastFetchTime = millis(); // Update the fetch time regardless of success to maintain interval

    if (fetchGood) {
      printDataSnapshot(); // Call helper function
    }
  }
  
  int updateFlowFieldInterval = 5; // Update every 5 frames, adjust as needed
  if (frameCount % updateFlowFieldInterval == 0) {
    updateFlowField();
  }
  
  // fade effect: draw a semi-transparent black rect over previous frame
  pg.beginDraw();
  pg.noStroke();
  pg.fill(0, 5);  // lower = slower fading
  pg.rect(0, 0, virtualWidth, virtualHeight);

   //// Update and display particles
  for (Particle p : particles) {
    p.follow(flowField);
    p.update();
    p.edges();
    p.show(pg);
  } 
  pg.endDraw();

  // clear main fullscreen window
  background(0);

  // now draw pg onto the actual screen
  image(pg, 0, 0, width, height);
  
  
  // --- BEGIN CORNER DATA LEGEND ---
  
  // 1. Set text properties for measurement and drawing
  textSize(LEGEND_TEXT_SIZE);
  // calculatedLineHeight is the distance from the top of one line of text to the top of the next
  float calculatedLineHeight = LEGEND_TEXT_SIZE * LEGEND_LINE_HEIGHT_MULTIPLIER;
  
  // 2. Prepare text content for the legend
  String line1 = "Wind speed: " + nf(windSpeed, 0, 1) + " mph";
  String line2 = "Wind gusts: " + nf(windGusts, 0, 1) + " mph";
  String line3 = "Wind direction (to): " + windDirToCard + " (" + nf(windDirTo, 0, 0) + "º" + ")";
  String line4 = "Temperature: " + nf(temp, 0, 0) + " ºF";
  String line5 = "Feels like: " + nf(appTemp, 0, 0) + " ºF";
  
  String[] legendLines = {line1, line2, line3, line4, line5};
  int numLines = legendLines.length;
  
  // 3. Determine Legend Box Dimensions (legendBoxW and legendBoxH)
  float maxTextWidth = 0;
  if (numLines > 0) {
    for (String line : legendLines) {
      maxTextWidth = max(maxTextWidth, textWidth(line));
    }
  }
  
  float legendBoxW = maxTextWidth + (2 * LEGEND_PADDING); // <<< legendBoxW is declared and calculated HERE
  
  float textBlockContentHeight = 0;
  if (numLines > 0) {
    textBlockContentHeight = (numLines - 1) * calculatedLineHeight + LEGEND_TEXT_SIZE;
  }
  float legendBoxH = textBlockContentHeight + (2 * LEGEND_PADDING); // <<< legendBoxH is declared and calculated HERE
  
  if (numLines == 0) { // If there are no lines, just make a small padded box
    legendBoxH = 2 * LEGEND_PADDING;
    legendBoxW = 2 * LEGEND_PADDING; // Ensure legendBoxW is also set for empty case
  }
  
  // 4. Determine Legend Box Position BASED ON legendTargetCorner
  //    Now legendBoxW and legendBoxH are available for these calculations.
  float currentLegendBoxX = 0;
  float currentLegendBoxY = 0;
  
  switch (legendTargetCorner) {
    case 0: // Top-Right
      currentLegendBoxX = width - legendBoxW - LEGEND_SCREEN_MARGIN;
      currentLegendBoxY = LEGEND_SCREEN_MARGIN;
      break;
    case 1: // Bottom-Right
      currentLegendBoxX = width - legendBoxW - LEGEND_SCREEN_MARGIN;
      currentLegendBoxY = height - legendBoxH - LEGEND_SCREEN_MARGIN;
      break;
    case 2: // Bottom-Left
      currentLegendBoxX = LEGEND_SCREEN_MARGIN;
      currentLegendBoxY = height - legendBoxH - LEGEND_SCREEN_MARGIN;
      break;
    case 3: // Top-Left
      currentLegendBoxX = LEGEND_SCREEN_MARGIN;
      currentLegendBoxY = LEGEND_SCREEN_MARGIN;
      break;
    default: // Fallback to Top-Right
      currentLegendBoxX = width - legendBoxW - LEGEND_SCREEN_MARGIN;
      currentLegendBoxY = LEGEND_SCREEN_MARGIN;
      break;
  }
  
  // --- Draw Legend ---
  // Draw the background rectangle for the legend
  fill(LEGEND_BACKGROUND_COLOR);
  noStroke();
  rect(currentLegendBoxX, currentLegendBoxY, legendBoxW, legendBoxH); // Uses legendBoxW and legendBoxH
  
  // Draw the text
  if (numLines > 0) {
    textSize(LEGEND_TEXT_SIZE); // This needs to be set before textWidth is called and before text is drawn
    fill(LEGEND_TEXT_COLOR);
    textAlign(LEFT, TOP);
  
    float textX = currentLegendBoxX + LEGEND_PADDING;
    float textCurrentY = currentLegendBoxY + LEGEND_PADDING;
  
    for (int i = 0; i < numLines; i++) {
      text(legendLines[i], textX, textCurrentY);
      textCurrentY += calculatedLineHeight;
    }
  }
  // --- END CORNER DATA LEGEND ---
}

void updateFlowField() {
  float yOff = 0;
  for (int y = 0; y < rows; y++) {
    float xOff = 0;
    for (int x = 0; x < cols; x++) {
      int index = x + y * cols;
      float noiseVal = noise(xOff, yOff, zOff);
      float angle = (noiseVal * TWO_PI + angleOff); // Maintain original angle logic

      // Update existing PVector instead of creating a new one
      float vecX = cos(angle);
      float vecY = sin(angle);
      if (index < flowField.length) { // Safety check, should always be true with correct cols/rows
          flowField[index].set(vecX, vecY);
      }

      xOff += incr;  // incr noise in x dir 
    }
    yOff += incr;  // incr noise in y dir 
  }
  zOff += zIncr;  // incr time offset to dynamicize 
}

// convert degrees to cardinal dir
String degreesToCard(float degrees) {
  String[] directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"};

  // Calculate the index for the directions array
  // Each direction covers 45 degrees. We round to the nearest 45-degree mark.
  int index = round(degrees / 45.0f);

  // Handle the wrap-around case for North (index 8 becomes 0)
  index = index % 8;

  return directions[index];
}

void printDataSnapshot() {
  println("--------------------------------------------------"); // Separator for clarity
  println("️  Weather Data & Sketch Vars Snapshot at: " + nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2));
  println("--------------------------------------------------");

  // --- Core API Data ---
  println("Core API Data:");
  println("  Temperature:         " + nf(temp, 0, 1) + " ºF");
  println("  Feels like:          " + nf(appTemp, 0, 1) + " ºF");
  println("  Wind Speed:          " + nf(windSpeed, 0, 1) + " mph");
  println("  Wind Gusts:          " + nf(windGusts, 0, 1) + " mph");
  println("  Wind Direction From: " + nf(windDirFrom, 0, 0) + "º");
  println("  Wind Direction To:   " + nf(windDirTo, 0, 0) + "º (" + windDirToCard + ")"); // Includes your cardinal conversion
  println("  Relative Humidity:   " + nf(relHum, 0, 0) + "%");
  println("  Cloud Cover:         " + nf(clouds, 0, 0) + "%");

  // Optionally print precipitation data if it's relevant and often non-zero
  if (precip > 0 || rain > 0 || showers > 0 || snow > 0) {
    println("  Precipitation Details:");
    if (precip > 0) println("    Total Precip: " + nf(precip, 0, 2) + " in.");
    if (rain > 0) println("    Rain:         " + nf(rain, 0, 2) + " in.");
    if (showers > 0) println("    Showers:      " + nf(showers, 0, 2) + " in.");
    if (snow > 0) println("    Snow:         " + nf(snow, 0, 2) + " in.");
  }
  println("---");

  // --- Derived Sketch Variables & Performance ---
  println("Derived Sketch Variables & Performance:");
  println("  Frame Rate (at time of fetch): " + nf(frameRate, 0, 2) + " FPS"); 
  println("  Flow Field Angle Offset: " + nf(degrees(angleOff), 0, 1) + "º"); // Convert radians back to degrees for printing
  println("  Flow Field Z Increment:  " + nf(zIncr, 0, 5));     // Animation speed of flow field
  println("  Legend Target Corner:    " + legendTargetCornerToString(legendTargetCorner)); // Readable corner

  if (particles != null && particles.length > 0 && particles[0] != null) {
    println("  Particle Max Speed (Sample): " + nf(particles[0].maxSpeed, 0, 2));
  } else {
    println("  Particle Max Speed (Sample): N/A (particles not initialized)");
  }
  println("--------------------------------------------------\n"); // Extra newline for spacing
}

// Helper function to make legendTargetCorner more readable in console
String legendTargetCornerToString(int cornerCode) {
  switch (cornerCode) {
    case 0: return "Top-Right";
    case 1: return "Bottom-Right";
    case 2: return "Bottom-Left";
    case 3: return "Top-Left";
    default: return "Unknown (" + cornerCode + ")";
  }
}
