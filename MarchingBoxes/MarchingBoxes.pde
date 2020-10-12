import shiffman.box2d.*;
import org.jbox2d.collision.shapes.*;
import org.jbox2d.common.*;
import org.jbox2d.dynamics.*;
import processing.video.*;

Capture cam;

// A reference to our box2d world
Box2DProcessing box2d;

// A list we'll use to track fixed objects
ArrayList<Boundary> boundaries;
// A list for all of our rectangles
ArrayList<Box> boxes;
ArrayList<Box> freeBoxes;

int rez = 5;
int cols, rows;
float[][] field;
boolean marchingStroke = false;
boolean marchingSquares = true;
boolean condition = true;

OpenSimplexNoise noise;
int instances = 1000;
int counter = 0;

PGraphics pg;
boolean ready = false;

void setup()
{
  size(600, 400, P2D);

  String[] cameras = Capture.list();

  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(i);
      println(cameras[i]);
    }

    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[19]);
    cam.start();
  }  

  pg = createGraphics(width, height);
  // Initialize box2d physics and create the world
  box2d = new Box2DProcessing(this);
  box2d.createWorld();
  // We are setting a custom gravity
  box2d.setGravity(0, -10);

  // Create ArrayLists  
  boxes = new ArrayList<Box>();
  boundaries = new ArrayList<Boundary>();
  freeBoxes =new ArrayList<Box>();


  cols = width / rez + 1;
  rows = height / rez + 1;
  field = new float[cols][rows];
  for (int i = 0; i < cols; i++)
  {
    for (int j = 0; j < rows; j++)
    {
      field[i][j] = floor(random(2));
    }
  }
  rectMode(CENTER);
}

void draw()
{

  if (ready) {
    if (counter < instances)
    {
      int inst = 0;
      while (inst < 5)
      {
        if (random(1) < 0.2) {
          Box p = new Box(random(width), 0, random(5, 10), random(5, 10));
          freeBoxes.add(p);
          counter++;
          inst++;
        }
      }
    }
  }
  box2d.step();
  // Boxes fall from the top every so often

  float cutoff = 0.3;
  background(0);
  if (cam.available() == true)
  {
    cam.read();
  }
  image(cam, 0, 0, width, height);
  pg.beginDraw();
  pg.strokeWeight(10);
  pg.stroke(0);
  if (mousePressed)
    pg.line(pmouseX, pmouseY, mouseX, mouseY);
  pg.endDraw();
  image(pg, 0, 0, width, height);
  filter(GRAY);
  //if(condition)return;
  for (int i = boundaries.size() - 1; i >= 0; --i)
  {
    box2d.destroyBody(boundaries.get(i).b);
  }
  boundaries.clear();
  for (int i = 0; i < cols; i++)
  {
    for (int j = 0; j < rows; j++)
    {
      field[i][j] = red(get(i*rez, j * rez))/255;
      if (field[i][j] > cutoff)
      {
        field[i][j] = 0;
      } else {
        boundaries.add(new Boundary(i * rez, j * rez, rez, rez));
      }
    }
  }

  //background(0);
  for (int i = 0; i < cols; i++)
  {
    for (int j = 0; j < rows; j++)
    {
      //stroke(field[i][j] * 255);
      //strokeWeight(rez* 0.4);
      if (marchingSquares)
      {
        fill(field[i][j] * 255);
        noStroke();
        //if (field[i][j]>0)
        //rect(i * rez, j * rez, rez, rez);
      }
    }
  }

  for (int i = 0; i < cols-1; i++)
  {
    for (int j = 0; j < rows-1; j++)
    {
      float x = i * rez;
      float y = j * rez;
      PVector a = new PVector(x + rez* 0.5, y);
      PVector b = new PVector(x + rez, y + rez * 0.5);
      PVector c = new PVector(x + rez* 0.5, y + rez);
      PVector d = new PVector(x, y + rez * 0.5);
      if (marchingStroke)
      {
        int state = getState(ceil(field[i][j]), ceil(field[i + 1][j]), 
          ceil(field[i+1][j+1]), ceil(field[i][j+1]));
        stroke(255);
        strokeWeight(1);
        switch(state)
        {
        case 1:
          line(c, d);
          break;
        case 2:
          line(b, c);
          break;
        case 3:
          line(b, d);
          break;
        case 4:
          line(a, b);
          break;
        case 5:
          line(a, d);
          line(b, c);
          break;
        case 6:
          line(a, c);
          break;
        case 7:
          line(a, d);
          break;
        case 8:
          line(a, d);
          break;
        case 9:
          line(a, c);
          break;
        case 10:
          line(c, d);
          line(a, b);
          break;
        case 11:
          line(a, b);
          break;
        case 12:
          line(b, d);
          break;
        case 13:
          line(b, c);
          break;
        case 14:
          line(c, d);
          break;
        case 15:

          break;
        }
        //forces[i][j].show();
      }
    }
  }
  // Display all the boxes
  for (Boundary b : boundaries) {
    //b.display();
  }
  for (Box b : freeBoxes) {
    b.display();
  }
  for (int i = freeBoxes.size()-1; i >= 0; i--) {
    Box b = freeBoxes.get(i);
    if (b.done()) {
      freeBoxes.remove(i);
    }
  }
}

void line(PVector a, PVector b)
{
  line(a.x, a.y, b.x, b.y);
}

PVector vectorDirector(PVector a, PVector b)
{
  return PVector.sub(b, a);
}

int getState(int a, int b, int c, int d)
{
  return a * 8 + b * 4 + c * 2 + d * 1;
}

int getState(float a, float b, float c, float d)
{
  return int(a * 8 + b * 4 + c * 2 + d * 1);
}

void keyPressed()
{
  if (key == 'q')
  {
    marchingStroke = !marchingStroke;
  }
  if (key == 'w')
  {
    marchingSquares = !marchingSquares;
  }
  if (key == ' ')
  {
    ready = true;
  }
}
