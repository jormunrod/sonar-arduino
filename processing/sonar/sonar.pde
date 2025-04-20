/* CONFIGURABLE VARIABLES */
final int MAX_DISTANCE = 70;         // Maximum distance in cm (adjustable for the radar)
final float IMAGE_SCALE = 0.;         // Fraction of screen width for the logo on the left, temporally disabled
final float FAIR_IMAGE_SCALE = 0.27;    // Fraction of screen width for the fair image on the right (increased)
final int SERIAL_BAUD = 9600;
final String[] PORT_PATTERNS = {"ttyUSB", "ttyACM"};
final int RADAR_STROKE_WEIGHT = 2;
final int LINE_STROKE_WEIGHT = 9;
final int TEXT_SIZE_SMALL = 25;
final int TEXT_SIZE_LARGE = 40;

// Thresholds for simulating LED states (similar to Arduino)
final int SAFE_DISTANCE = 70;
final int WARNING_DISTANCE = 10;

// Colors for radar elements
color RADAR_COLOR = color(98, 245, 31);
color LINE_COLOR = color(30, 250, 60);
color OBJECT_COLOR = color(255, 10, 10);
color TEXT_COLOR = RADAR_COLOR;

// New GitHub repository URL
final String GITHUB_URL = "https://github.com/jormunrod/sonar-arduino";

// Application version and last update date
final String APP_VERSION = "SONAR v1.0";
final String APP_LAST_UPDATE = "20/04/2025";

import processing.serial.*;
import java.awt.Desktop;
import java.net.URI;
import java.io.IOException;
import java.awt.event.KeyEvent;

Serial myPort;
PImage schoolLogo;    // Image for the top-left corner (project logo)
PImage fairImage;     // Image for the top-right corner (fair image)
PImage githubLogo;    // Logo for the GitHub link

// Global sensor data variables
int sensorAngle = 0;
int sensorDistance = 0;

// Global variable to toggle the menu
boolean showMenu = true;

// Global variable to store the connected Arduino port
String arduinoPort = "";

void setup() {
  // Adapt window to 1920x1080 and make it resizable
  size(1920, 1080);
  surface.setTitle(APP_VERSION);
  surface.setResizable(true);
  smooth();
  
  // Load images from the "data" folder
  schoolLogo = loadImage("ies.jpeg");
  fairImage  = loadImage("logo_white.png");
  githubLogo = loadImage("github.png");
  
  if (schoolLogo == null)  println("Could not load 'ies.jpeg'");
  if (fairImage == null)   println("Could not load 'logo_white.png'");
  if (githubLogo == null)  println("Could not load 'github.png'");
  
  // Setup the serial port
  setupSerialPort();
}

void draw() {
  if (showMenu) {
    updateSerialConnection(); // <-- added to update Arduino connection live
    drawMenu();
  } else {
    // Draw scaled images in the corners
    drawScaledImage(schoolLogo, IMAGE_SCALE, false);        // Left: logo (small)
    drawScaledImage(fairImage, FAIR_IMAGE_SCALE, true);     // Right: fair image (larger)
    
    // Fade/blur effect: semi-transparent rectangle over the background
    noStroke();
    fill(0, 4);
    rect(0, 0, width, height - height * 0.065);

    // Draw radar elements and sensor data
    fill(RADAR_COLOR);
    drawRadar();
    drawSensorLine();
    drawObjectLine();
    drawInfoText();

    // Draw the status indicator at the top center
    drawStatusIndicator();
  }
}

/* Draws a scaled image.
   If alignRight is true, the image is aligned to the right. */
void drawScaledImage(PImage img, float scaleFactor, boolean alignRight) {
  if (img == null) return;
  int newWidth  = int(width * scaleFactor);
  int newHeight = int(img.height * (newWidth / (float)img.width));
  if (alignRight) {
    image(img, width - newWidth - 20, 20, newWidth, newHeight); // 20px margin from corner
  } else {
    image(img, 20, 20, newWidth, newHeight); // 20px margin from corner
  }
}

