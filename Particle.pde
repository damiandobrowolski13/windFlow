class Particle {
  PVector pos, vel, acc;
  float maxSpeed; // init in updateVarsOnFetch()
  int pWeight;
  color pColor = 255;

  Particle() {
    pos = new PVector(random(width), random(height));
    vel = new PVector();
    acc = new PVector();
    //pWeight = int(random(1,7));
    pWeight = 1;
  }

  void follow(PVector[] vectors) {
    int x = constrain(floor(pos.x / scl), 0, cols -1);
    int y = constrain(floor(pos.y / scl), 0, rows - 1);
    int index = x + y * cols;
    
    if (index >= 0 && index < vectors.length) { // Safety check
      PVector force = vectors[index];
      acc.add(force);
    }
  }

  void update() {
    vel.add(acc);
    
    vel.limit(maxSpeed);
    
    pos.add(vel);
    
    acc.mult(0);  // Reset acceleration
  }

  void edges() {
    
    if (pos.x < 0) {
      pos.x += width; // Wrap around from the left
      vel.x += random(-10,10);
      vel.y += random(-10,10);
    }
    if (pos.x >= width){
      pos.x -= width; // Wrap around from the right
      vel.x += random(-10,10);
      vel.y += random(-10,10);
    }
    
    if (pos.y < 0) {
      pos.y += height; // Wrap around from the top
      vel.x += random(-10,10);
      vel.y += random(-10,10);
    }
    if (pos.y >= height) {
      pos.y -= height; // Wrap around from the bottom
      vel.x += random(-10,10);
      vel.y += random(-10,10);
    }
  }

  void show(PGraphics pg) {
    pg.stroke(pColor);
    pg.strokeWeight(pWeight);
    pg.point(pos.x, pos.y);
  }
  
  void updateVarsOnFetch(float curWindSpeed) {
    // This ensures vars are updated when windSpeed changes
    maxSpeed = map(curWindSpeed, 0, 30, 0, 10);
  }
}
