const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const os = std.os;

const Game = @import("snake.zig").Game;

const CELL_SIZE = 20;

var speed: f32 = 100;

const ErrorSet = error{SDLError};

pub const ScreenWidth = 600;
pub const ScreenHeight = 600;

const MAX_HEIGHT = @divTrunc(ScreenHeight, CELL_SIZE);
const MAX_WIDTH = @divTrunc(ScreenWidth, CELL_SIZE);

var RNG = std.rand.DefaultPrng.init(0);
var random = std.rand.DefaultPrng.random(&RNG);

pub fn main() anyerror!void {
    _ = c.SDL_Init(c.SDL_INIT_EVERYTHING);
    defer c.SDL_Quit();

    var window = c.SDL_CreateWindow("SDL Rectangle Example Thingy", 100, 100, ScreenWidth, ScreenHeight, c.SDL_WINDOW_SHOWN);
    if (window == null) {
        return ErrorSet.SDLError;
    }
    defer c.SDL_DestroyWindow(window);

    var renderer = c.SDL_CreateRenderer(window, 0, 0);
    defer c.SDL_DestroyRenderer(renderer);

    var event: c.SDL_Event = undefined;
    var quit = false;

    const center_x = @divTrunc(ScreenWidth, 2);
    const center_y = @divTrunc(ScreenHeight, 2);

    const pos_x = @divTrunc(center_x, CELL_SIZE);
    const pos_y = @divTrunc(center_y, CELL_SIZE);

    var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.child_allocator;

    var player = try Snake.init(allocator);
    player.head.x = pos_x;
    player.head.y = pos_y;

    var food = try Food.init(random, allocator);

    while (!quit) {
        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);

        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_KEYDOWN => {
                    player.changeDirection(event);
                },
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }

        player.move();
        player.updateBodyPartsDirections();

        player.render(renderer);
        food.render(renderer);

        if (food.intersects(&player)) {
            food = try Food.init(random, allocator);
            try player.grow(allocator);
        }

        _ = c.SDL_RenderPresent(renderer);
        c.SDL_Delay(100);

        if (player.isOutOfBounds() or try player.intersectsItself()) {
            c.SDL_Quit();
            std.os.exit(1);
        }

        speed -= 0.1;
    }
}

pub const Direction = enum(u8) { Top, Left, Right, Bottom };

pub const Food = struct {
    const Self = @This();

    x: i32,
    y: i32,

    pub fn init(rnd: anytype, allocator: *std.mem.Allocator) !*Food {
        var food: *Food = try allocator.create(Food);
        food.x = rnd.intRangeAtMost(i32, 0, MAX_WIDTH);
        food.y = rnd.intRangeAtMost(i32, 0, MAX_WIDTH);
        return food;
    }

    pub fn render(self: *Self, renderer: anytype) void {
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 100, 100, 100);

        var rect = c.SDL_Rect{ .x = @intCast(c_int, 0), .y = @intCast(c_int, 0), .w = CELL_SIZE, .h = CELL_SIZE };

        rect.x = @intCast(c_int, self.x * CELL_SIZE);
        rect.y = @intCast(c_int, self.y * CELL_SIZE);

        _ = c.SDL_RenderDrawRect(renderer, &rect);
    }

    pub fn intersects(self: *Self, snake: *Snake) bool {
        return self.x == snake.head.x and self.y == snake.head.y;
    }
};

pub const SnakeBodyPart = struct {
    const Self = @This();

    x: i32,
    y: i32,

    prevX: ?i32,
    prevY: ?i32,

    direction: Direction,
    prevDirection: Direction,

    prev: ?*SnakeBodyPart,
    next: ?*SnakeBodyPart,

    pub fn init(allocator: *std.mem.Allocator) !*SnakeBodyPart {
        var part: *SnakeBodyPart = try allocator.create(SnakeBodyPart);
        part.prev = null;
        part.next = null;
        part.direction = Direction.Top;
        part.prevDirection = Direction.Top;
        part.x = 0;
        part.y = 0;
        return part;
    }

    pub fn move(self: *Self) void {
        self.prevX = self.x;
        self.prevY = self.y;

        switch (self.direction) {
            Direction.Top => {
                self.y -= 1;
            },
            Direction.Bottom => {
                self.y += 1;
            },
            Direction.Left => {
                self.x -= 1;
            },
            Direction.Right => {
                self.x += 1;
            },
        }
    }

    pub fn render(self: *Self, renderer: anytype, rect: anytype) void {
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);

        rect.x = @intCast(c_int, self.x * CELL_SIZE);
        rect.y = @intCast(c_int, self.y * CELL_SIZE);

        _ = c.SDL_RenderDrawRect(renderer, rect);
    }

    pub fn updateDirection(self: *SnakeBodyPart) void {
        if (self.prev == null) return;

        var prev = self.prev orelse unreachable;

        self.prevDirection = self.direction;
        self.direction = prev.prevDirection;
    }
};