/* Configures the serial port by searching for defined patterns */
void setupSerialPort() {
  String[] ports = Serial.list();
  println("Available ports:");
  for (int i = 0; i < ports.length; i++) {
    println(i + ": " + ports[i]);
  }
  
  String selectedPort = null;
  for (int i = 0; i < ports.length; i++) {
    for (String pattern : PORT_PATTERNS) {
      if (ports[i].indexOf(pattern) != -1) {
        selectedPort = ports[i];
        break;
      }
    }
    if (selectedPort != null) break;
  }
  
  if (selectedPort != null) {
    try {
      myPort = new Serial(this, selectedPort, SERIAL_BAUD);
      myPort.bufferUntil('.');
      println("Serial port opened on: " + selectedPort);
      arduinoPort = selectedPort;  // Store the connected port name
    } catch(Exception e) {
      println("Error opening serial port: " + e.getMessage());
    }
  } else {
    println("No Arduino port found.");
  }
}

/* Handles incoming data from the serial port */
void serialEvent(Serial port) {
  String rawData = port.readStringUntil('.');
  if (rawData == null) return;
  
  rawData = rawData.trim();
  if (rawData.length() < 3) {
    println("Received string too short: " + rawData);
    return;
  }
  
  if (rawData.charAt(rawData.length()-1) == '.') {
    rawData = rawData.substring(0, rawData.length()-1);
  }
  
  int commaIndex = rawData.indexOf(",");
  if (commaIndex == -1) {
    println("Incorrect format, no comma found in: " + rawData);
    return;
  }
  
  String angleStr = rawData.substring(0, commaIndex);
  String distanceStr = rawData.substring(commaIndex + 1);
  
  try {
    sensorAngle = int(angleStr);
    sensorDistance = int(distanceStr);
  } catch(Exception e) {
    println("Error converting data: " + e.getMessage());
  }
}

/* Draws the radar grid */
void drawRadar() {
  pushMatrix();
  translate(width / 2, height - height * 0.074);
  noFill();
  strokeWeight(RADAR_STROKE_WEIGHT);
  stroke(RADAR_COLOR);
  
  // Draw radar arcs (outer grid)
  float outerDiameter = width - width * 0.0625;
  arc(0, 0, outerDiameter, outerDiameter, PI, TWO_PI);
  arc(0, 0, width - width * 0.27, width - width * 0.27, PI, TWO_PI);
  arc(0, 0, width - width * 0.479, width - width * 0.479, PI, TWO_PI);
  arc(0, 0, width - width * 0.687, width - width * 0.687, PI, TWO_PI);
  
  // Draw radar grid lines
  line(-width / 2, 0, width / 2, 0);
  line(0, 0, (-width / 2) * cos(radians(30)), (-width / 2) * sin(radians(30)));
  line(0, 0, (-width / 2) * cos(radians(60)), (-width / 2) * sin(radians(60)));
  line(0, 0, (-width / 2) * cos(radians(90)), (-width / 2) * sin(radians(90)));
  line(0, 0, (-width / 2) * cos(radians(120)), (-width / 2) * sin(radians(120)));
  line(0, 0, (-width / 2) * cos(radians(150)), (-width / 2) * sin(radians(150)));
  line((-width / 2) * cos(radians(30)), 0, width / 2, 0);
  popMatrix();
}

/* Draws the sensor (green) line */
void drawSensorLine() {
  pushMatrix();
  translate(width/2, height - height*0.074);
  strokeWeight(LINE_STROKE_WEIGHT);
  stroke(LINE_COLOR);
  
  float radarDiameter = width - width * 0.0625;
  float radarRadius = radarDiameter / 2.0;
  
  float limitedDistance = min(sensorDistance, MAX_DISTANCE);
  float sensorLineLength = limitedDistance * (radarRadius / MAX_DISTANCE);

  // INVERT ANGLE for correct orientation (mirror horizontally)
  float displayAngle = 180 - sensorAngle;
  
  line(0, 0, sensorLineLength * cos(radians(displayAngle)), -sensorLineLength * sin(radians(displayAngle)));
  popMatrix();
}

