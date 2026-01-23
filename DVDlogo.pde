class DVDlogo {
  PVector pos;
  PVector vel;
  String logoText = "DVD";
  float logoSize = 50;
  float w, h;
  color currentTint;

  DVDlogo(PGraphics pg) {
    pos = new PVector(virtualWidth / 2, virtualHeight / 2);
    vel = PVector.random2D();
    pg.beginDraw();
    pg.textSize(logoSize);
    w = pg.textWidth(logoText);
    h = pg.textAscent();
    pg.endDraw();
    changeColor();
  }

  void update() {
    pos.add(vel);
    checkBounce();
  }

  void checkBounce() {
    float margin = 10.0; // 10-pixel leniency
    boolean hitX = false;
    boolean hitY = false;

    // Check X
    if (pos.x <= 0 || pos.x + w >= virtualWidth) {
      vel.x *= -1;
      hitX = true;
      changeColor();
    }
    // Check Y
    if (pos.y - h <= 0 || pos.y >= virtualHeight) {
      vel.y *= -1;
      hitY = true;
      changeColor();
    }

    // CELEBRATION with a tiny bit of forgiveness
    // If it hit one axis and is within 'margin' pixels of the other
    if (hitX && (pos.y - h <= margin || pos.y >= virtualHeight - margin)) {
       triggerConfetti(pos.x + w/2, pos.y - h/2);
    } else if (hitY && (pos.x <= margin || pos.x + w >= virtualWidth - margin)) {
       triggerConfetti(pos.x + w/2, pos.y - h/2);
    }
  }

  void display(PGraphics pg) {
    pg.fill(currentTint);
    pg.textSize(logoSize);
    pg.textAlign(LEFT, TOP);
    pg.text(logoText, pos.x, pos.y - h);
  }

  void changeColor() {
    currentTint = color(random(100, 255), random(100, 255), random(100, 255));
  }

  void updateSpeed(float newSpeed) {
    vel.normalize();
    vel.mult(max(0.5, newSpeed));
  }
}
