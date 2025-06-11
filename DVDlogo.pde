class DVDlogo {

  PVector pos;         // Position vector
  PVector vel;         // Velocity vector

  String logoText = "DVD";
  float logoSize = 50; // The font size of the logo
  float w, h;          // The width and height of the text for collision

  color currentTint;   // The current color of the logo

  DVDlogo(PGraphics pg) {
    // Start the logo in the center of the VIRTUAL canvas
    pos = new PVector(virtualWidth / 2, virtualHeight / 2);

    // Give it a random starting direction and speed
    vel = PVector.random2D(); // A random direction vector of length 1

    // Measure the text using the PGraphics context it will be drawn on
    pg.beginDraw();
    pg.textSize(logoSize);
    w = pg.textWidth(logoText);
    h = pg.textAscent(); // textAscent is more accurate for vertical collision
    pg.endDraw();

    // Pick a random starting color
    changeColor();
  }

  // update() - moves the logo and checks for bounces
  void update() {
    pos.add(vel); // Move the logo
    checkBounce();
  }

  // checkBounce() - inverts velocity when an edge is hit
  void checkBounce() {
    // Check for collision with left or right wall
    if (pos.x <= 0 || pos.x + w >= virtualWidth) {
      vel.x *= -1; // Invert horizontal velocity
      changeColor();
    }
    // Check for collision with top or bottom wall
    if (pos.y - h <= 0 || pos.y >= virtualHeight) {
      vel.y *= -1; // Invert vertical velocity
      changeColor();
    }
  }

  // display() - draws the logo on the screen
  void display(PGraphics pg) {
    pg.fill(currentTint);
    pg.textSize(logoSize);
    pg.textAlign(LEFT, TOP); // Align from the top-left for easier calculations
    // We draw at pos.y - h because the text's origin is its baseline
    pg.text(logoText, pos.x, pos.y - h);
  }

  // changeColor() - picks a new random color
  void changeColor() {
    currentTint = color(random(0, 255), random(0, 255), random(0, 255));
  }
  
   void updateSpeed(float newSpeed) {
    // change the vector's magnitude
    // without changing its direction.
  
    // First, normalize the vector
    vel.normalize();
  
    // Then, scale it by the new speed
    // Add a minimum speed to ensure it never stops completely
    vel.mult(max(0.5, newSpeed)); // Use max() to prevent speed from being 0
  }
}
