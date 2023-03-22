const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const os = std.os;
const testing = std.testing;

const TailQueue = std.TailQueue;

const ArrayList = std.ArrayList;

const ScreenWidth = @import("main.zig").ScreenWidth;
const ScreenHeight = @import("main.zig").ScreenHeight;

pub const CELL_SIZE = 10;

pub const Direction = enum(u8) { Top, Left, Right, Bottom };

pub const SnakeBodyPart = struct {
    x: i32,
    y: i32,
    direction: Direction,
};

pub const SnakeBody = std.ArrayList(SnakeBodyPart);

pub const Snake = struct {
    const Self = @This();
    body: *SnakeBody,
    head: *SnakeBodyPart,
    wololo: u8,
};

pub const Game = struct {
    const MAX_HEIGHT = @divTrunc(ScreenHeight, CELL_SIZE);
    const MAX_WIDTH = @divTrunc(ScreenWidth, CELL_SIZE);
    var player: Snake = undefined;

    pub fn createPlayer(x: i32, y: i32) !*Snake {
        const allocator = std.heap.page_allocator;
        var body = std.ArrayList(SnakeBodyPart).init(allocator);
        var head = SnakeBodyPart{ .x = x, .y = y, .direction = Direction.Top };
        // try body.append(head);
        player.body = &body;
        player.head = &head;
        std.debug.print("\n createPlayer head {}", .{player.head});
        return &player;
        // std.debug.print("Created {any} \n", .{player.head});
    }

    pub fn move() void {
        // var head = player.head.data;
        std.debug.print("\n items? {any} \n", .{player.head.*});
        // std.debug.print("first data? {any} \n", .{player.body.first.?.*.data});
        switch (player.head.direction) {
            Direction.Top => {
                player.head.y -= 1;
            },
            Direction.Bottom => {
                player.head.y += 1;
            },
            Direction.Left => {
                player.head.x -= 1;
            },
            Direction.Right => {
                player.head.x += 1;
            },
        }
    }

    pub fn processInput(event: anytype) void {
        const key = c.SDL_GetKeyName(event.key.keysym.sym)[0..5];

        std.debug.print("\n Key pressed {s} ", .{key});

        // var direction = player.head.data.direction;

        // Hoooly fuuu string lennn ???
        if (Game.keyPressed(key[0..2], "Up")) {
            // player.head.data.direction = Direction.Top;
        } else if (Game.keyPressed(key[0..4], "Down")) {
            // player.head.data.direction = Direction.Bottom;
        } else if (Game.keyPressed(key[0..4], "Left")) {
            // player.head.data.direction = Direction.Left;
        } else if (Game.keyPressed(key[0..5], "Right")) {
            // player.head.data.direction = Direction.Right;
        }
    }

    fn keyPressed(pressedKeyName: []const u8, keyName: []const u8) bool {
        return std.mem.eql(u8, pressedKeyName, keyName);
    }

    pub fn gameOver() bool {
        return false;
        // return player.head.data.x < 0 or player.head.data.x > MAX_WIDTH or player.head.data.y < 0 or player.head.data.y > MAX_WIDTH;
    }

    pub fn render(renderer: anytype) void {
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);

        var rect = c.SDL_Rect{ .x = @intCast(c_int, 0), .y = @intCast(c_int, 0), .w = CELL_SIZE, .h = CELL_SIZE };

        rect.x = @intCast(c_int, player.head.x * CELL_SIZE);
        rect.y = @intCast(c_int, player.head.y * CELL_SIZE);

        _ = c.SDL_RenderDrawRect(renderer, &rect);

        // var body = player.body.first;
        // std.debug.print("\n it {?}", .{it.?.data});
        // while (it) |node| : (it = node.next) {
        //     rect.x = @intCast(c_int, it.?.data.x * CELL_SIZE);
        //     rect.y = @intCast(c_int, it.?.data.y * CELL_SIZE);
        //     _ = c.SDL_RenderDrawRect(renderer, &rect);
        // }

        // for (player.body) |part| {
        //     rect.x = @intCast(c_int, part.x * CELL_SIZE);
        //     rect.y = @intCast(c_int, part.y * CELL_SIZE);
        //     _ = c.SDL_RenderDrawRect(renderer, &rect);
        // }
    }
};

test "Snake" {
    const player = Game.createPlayer(0, 0);

    try testing.expect(player.head().x == 0);
    try testing.expect(player.head().y == 0);
}