pub const Snake = struct {
    const Self = @This();

    head: *SnakeBodyPart,
    allocator: *std.mem.Allocator,
    wololo: u8 = 0,

    pub fn init(allocator: *std.mem.Allocator) !Snake {
        var head = try SnakeBodyPart.init(allocator);

        return Snake{
            .head = head,
            .allocator = allocator,
        };
    }

    pub fn changeDirection(self: *Self, event: anytype) void {
        const key = c.SDL_GetKeyName(event.key.keysym.sym)[0..5];

        // std.debug.print("\n Key pressed {any} ", .{key});
        self.head.prevDirection = self.head.direction;

        // Hoooly fuuu string lennn ???
        if (pressedKey(key[0..2], "Up")) {
            self.head.direction = Direction.Top;
        } else if (pressedKey(key[0..4], "Down")) {
            self.head.direction = Direction.Bottom;
        } else if (pressedKey(key[0..4], "Left")) {
            self.head.direction = Direction.Left;
        } else if (pressedKey(key[0..5], "Right")) {
            self.head.direction = Direction.Right;
        }
    }

    pub fn move(player: *Snake) void {
        player.forEachPart(SnakeBodyPart.move);
    }

    pub fn render(self: *Self, renderer: anytype) void {
        var rect = c.SDL_Rect{ .x = @intCast(c_int, 0), .y = @intCast(c_int, 0), .w = CELL_SIZE, .h = CELL_SIZE };

        var part: ?*SnakeBodyPart = self.head;
        while (part != null) : (part = part.?.next) {
            part.?.render(renderer, &rect);
        }
    }

    pub fn updateBodyPartsDirections(self: *Self) void {
        self.head.prevDirection = self.head.direction;
        self.forEachPart(SnakeBodyPart.updateDirection);
    }

    pub fn isOutOfBounds(self: *Self) bool {
        return self.head.x < 0 or self.head.x >= MAX_WIDTH or self.head.y < 0 or self.head.y >= MAX_WIDTH;
    }

    pub fn intersectsItself(self: *Self) !bool {
        var part: ?*SnakeBodyPart = self.head;
        while (part != null) : (part = part.?.next) {
            var segment = part orelse unreachable;
            var other: ?*SnakeBodyPart = segment.next;

            while (other != null) : (other = other.?.next) {
                if (segment.x == other.?.x and segment.y == other.?.y) {
                    return true;
                }
            }
        }

        return false;
    }

    pub fn grow(self: *Self, allocator: *std.mem.Allocator) !void {
        var part = try SnakeBodyPart.init(allocator);
        var last = self.getLastPart();

        part.direction = last.prevDirection;

        part.x = last.prevX orelse 0;
        part.y = last.prevY orelse 0;

        last.next = part;
        part.prev = last;
    }

    fn forEachPart(self: *Self, comptime function: fn (*SnakeBodyPart) void) void {
        var part: ?*SnakeBodyPart = self.head;
        while (part != null) : (part = part.?.next) {
            function(part orelse unreachable);
        }
    }

    fn getLastPart(self: *Self) *SnakeBodyPart {
        var part: ?*SnakeBodyPart = self.head;
        var last: ?*SnakeBodyPart = undefined;
        while (part != null) : (part = part.?.next) {
            if (part.?.next == null) {
                last = part;
            }
        }
        return last orelse self.head;
    }
};

fn pressedKey(pressedKeyName: []const u8, keyName: []const u8) bool {
    return std.mem.eql(u8, pressedKeyName, keyName);
}
