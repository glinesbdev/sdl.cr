require "../src/sdl"

module SimplePhysics
  def self.check_collision(a : Array(SDL::Rect), b : Array(SDL::Rect)) : Bool
    left_a = left_b = 0
    right_a = right_b = 0
    top_a = top_b = 0
    bottom_a = bottom_b = 0

    a.each do |a_box|
      left_a = a_box.x
      right_a = a_box.x + a_box.w
      top_a = a_box.y
      bottom_a = a_box.y + a_box.h

      b.each do |b_box|
        left_b = b_box.x
        right_b = b_box.x + b_box.w
        top_b = b_box.y
        bottom_b = b_box.y + b_box.h

        return true unless (bottom_a <= top_b) || (top_a >= bottom_b) || (right_a <= left_b) || (left_a >= right_b)
      end
    end

    false
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
  @colliders  = [] of SDL::Rect

  def initialize(x, y)
    @position = Position.new(x, y)
    @velocity = Velocity.new
    @surface = SDL.load_bmp(File.join(__DIR__, "data", "dot.bmp"))

    initialize_colliders
    shift_colliders
  end

  def finalize
    @surface.finalize
  end

  def colliders
    @colliders
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

  def move(x_limit : Int32, y_limit : Int32, other_colliders : Array(SDL::Rect))
    @position.x += @velocity.x
    shift_colliders

    if @position.x < 0 || @position.x + WIDTH > x_limit || SimplePhysics.check_collision(@colliders, other_colliders)
      @position.x -= @velocity.x
      shift_colliders
    end

    @position.y += @velocity.y
    shift_colliders

    if @position.y < 0 || @position.y + HEIGHT > y_limit || SimplePhysics.check_collision(@colliders, other_colliders)
      @position.y -= @velocity.y
      shift_colliders
    end
  end

  def render(renderer : SDL::Renderer)
    renderer.copy(@surface, dstrect: SDL::Rect[@position.x, @position.y, @surface.width, @surface.height])
  end

  def render_colliders(renderer : SDL::Renderer)
    renderer.draw_color = SDL::Color[255, 0, 255, 255]
    @colliders.each { |collider| renderer.draw_rect(collider) }
  end

  private def initialize_colliders
    width_height = [{6, 1}, {10, 1}, {14, 1}, {16, 2}, {18, 2}, {20, 6}, {18, 2}, {16, 2}, {14, 1}, {10, 1}, {6, 1}]
    @colliders = width_height.map { |w, h| SDL::Rect[@position.x, @position.y, w, h] }
  end

  private def shift_colliders
    offset = 0

    @colliders.map! do |collider|
      collider.x = @position.x + (WIDTH - collider.w) // 2
      collider.y = @position.y + offset
      offset += collider.h
      collider
    end
  end
end

SDL.init(SDL::Init::VIDEO); at_exit { SDL.quit }
SDL.set_hint(SDL::Hint::RENDER_SCALE_QUALITY, "1")

window = SDL::Window.new("SDL tutorial", 640, 480)
renderer = SDL::Renderer.new(window, SDL::Renderer::Flags::ACCELERATED | SDL::Renderer::Flags::PRESENTVSYNC)
dot = Dot.new(0, 0)
other_dot = Dot.new(window.width // 4, window.height // 4)

loop do
  case event = SDL::Event.poll
  when SDL::Event::Quit
    break
  when SDL::Event::Keyboard
    dot.handle_events(event)
  end

  dot.move(window.width, window.height, other_dot.colliders)

  renderer.draw_color = SDL::Color[255]
  renderer.clear

  dot.render(renderer)
  other_dot.render(renderer)

  # uncomment to see how the colliders are drawn
  # dot.render_colliders(renderer)
  # other_dot.render_colliders(renderer)

  renderer.present
end

# clean up data
[other_dot, dot, renderer, window].each(&.finalize)
