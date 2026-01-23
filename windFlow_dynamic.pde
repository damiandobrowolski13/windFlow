/*////////////

ideas:

- DVD logo celebration on corner hit
- grass effect w/ fixed vectors

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

/*/////////////////////////////////////////////////////////////////////////////
  WIND FLOW DYNAMIC 
  By Damian Vincent Dobrowolski [DVD]
/////////////////////////////////////////////////////////////////////////////*/

float temp, appTemp, windSpeed, windGusts, windDirFrom, windDirTo, relHum, precip, rain, showers, snow, clouds;
String windDirToCard;

PVector[] flowField; 
int cols, rows;
int numParticles = 12000; 
Particle[] particles = new Particle[numParticles];
int scl = 60;  

float incr = 0.1;   
float zOff, zIncr;
float windBias = 0.7; 
float procRot = -90; 
float angleOff;      

int virtualWidth = 1280;
int virtualHeight = 720;
int fetchInterval = 15 * 60 * 1000; 
int lastFetchTime = 0;

PGraphics pg;
DVDlogo dvd;

// Confetti System
ArrayList<Confetti> confettiExplosion = new ArrayList<Confetti>();

// Legend Config
float LEGEND_TEXT_SIZE = 25;
float LEGEND_LINE_HEIGHT_MULTIPLIER = 1.4;
float LEGEND_PADDING = 20;
float LEGEND_SCREEN_MARGIN = 30;         
color LEGEND_BACKGROUND_COLOR = color(0, 220);
color LEGEND_TEXT_COLOR = color(255);
int legendTargetCorner = 0; 

void setup() {
  noCursor();
  fullScreen(P2D);
  pg = createGraphics(virtualWidth, virtualHeight);
  pg.noSmooth();
  dvd = new DVDlogo(pg);
  
  boolean initFetch = fetchWeatherData();
  
  cols = floor((float)virtualWidth / scl) + 1;
  rows = floor((float)virtualHeight / scl) + 1;
  flowField = new PVector[cols * rows];
  for (int i = 0; i < flowField.length; i++) flowField[i] = new PVector();
  
  for (int i = 0; i < numParticles; i++) {
    particles[i] = new Particle();
    particles[i].updateVarsOnFetch(windSpeed);
  }
  
  if (particles.length > 0 && particles[0] != null) dvd.updateSpeed(particles[0].maxSpeed * 0.5);
  
  updateFlowField();
  if (initFetch) printDataSnapshot(); 
  lastFetchTime = millis();
}

void draw() {  
  if (millis() - lastFetchTime >= fetchInterval) {
    if (fetchWeatherData()) printDataSnapshot(); 
    lastFetchTime = millis();
  }
  
  if (frameCount % 5 == 0) updateFlowField();
  
  pg.beginDraw();
    pg.noStroke();
    pg.fill(0, 5); 
    pg.rect(0, 0, virtualWidth, virtualHeight);

    for (Particle p : particles) {
      p.follow(flowField);
      p.update();
      p.edges();
      p.show(pg);
    } 
    
    // Update/Display Confetti inside pg for the trail effect
    for (int i = confettiExplosion.size()-1; i >= 0; i--) {
      Confetti c = confettiExplosion.get(i);
      c.update();
      c.display(pg);
      if (c.isDead()) confettiExplosion.remove(i);
    }

    dvd.update();   
    dvd.display(pg);
  pg.endDraw();

  background(0);
  image(pg, 0, 0, width, height);
  
  drawLegend();
  drawSignature();
}

// Helper to trigger the explosion
void triggerConfetti(float x, float y) {
  for (int i = 0; i < 100; i++) {
    confettiExplosion.add(new Confetti(x, y));
  }
  println("!!! CORNER HIT CELEBRATION !!!");
}

// Confetti Class
class Confetti {
  PVector pos, vel;
  float gravity = 0.05;
  color c;
  float lifespan = 255;

  Confetti(float x, float y) {
    pos = new PVector(x, y);
    vel = PVector.random2D();
    vel.mult(random(2, 5));
    c = color(random(255), random(255), random(255));
  }

