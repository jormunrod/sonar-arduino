# Sonar Arduino Project

## Description

Arduino-based project that uses an ultrasonic sensor to measure distances. A servo motor performs a sweep (from 15° to 165°) and, based on the detected distance, different indicators are activated:

- Green LED for safe distances
- Yellow LED for warnings
- Red LED and buzzer for danger situations

## Features

- Automatic sweep with servo motor.
- Distance measurement with the HC-SR04 ultrasonic sensor.
- Visual (LEDs) and audible (buzzer) indicators.
- Pause and resume functionality via button.

## Requirements

- Arduino (UNO, Mega, etc.)
- Ultrasonic sensor (e.g., HC-SR04)
- Servo motor
- LEDs (green, yellow, and red)
- Buzzer
- Arduino IDE

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/jormunrod/sonar-arduino.git
   ```
2. Open the project in Arduino IDE.
3. Connect the components according to the wiring diagram.

## Usage

1. Recommended wiring:
   - trigPin: pin 3
   - echoPin: pin 4
   - buttonPin: pin 2
   - green LED: pin 8
   - yellow LED: pin 7
   - red LED: pin 6
   - buzzer: pin 11
2. Upload the sketch to Arduino.
3. Open the Serial Monitor to observe the LED and buzzer behavior based on the measured distance.
