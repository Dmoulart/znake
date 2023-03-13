const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const os = std.os;

const ScreenWidth = @import("main.zig").ScreenWidth;
const ScreenHeight = @import("main.zig").ScreenHeight;

pub const CELL_SIZE = 10;

pub const Direction = enum(u8) { Top, Left, Right, Bottom };

pub const SnakeBodyPart = struct {
    x: i16,
    y: i16,
    direction: Direction,
};
pub const Snake = struct { head: SnakeBodyPart, tail: [10]SnakeBodyPart };

pub const Game = struct {
    const MAX_HEIGHT = @divTrunc(ScreenHeight, CELL_SIZE);
    const MAX_WIDTH = @divTrunc(ScreenWidth, CELL_SIZE);
    var player: Snake = undefined;

    pub fn createPlayer(x: i16, y: i16) void {
        player = Snake{ .head = SnakeBodyPart{
            .x = x,
            .y = y,
            .direction = Direction.Top,
        }, .tail = undefined };
    }

    pub fn move() void {
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

        // Hoooly fuuu string lennn ???
        if (Game.keyPressed(key[0..2], "Up")) {
            player.head.direction = Direction.Top;
        } else if (Game.keyPressed(key[0..4], "Down")) {
            player.head.direction = Direction.Bottom;
        } else if (Game.keyPressed(key[0..4], "Left")) {
            player.head.direction = Direction.Left;
        } else if (Game.keyPressed(key[0..5], "Right")) {
            player.head.direction = Direction.Right;
        }
    }

    fn keyPressed(pressedKeyName: []const u8, keyName: []const u8) bool {
        return std.mem.eql(u8, pressedKeyName, keyName);
    }

    pub fn gameOver() bool {
        return player.head.x < 0 or player.head.x > MAX_WIDTH or player.head.y < 0 or player.head.y > MAX_WIDTH;
    }

    pub fn render(renderer: anytype) void {
        _ = c.SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);

        var rect = c.SDL_Rect{ .x = @intCast(c_int, 0), .y = @intCast(c_int, 0), .w = CELL_SIZE, .h = CELL_SIZE };

        rect.x = @intCast(c_int, player.head.x * CELL_SIZE);
        rect.y = @intCast(c_int, player.head.y * CELL_SIZE);

        _ = c.SDL_RenderDrawRect(renderer, &rect);
    }
};
