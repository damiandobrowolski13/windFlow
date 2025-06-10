# Sketch Overview

This Processing sketch visualizes real-time wind and weather data by biasing a Perlin-noise–driven particle flow field with live wind information. Here’s a breakdown of its main components:

---

## 1. Weather-Data Fetch & Storage
- Every **15 minutes** it calls `fetchWeatherData()`.
- Populates globals:  
  - `temp`, `appTemp`  
  - `windSpeed`, `windGusts`  
  - `windDirFrom`, `windDirTo`, `windDirToCard`  
  - `relHum`, `clouds`, `precip`, `rain`, `showers`, `snow`
- Converts wind degrees → cardinal with `degreesToCard()`.
- On each successful fetch, prints a detailed snapshot via `printDataSnapshot()`.

---

## 2. Flow Field Generation
- Divides the canvas into a grid of `cols × rows` cells, each of size `scl`.
- Samples 3D Perlin noise (`xOff`, `yOff`, `zOff`) to compute an angle at each grid cell.
- Applies a wind bias (`angleOff`) so vectors “blow” in the real wind direction.
- Stores each normalized direction in a `PVector[] flowField`.

---

## 3. Particle System
- Spawns `numParticles` (10 000 by default), each:
  1. **Follows** the local flow field vector.  
  2. **Updates** its position & velocity (`maxSpeed`).  
  3. **Handles edges** (`edges()`).  
  4. **Draws** itself on an off-screen buffer (`PGraphics pg`).

---

## 4. Rendering & Animation
- In `draw()`, every frame:
  1. **Fade** old trails by drawing a semi-transparent black rect (`pg.fill(0, 5)`).
  2. **Update** & **show** all particles.
  3. **Blit** `pg` onto the screen for smooth motion-blur.
- Recomputes the flow field every few frames (`frameCount % updateFlowFieldInterval == 0`), creating a dynamic undulation.

---

## 5. On-Screen Legend
- Renders a legend box in one corner (`legendTargetCorner`).
- Displays:
  - **Wind speed** & **gusts**  
  - **Wind direction** (degrees + cardinal)  
  - **Temperature**
- Dynamically sizes the box to fit the text, with configurable padding, font size, and corner placement.

---

**Result:** an ever-shifting “wind map” with fading particle
