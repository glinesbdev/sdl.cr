require "../src/sdl"

module SimplePhysics
  def self.check_collision(a : SDL::Rect, b : SDL::Rect) : Bool
    left_a = a.x
    right_a = a.x + a.w
    top_a = a.y
    bottom_a = a.y + a.h

    left_b = b.x
    right_b = b.x + b.w
    top_b = b.y
    bottom_b = b.y + b.h

    if bottom_a <= top_b ||
       top_a >= bottom_b ||
       right_a <= left_b ||
       left_a >= right_b
      return false
    end

    return true
  end
end

class Dot
  WIDTH = 20
  HEIGHT = 20
  VELOCITY = 10

  struct Position
    property x : Int32 = 0
    property y : Int32 = 0
  end

  struct Velocity
    property x : Int32 = 0
    property y : Int32 = 0
  end

  @surface : SDL::Surface
  @collider : SDL::Rect

  def initialize
    @position = Position.new
    @velocity = Velocity.new
    @surface = SDL.load_bmp(File.join(__DIR__, "data", "dot.bmp"))
    @collider = SDL::Rect[0, 0, WIDTH, HEIGHT]
  end

  def finalize
    @surface.finalize
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

  def move(x_limit : Int32, y_limit : Int32, wall : SDL::Rect)
    # move left or right
    @position.x += @velocity.x
    @collider.x = @position.x

    # if we went too far left or right, move back
    if @position.x < 0 || @position.x + WIDTH > x_limit || SimplePhysics.check_collision(@collider, wall)
      @position.x -= @velocity.x
      @collider.x = @position.x
    end

    # move up or down
    @position.y += @velocity.y
    @collider.y = @position.y

    # if we went too far up or down, move back
    if @position.y < 0 || @position.y + HEIGHT > y_limit || SimplePhysics.check_collision(@collider, wall)
      @position.y -= @velocity.y
      @collider.y = @position.y
    end
  end

  def render(renderer : SDL::Renderer)
    renderer.copy(@surface, dstrect: SDL::Rect[@position.x, @position.y, @surface.width, @surface.height])
  end

  def render_collider(renderer : SDL::Renderer)
    renderer.draw_rect(@collider)
  end
end

SDL.init(SDL::Init::VIDEO); at_exit { SDL.quit }
SDL.set_hint(SDL::Hint::RENDER_SCALE_QUALITY, "1")

window = SDL::Window.new("SDL tutorial", 640, 480)
renderer = SDL::Renderer.new(window, SDL::Renderer::Flags::ACCELERATED | SDL::Renderer::Flags::PRESENTVSYNC)
dot = Dot.new
wall = SDL::Rect[300, 40, 40, 400]

loop do
  case event = SDL::Event.poll
  when SDL::Event::Quit
    break
  when SDL::Event::Keyboard
    dot.handle_events(event)
  end

  dot.move(window.width, window.height, wall)

  renderer.draw_color = SDL::Color[255]
  renderer.clear

  renderer.draw_color = SDL::Color[0]
  renderer.draw_rect(wall)

  dot.render(renderer)

  # uncomment to see the dot's collider box
  # dot.render_collider(renderer)

  renderer.present
end

# clean up data
[dot, renderer, window].each(&.finalize)