  void update() {
    vel.y += gravity;
    pos.add(vel);
    lifespan -= 2.0;
  }

  void display(PGraphics pg) {
    pg.fill(c, lifespan);
    pg.noStroke();
    pg.rect(pos.x, pos.y, 5, 5);
  }

  boolean isDead() { return (lifespan < 0); }
}

// --- LEGEND & SIGNATURE ---

void drawLegend() {
  textSize(LEGEND_TEXT_SIZE);
  float calculatedLineHeight = LEGEND_TEXT_SIZE * LEGEND_LINE_HEIGHT_MULTIPLIER;
  String[] labels = {"Wind speed: ", "Wind gusts: ", "Direction: ", "Temp: ", "Feels: "};
  String[] values = {round(windSpeed)+" mph", round(windGusts)+" mph", windDirToCard+" ("+round(windDirTo)+"º)", round(temp)+" ºF", round(appTemp)+" ºF"};
  
  float maxLineWidth = 0;
  for (int i = 0; i < labels.length; i++) {
    float currentLineWidth = textWidth(labels[i]) + textWidth(values[i]);
    if (currentLineWidth > maxLineWidth) maxLineWidth = currentLineWidth;
  }
  
  float legendBoxW = maxLineWidth + (2 * LEGEND_PADDING);
  float legendBoxH = ((labels.length - 1) * calculatedLineHeight) + LEGEND_TEXT_SIZE + (2 * LEGEND_PADDING);
  
  float lx = 0, ly = 0;
  switch (legendTargetCorner) {
    case 0: lx = width - legendBoxW - LEGEND_SCREEN_MARGIN; ly = LEGEND_SCREEN_MARGIN; break;
    case 1: lx = width - legendBoxW - LEGEND_SCREEN_MARGIN; ly = height - legendBoxH - LEGEND_SCREEN_MARGIN; break;
    case 2: lx = LEGEND_SCREEN_MARGIN; ly = height - legendBoxH - LEGEND_SCREEN_MARGIN; break;
    case 3: lx = LEGEND_SCREEN_MARGIN; ly = LEGEND_SCREEN_MARGIN; break;
  }
  
  fill(LEGEND_BACKGROUND_COLOR);
  noStroke();
  rect(lx, ly, legendBoxW, legendBoxH);
  
  textAlign(LEFT, TOP);
  float drawX = lx + LEGEND_PADDING;
  float drawY = ly + LEGEND_PADDING;
  
  for (int i = 0; i < labels.length; i++) {
    fill(LEGEND_TEXT_COLOR, 160); 
    text(labels[i], drawX, drawY);
    float labelOffset = textWidth(labels[i]);
    fill(LEGEND_TEXT_COLOR); 
    text(values[i], drawX + labelOffset, drawY);
    text(values[i], drawX + labelOffset + 1, drawY); 
    drawY += calculatedLineHeight;
  }
}

void drawSignature() {
  pushMatrix();
    textSize(14);
    textAlign(RIGHT, BOTTOM);
    fill(255, 100); 
    String signature = "by Damian Vincent Dobrowolski [DVD]";
    float sigX = width - 20;
    float sigY = height - 15;
    stroke(255, 50);
    line(sigX - textWidth(signature), sigY - 19, sigX, sigY - 19);
    text(signature, sigX, sigY);
  popMatrix();
}

// --- UTILS & DATA ---

void updateFlowField() {
  float yOff = 0;
  for (int y = 0; y < rows; y++) {
    float xOff = 0;
    for (int x = 0; x < cols; x++) {
      int index = x + y * cols;
      float noiseVal = noise(xOff, yOff, zOff);
      float angle = (noiseVal * TWO_PI + angleOff);
      if (index < flowField.length) flowField[index].set(cos(angle), sin(angle));
      xOff += incr; 
    }
    yOff += incr; 
  }
  zOff += zIncr; 
}

String degreesToCard(float degrees) {
  String[] directions = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"};
  return directions[round(degrees / 45.0f) % 8];
}

void printDataSnapshot() {
  println("--- API Snapshot: " + nf(hour(), 2) + ":" + nf(minute(), 2) + " ---");
}
