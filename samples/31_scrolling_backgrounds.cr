require "../src/sdl"
require "../src/image"

class Dot
  WIDTH = 20
  HEIGHT = 20
  VELOCITY = 5

  struct Position
    property x : Int32 = 0
    property y : Int32 = 0
  end

  struct Velocity
    property x : Int32 = 0
    property y : Int32 = 0
  end

  @surface : SDL::Surface

  def initialize
    @position = Position.new
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

  def move(x_limit : Int32, y_limit : Int32)
    @position.x += @velocity.x
    @position.x -= @velocity.x if @position.x < 0 || @position.x + WIDTH > x_limit

    @position.y += @velocity.y
    @position.y -= @velocity.y if @position.y < 0 || @position.y + HEIGHT > y_limit
  end

  def render(renderer : SDL::Renderer)
    renderer.copy(@surface, dstrect: SDL::Rect[@position.x, @position.y, @surface.width, @surface.height])
  end
end

SDL.init(SDL::Init::VIDEO); at_exit { SDL.quit }
SDL::IMG.init(SDL::IMG::Init::PNG); at_exit { SDL::IMG.quit }
SDL.set_hint(SDL::Hint::RENDER_SCALE_QUALITY, "1")

window = SDL::Window.new("SDL tutorial", 640, 480)
renderer = SDL::Renderer.new(window, SDL::Renderer::Flags::ACCELERATED | SDL::Renderer::Flags::PRESENTVSYNC)

dot = Dot.new
background = SDL::IMG.load(File.join(__DIR__, "data", "scrolling_bg.png"))
scrolling_offset = 0

loop do
  case event = SDL::Event.poll
  when SDL::Event::Quit
    break
  when SDL::Event::Keyboard
    dot.handle_events(event)
  end

  dot.move(window.width, window.height)

  scrolling_offset -= 1
  scrolling_offset = 0 if scrolling_offset < -background.width

  renderer.draw_color = SDL::Color[255]
  renderer.clear

  renderer.copy(background, dstrect: SDL::Rect[scrolling_offset, 0, background.width, background.height])
  renderer.copy(background, dstrect: SDL::Rect[scrolling_offset + background.width, 0, background.width, background.height])

  dot.render(renderer)

  renderer.present
end

[background, dot, renderer, window].each(&.finalize)
