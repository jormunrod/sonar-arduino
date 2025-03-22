#include <Servo.h>

const int trigPin = 3;
const int echoPin = 4;
const int buttonPin = 2;

const int ledVerde = 8;
const int ledAmarillo = 7;
const int ledRojo = 6;
const int buzzer = 11;

long duration;
int distance;
Servo myServo;
bool paused = false;
bool lastButtonState = HIGH;

// Safe, warning distances in cm
int safeDistance = 70;
int warningDistance = 10;

// Variables to handle smooth state transitions
int currentState = 0; // 0 = Safe, 1 = Warning, 2 = Danger
int previousState = 0;
unsigned long lastChangeTime = 0;  // To avoid state change too often
unsigned long debounceDelay = 100; // 500ms debounce delay for state change

void setup()
{
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buttonPin, INPUT_PULLUP);

  pinMode(ledVerde, OUTPUT);
  pinMode(ledAmarillo, OUTPUT);
  pinMode(ledRojo, OUTPUT);
  pinMode(buzzer, OUTPUT);

  // Initially turn on the green LED
  digitalWrite(ledVerde, HIGH);
  digitalWrite(ledAmarillo, LOW);
  digitalWrite(ledRojo, LOW);
  noTone(buzzer); // Ensure buzzer is off

  Serial.begin(9600);
  myServo.attach(12);
}

void loop()
{
  // Check if the button was pressed
  bool buttonState = digitalRead(buttonPin);

  if (buttonState == LOW && lastButtonState == HIGH)
  {
    paused = !paused;
    delay(50);
  }
  lastButtonState = buttonState;

  if (!paused)
  {
    int i = 15;
    while (i <= 165 && !paused)
    {
      myServo.write(i);
      delay(30);
      distance = calculateDistance();
      Serial.print(i);
      Serial.print(",");
      Serial.print(distance);
      Serial.print(".");

      updateLEDs(distance); // Update LEDs and buzzer based on distance

      i++;
      checkButton();
    }

    i = 165;
    while (i >= 15 && !paused)
    {
      myServo.write(i);
      delay(30);
      distance = calculateDistance();
      Serial.print(i);
      Serial.print(",");
      Serial.print(distance);
      Serial.print(".");

      updateLEDs(distance); // Update LEDs and buzzer based on distance

      i--;
      checkButton();
    }
  }
}

// Function to measure the distance using the ultrasonic sensor
int calculateDistance()
{
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH);
  distance = duration * 0.034 / 2;
  return distance;
}

// Function to check the button press state
void checkButton()
{
  bool buttonState = digitalRead(buttonPin);
  if (buttonState == LOW && lastButtonState == HIGH)
  {
    paused = !paused;
    delay(50); // Debounce delay
  }
  lastButtonState = buttonState;
}

// Function to update LEDs and buzzer based on distance
void updateLEDs(int dist)
{
  int newState = currentState;

  // Determine new state based on distance
  if (dist > safeDistance)
  {
    newState = 0; // Safe
  }
  else if (dist > warningDistance && dist <= safeDistance)
  {
    newState = 1; // Warning
  }
  else
  {
    newState = 2; // Danger
  }

  // Only change state if enough time has passed to avoid flickering
  if (newState != previousState && millis() - lastChangeTime > debounceDelay)
  {
    previousState = newState;
    lastChangeTime = millis(); // Record time of state change

    // Update LEDs and buzzer based on new state
    switch (newState)
    {
    case 0: // Safe
      digitalWrite(ledVerde, HIGH);
      digitalWrite(ledAmarillo, LOW);
      digitalWrite(ledRojo, LOW);
      noTone(buzzer); // Turn off buzzer
      break;
    case 1: // Warning
      digitalWrite(ledVerde, LOW);
      digitalWrite(ledAmarillo, HIGH);
      digitalWrite(ledRojo, LOW);
      noTone(buzzer); // Turn off buzzer
      break;
    case 2: // Danger
      digitalWrite(ledVerde, LOW);
      digitalWrite(ledAmarillo, LOW);
      digitalWrite(ledRojo, HIGH);
      tone(buzzer, 700); // 1 kHz sound on buzzer
      break;
    }
  }
}
