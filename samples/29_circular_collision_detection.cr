require "../src/sdl"

module SimplePhysics
  def self.check_collision(a : Circle, b : Circle) : Bool
    # calculate total radius squared
    total_radius_squared = (a.r + b.r) * (a.r + b.r)

    # if the distance between the centers of the circles is less than the sum of their radii, the circles have collided
    distance_squared(a.x, a.y, b.x, b.y) < total_radius_squared
  end

  def self.check_collision(a : Circle, b : SDL::Rect) : Bool
    # closet point on collision box
    cx = cy = 0

    # find closest x offset
    if a.x < b.x
      cx = b.x
    elsif a.x > b.x + b.w
      cx = b.x + b.w
    else
      cx = a.x
    end

    # find closest y offset
    if a.y < b.y
      cy = b.y
    elsif a.y > b.y + b.h
      cy = b.y + b.h
    else
      cy = a.y
    end

    # if the closest point is inside the circle, the shapes have collided
    distance_squared(a.x, a.y, cx, cy) < a.r * a.r
  end

  private def self.distance_squared(x1 : Int32, y1 : Int32, x2 : Int32, y2 : Int32) : Int32
    delta_x = x2 - x1
    delta_y = y2 - y1
    delta_x * delta_x + delta_y * delta_y
  end
end

class Circle
  property x : Int32
  property y : Int32
  property r : Int32

  def initialize(@x, @y, @r)
  end
end

class Dot
  WIDTH = 20
  HEIGHT = 20
  VELOCITY = 3

  struct Position
    property x : Int32
    property y : Int32

    def initialize(@x, @y)
    end
  end

  struct Velocity
    property x : Int32
    property y : Int32

    def initialize(@x = 0, @y = 0)
    end
  end

  @surface : SDL::Surface
  @collider : Circle

  def initialize(x, y)
    @position = Position.new(x, y)
    @velocity = Velocity.new
    @collider = Circle.new(0, 0, WIDTH // 2)
    @surface = SDL.load_bmp(File.join(__DIR__, "data", "dot.bmp"))

    shift_collider
  end

  def finalize
    @surface.finalize
  end

  def collider
    @collider
  end

  def handle_events(event : SDL::Event::Keyboard)
    case event.sym
    when .up?, .w?
      @velocity.y -= VELOCITY
    when .down?, .s?
      @velocity.y += VELOCITY
    when .left?, .a?
      @velocity.x -= VELOCITY
    when .right?, .d?
      @velocity.x += VELOCITY
    end if event.keydown? && event.repeat == 0

    case event.sym
    when .up?, .w?
      @velocity.y += VELOCITY
    when .down?, .s?
      @velocity.y -= VELOCITY
    when .left?, .a?
      @velocity.x += VELOCITY
    when .right?, .d?
      @velocity.x -= VELOCITY
    end if event.keyup? && event.repeat == 0
  end

  def move(x_limit : Int32, y_limit : Int32, square : SDL::Rect, circle : Circle)
    @position.x += @velocity.x
    shift_collider

    if @position.x - @collider.r < 0 ||
       @position.x + @collider.r > x_limit ||
       SimplePhysics.check_collision(@collider, square) ||
       SimplePhysics.check_collision(@collider, circle)
      @position.x -= @velocity.x
      shift_collider
    end

    @position.y += @velocity.y
    shift_collider

    if @position.y - @collider.r < 0 ||
       @position.y + @collider.r > y_limit ||
       SimplePhysics.check_collision(@collider, square) ||
       SimplePhysics.check_collision(@collider, circle)
      @position.y -= @velocity.y
      shift_collider
    end
  end

  def render(renderer : SDL::Renderer)
    renderer.copy(@surface, dstrect: SDL::Rect[
      @position.x - @collider.r,
      @position.y - @collider.r,
      @surface.width,
      @surface.height
    ])
  end

  private def shift_collider
    @collider.x = @position.x
	  @collider.y = @position.y
  end
end

SDL.init(SDL::Init::VIDEO); at_exit { SDL.quit }
SDL.set_hint(SDL::Hint::RENDER_SCALE_QUALITY, "1")

window = SDL::Window.new("SDL tutorial", 640, 480)
renderer = SDL::Renderer.new(window, SDL::Renderer::Flags::ACCELERATED | SDL::Renderer::Flags::PRESENTVSYNC)

dot = Dot.new(Dot::WIDTH // 2, Dot::HEIGHT // 2)
other_dot = Dot.new(window.width // 4, window.height // 4)
wall = SDL::Rect[300, 40, 40, 400]

loop do
  case event = SDL::Event.poll
  when SDL::Event::Quit
    break
  when SDL::Event::Keyboard
    dot.handle_events(event)
  end

  dot.move(window.width, window.height, wall, other_dot.collider)

  renderer.draw_color = SDL::Color[255]
  renderer.clear

  renderer.draw_color = SDL::Color[0]

  renderer.draw_rect(wall)
  dot.render(renderer)
  other_dot.render(renderer)

  renderer.present
end

# clean up data
[other_dot, dot, renderer, window].each(&.finalize)