/* Draws the detected object (red) line without exceeding the radar grid */
void drawObjectLine() {
  pushMatrix();
  translate(width/2, height - height*0.074);
  strokeWeight(LINE_STROKE_WEIGHT);
  stroke(OBJECT_COLOR);
  
  float radarDiameter = width - width * 0.0625;
  float radarRadius = radarDiameter / 2.0;
  
  float limitedDistance = min(sensorDistance, MAX_DISTANCE);
  float sensorPixelDistance = limitedDistance * (radarRadius / MAX_DISTANCE);

  // INVERT ANGLE for correct orientation (mirror horizontally)
  float displayAngle = 180 - sensorAngle;
  
  if (sensorDistance < MAX_DISTANCE) {
    line(sensorPixelDistance * cos(radians(displayAngle)), -sensorPixelDistance * sin(radians(displayAngle)),
         radarRadius * cos(radians(displayAngle)), -radarRadius * sin(radians(displayAngle)));
  }
  popMatrix();
}

/* Draws text information and angle labels */
void drawInfoText() {
  pushMatrix();
  
  String sensorStatus;
  if (sensorDistance > MAX_DISTANCE) {
    sensorStatus = "Out of Range";
  } else {
    sensorStatus = "In Range";
  }
  
  fill(0);
  noStroke();
  rect(0, height - height * 0.0648, width, height);
  
  fill(TEXT_COLOR);
  textSize(TEXT_SIZE_SMALL);
  text(int(MAX_DISTANCE / 4) + "cm", width - width * 0.3854, height - height * 0.0833);
  text(int(MAX_DISTANCE / 2) + "cm", width - width * 0.281, height - height * 0.0833);
  text(int(3 * MAX_DISTANCE / 4) + "cm", width - width * 0.177, height - height * 0.0833);
  text(MAX_DISTANCE + "cm", width - width * 0.0729, height - height * 0.0833);
  
  textSize(TEXT_SIZE_LARGE);
  text("Feria de la Ciencia 2025", width - width * 0.875, height - height * 0.0277);
  text("Ángulo: " + sensorAngle + " °", width - width * 0.48, height - height * 0.0277);
  text("Dist:", width - width * 0.26, height - height * 0.0277);
  if (sensorDistance < MAX_DISTANCE) {
    text("        " + sensorDistance + " cm", width - width * 0.225, height - height * 0.0277);
  } else {
    text("        > " + MAX_DISTANCE + " cm", width - width * 0.225, height - height * 0.0277);    
  }
  
  textSize(TEXT_SIZE_SMALL);
  drawAngleLabel("30°", 30, 0.4994, 0.0907, radians(60));
  drawAngleLabel("60°", 60, 0.503, 0.0888, radians(30));
  drawAngleLabel("90°", 90, 0.507, 0.0833, 0);
  drawAngleLabel("120°", 120, 0.513, 0.07129, radians(-30));
  drawAngleLabel("150°", 150, 0.5104, 0.0574, radians(-60));
  
  popMatrix();
}

/* Helper function to draw angle labels */
void drawAngleLabel(String label, float baseAngle, float xOffsetFactor, float yOffsetFactor, float rotationAngle) {
  pushMatrix();
  // Invert angle for mirrored radar
  float displayAngle = 180 - baseAngle;
  float tx = (width - width * xOffsetFactor) + (width / 2) * cos(radians(displayAngle));
  float ty = (height - height * yOffsetFactor) - (width / 2) * sin(radians(displayAngle));
  translate(tx, ty);
  rotate(rotationAngle);
  text(label, 0, 0);
  popMatrix();
}

