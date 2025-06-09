boolean fetchWeatherData() {
  String url = "https://api.open-meteo.com/v1/forecast?latitude=42.051438&longitude=-87.674683&current=temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,rain,showers,snowfall,cloud_cover&timezone=America%2FChicago&wind_speed_unit=mph&temperature_unit=fahrenheit&precipitation_unit=inch";
  JSONObject weatherData = loadJSONObject(url);
  
  if (weatherData != null){
    JSONObject currentWeather = weatherData.getJSONObject("current");
    
    //current (15-minutely) wind variables
    temp = currentWeather.getFloat("temperature_2m");
    appTemp = currentWeather.getFloat("apparent_temperature");
    windSpeed = currentWeather.getFloat("wind_speed_10m");
    windGusts = currentWeather.getFloat("wind_gusts_10m");
    windDirFrom = currentWeather.getFloat("wind_direction_10m");
    windDirTo = (windDirFrom + 180) % 360;
    windDirToCard = degreesToCard(windDirTo);
    // Determine legend's target corner based on windDirTo (degrees)
    if (windDirTo >= 0 && windDirTo < 90) {         // Wind blowing towards NE quadrant
      legendTargetCorner = 2; // Bottom-Left 
    } else if (windDirTo >= 90 && windDirTo < 180) { // Wind blowing towards SE quadrant
      legendTargetCorner = 3; // Top-Left
    } else if (windDirTo >= 180 && windDirTo < 270) { // Wind blowing towards SW quadrant
      legendTargetCorner = 0; // Top-Right
    } else { // windDirTo >= 270 && windDirTo < 360   // Wind blowing towards NW quadrant
      legendTargetCorner = 1; // Bottom-Right
    }
    
    relHum = currentWeather.getFloat("relative_humidity_2m");
    precip = currentWeather.getFloat("precipitation");
    rain = currentWeather.getFloat("rain");
    showers = currentWeather.getFloat("showers");
    snow = currentWeather.getFloat("snowfall");
    clouds = currentWeather.getFloat("cloud_cover");
    
    //println("Temperature: " + temp + " ºF");
    //println("Feels like: " + appTemp + " ºF");
    //println("Wind speed: " + windSpeed + " mph");
    //println("Wind gusts: " + windGusts + " mph");
    //println("Wind direction from: " + windDirFrom + "º");
    //println("Wind direction to: " + windDirTo + "º");
    //println("Relative humidity: " + relHum + "%");
    //println("precip: " + precip + " in.");
    //println("rain: " + rain + " in.");
    //println("showers: " + showers + " in.");
    //println("snow: " + snow + " in.");
    //println("clouds: " + clouds + "% \n");
    
    // Recalculate sketch parameters that depend on weather data
    angleOff = radians(windDirTo + procRot); // angle to offset noise is windDirTo shifted by the regular orientation of the program
    zIncr = map(windGusts - windSpeed, 0, 30, 0.0001, 0.1); // Making speed of time progression proportional to prop of wind gusts - wind speed data from API
    zIncr = max(0.00001f, zIncr); // Ensure zIncr remains positive

    // Update properties for all particles
    if (particles != null) { // check array itself, though it's init globally
        for (Particle p : particles) {
            if (p != null) { // null check
                p.updateVarsOnFetch(windSpeed);
            }
        }
    }
    return true;
  } else {
    println("Error fetching weather data.");
    return false;
  }
}
