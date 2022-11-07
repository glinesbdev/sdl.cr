require "../src/sdl"
require "../src/image"

LEVEL_WIDTH = 1280
LEVEL_HEIGHT = 960

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

  getter position : Position

  @surface : SDL::Surface

  def initialize(x, y)
    @position = Position.new(x, y)
    @velocity = Velocity.new
    @surface = SDL.load_bmp(File.join(__DIR__, "data", "dot.bmp"))
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

  def move
    @position.x += @velocity.x
    @position.x -= @velocity.x if @position.x < 0 || (@position.x + WIDTH > LEVEL_WIDTH)

    @position.y += @velocity.y
    @position.y -= @velocity.y if @position.y < 0 || (@position.y + HEIGHT > LEVEL_HEIGHT)
  end

  def render(renderer : SDL::Renderer, cam_x : Int32, cam_y : Int32)
    renderer.copy(@surface, dstrect: SDL::Rect[
      @position.x - cam_x,
      @position.y - cam_y,
      @surface.width,
      @surface.height
    ])
  end
end

SDL.init(SDL::Init::VIDEO); at_exit { SDL.quit }
SDL::IMG.init(SDL::IMG::Init::PNG); at_exit { SDL::IMG.quit }
SDL.set_hint(SDL::Hint::RENDER_SCALE_QUALITY, "1")

window = SDL::Window.new("SDL tutorial", 640, 480)
renderer = SDL::Renderer.new(window, SDL::Renderer::Flags::ACCELERATED | SDL::Renderer::Flags::PRESENTVSYNC)

dot = Dot.new(window.width // 2, window.height // 2)
background = SDL::IMG.load(File.join(__DIR__, "data", "bg.png"))
camera = SDL::Rect[0, 0, window.width, window.height]

loop do
  case event = SDL::Event.poll
  when SDL::Event::Quit
    break
  when SDL::Event::Keyboard
    dot.handle_events(event)
  end

  dot.move

  camera.x = (dot.position.x + Dot::WIDTH // 2) - window.width // 2
  camera.y = (dot.position.y + Dot::HEIGHT // 2) - window.height // 2

  camera.x = 0 if camera.x < 0
  camera.y = 0 if camera.y < 0
  camera.x = LEVEL_WIDTH - camera.w if camera.x > LEVEL_WIDTH - camera.w
  camera.y = LEVEL_HEIGHT - camera.h if camera.y > LEVEL_HEIGHT - camera.h

  renderer.draw_color = SDL::Color[255]
  renderer.clear

  renderer.copy(background, camera, SDL::Rect[0, 0, camera.w, camera.h])

  dot.render(renderer, camera.x, camera.y)

  renderer.present
end

[background, dot, renderer, window].each(&.finalize)