/* Draws a visual status indicator at the top center */
void drawStatusIndicator() {
  String statusText;
  color statusColor;
  
  if (sensorDistance > SAFE_DISTANCE) {
    statusText = "Seguro";
    statusColor = color(0, 255, 0);
  } else if (sensorDistance > WARNING_DISTANCE) {
    statusText = "Peligro";
    statusColor = color(255, 255, 0);
  } else {
    statusText = "Alerta";
    statusColor = color(255, 0, 0);
  }
  
  int rectWidth = int(width * 0.156); // ~300px for 1920 width
  int rectHeight = int(height * 0.064); // ~70px for 1080 height
  int rectX = width/2 - rectWidth/2;
  int rectY = int(height * 0.02);
  
  noStroke();
  fill(0, 150);
  rect(rectX, rectY, rectWidth, rectHeight, 10);
  
  textAlign(CENTER, CENTER);
  textSize(40);
  fill(statusColor);
  text(statusText, width/2, rectY + rectHeight/2);
}

/* Draws the improved menu screen with logos, GitHub link, and status info,
   enlarged slightly and with extra space between the logo and the top */
void drawMenu() {
  float scaleFactor = width / 1920.0;
  background(50);
  textAlign(CENTER, CENTER);
  
  int menuTopMargin = int(80 * scaleFactor);
  int titleSize = int(100 * scaleFactor);
  textSize(titleSize);
  fill(255);
  // Title at the top
  text("SONAR v1.0", width/2, height/4 + menuTopMargin);
  
  // Main buttons in the center
  int buttonWidth = int(350 * scaleFactor);
  int buttonHeight = int(100 * scaleFactor);
  int startX = width/2 - buttonWidth/2;
  int startY = height/2 - buttonHeight - int(30 * scaleFactor);
  fill(100, 150, 255);
  rect(startX, startY, buttonWidth, buttonHeight, int(20 * scaleFactor));
  fill(255);
  textSize(int(45 * scaleFactor));
  text("Iniciar", width/2, startY + buttonHeight/2);
  
  int exitX = width/2 - buttonWidth/2;
  int exitY = height/2 + int(30 * scaleFactor);
  fill(255, 100, 100);
  rect(exitX, exitY, buttonWidth, buttonHeight, int(20 * scaleFactor));
  fill(255);
  text("Salir", width/2, exitY + buttonHeight/2);
  
  // Adjustment buttons (Increase/Decrease)
  int adjButtonWidth = int(280 * scaleFactor);
  int adjButtonHeight = int(100 * scaleFactor);
  int incButtonX = width/2 - adjButtonWidth - int(20 * scaleFactor);
  int decButtonX = width/2 + int(20 * scaleFactor);
  int adjButtonY = exitY + buttonHeight + int(50 * scaleFactor);
  fill(100, 150, 255);
  rect(incButtonX, adjButtonY, adjButtonWidth, adjButtonHeight, int(20 * scaleFactor));
  fill(255);
  textSize(int(34 * scaleFactor));
  text("Aumentar", incButtonX + adjButtonWidth/2, adjButtonY + adjButtonHeight/2);
  
  fill(255, 100, 100);
  rect(decButtonX, adjButtonY, adjButtonWidth, adjButtonHeight, int(20 * scaleFactor));
  fill(255);
  text("Reducir", decButtonX + adjButtonWidth/2, adjButtonY + adjButtonHeight/2);
  
  // Arduino connection info below the adjustment buttons
  int infoSize = int(26 * scaleFactor);
  textSize(infoSize);
  fill(255);
  int infoY = adjButtonY + adjButtonHeight + int(60 * scaleFactor);
  if (arduinoPort != null && arduinoPort.length() > 0) {
    text("Arduino connected on port: " + arduinoPort, width/2, infoY);
  } else {
    text("Arduino not connected", width/2, infoY);
  }
  text("Latest version: " + APP_LAST_UPDATE, width/2, infoY + int(40 * scaleFactor));
  
  // GitHub button and its label
  int ghButtonSize = int(120 * scaleFactor);
  int ghX = width - ghButtonSize - int(40 * scaleFactor);
  int ghY = height - ghButtonSize - int(40 * scaleFactor);
  if (githubLogo != null) {
    image(githubLogo, ghX, ghY, ghButtonSize, ghButtonSize);
  } else {
    fill(200);
    rect(ghX, ghY, ghButtonSize, ghButtonSize, int(10 * scaleFactor));
    fill(0);
    textSize(int(22 * scaleFactor));
    text("GitHub", ghX + ghButtonSize/2, ghY + ghButtonSize/2);
  }
  textSize(infoSize);
  fill(255);
  text("View on GitHub", width - ghButtonSize/2 - int(40 * scaleFactor), ghY - int(20 * scaleFactor));
}

/* Handles mouse presses for the menu and GitHub link */
void mousePressed() {
  if (showMenu) {
    float scaleFactor = width / 1920.0;
    int buttonWidth = int(350 * scaleFactor);
    int buttonHeight = int(100 * scaleFactor);
    int startX = width/2 - buttonWidth/2;
    int startY = height/2 - buttonHeight - int(30 * scaleFactor);
    int exitX = width/2 - buttonWidth/2;
    int exitY = height/2 + int(30 * scaleFactor);
    
    // "Start" button
    if (mouseX > startX && mouseX < startX + buttonWidth &&
        mouseY > startY && mouseY < startY + buttonHeight) {
      showMenu = false;
      return;
    }
    // "Exit" button
    if (mouseX > exitX && mouseX < exitX + buttonWidth &&
        mouseY > exitY && mouseY < exitY + buttonHeight) {
      exit();
      return;
    }
    
    // GitHub button
    int ghButtonSize = int(120 * scaleFactor);
    int ghX = width - ghButtonSize - int(40 * scaleFactor);
    int ghY = height - ghButtonSize - int(40 * scaleFactor);
    if (mouseX > ghX && mouseX < ghX + ghButtonSize &&
        mouseY > ghY && mouseY < ghY + ghButtonSize) {
      openLink(GITHUB_URL);
      return;
    }
    
    // Adjustment buttons
    int adjButtonWidth = int(280 * scaleFactor);
    int adjButtonHeight = int(100 * scaleFactor);
    int incButtonX = width/2 - adjButtonWidth - int(20 * scaleFactor);
    int decButtonX = width/2 + int(20 * scaleFactor);
    int adjButtonY = exitY + buttonHeight + int(50 * scaleFactor);
    if (mouseX > incButtonX && mouseX < incButtonX + adjButtonWidth &&
        mouseY > adjButtonY && mouseY < adjButtonY + adjButtonHeight) {
      surface.setSize(width + int(200 * scaleFactor), height + int(150 * scaleFactor));
      return;
    }
    if (mouseX > decButtonX && mouseX < decButtonX + adjButtonWidth &&
        mouseY > adjButtonY && mouseY < adjButtonY + adjButtonHeight) {
      int newWidth = max(width - int(200 * scaleFactor), int(900 * scaleFactor));
      int newHeight = max(height - int(150 * scaleFactor), int(500 * scaleFactor));
      surface.setSize(newWidth, newHeight);
      return;
    }
  }
  if (key == ESC) {
    exit();
  }
}

/* Handles keyboard events */
void keyPressed() {
  if (key == ESC) {
    exit();
  }
}

/* Opens the given URL in the default web browser */
void openLink(String url) {
  try {
    Desktop.getDesktop().browse(new URI(url));
  } catch (Exception e) {
    println("Error opening URL: " + e.getMessage());
  }
}

// Add the following function at the end of the file:
void updateSerialConnection() {
  String[] ports = Serial.list();
  boolean currentPortFound = false;
  for (int i = 0; i < ports.length; i++) {
    if (!arduinoPort.equals("") && ports[i].equals(arduinoPort)) {
      currentPortFound = true;
      break;
    }
  }
  if (!currentPortFound) {
    if (myPort != null) {
      myPort.stop();
      myPort = null;
    }
    arduinoPort = "";
    for (int i = 0; i < ports.length; i++) {
      for (String pattern : PORT_PATTERNS) {
        if (ports[i].indexOf(pattern) != -1) {
          try {
            myPort = new Serial(this, ports[i], SERIAL_BAUD);
            myPort.bufferUntil('.');
            arduinoPort = ports[i];
            println("Serial port reconnected on: " + ports[i]);
            return;
          } catch(Exception e) {
            println("Error reconnecting serial port: " + e.getMessage());
          }
        }
      }
    }
  }
}
