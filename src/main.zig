const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const os = std.os;

const Game = @import("snake.zig").Game;

const CELL_SIZE = @import("snake.zig").CELL_SIZE;

var speed: f32 = 100;

const ErrorSet = error{SDLError};

pub const ScreenWidth = 600;
pub const ScreenHeight = 600;

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

    const centerX = @divTrunc(ScreenWidth, 2);
    const centerY = @divTrunc(ScreenHeight, 2);

    const player = try Game.createPlayer(@divTrunc(centerX, CELL_SIZE), @divTrunc(centerY, CELL_SIZE));
    std.debug.print("player created :: head {}", .{player.head});
    player.wololo = 2;

    while (!quit) {
        _ = c.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        _ = c.SDL_RenderClear(renderer);

        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_KEYDOWN => {
                    Game.processInput(event);
                },
                c.SDL_QUIT => {
                    quit = true;
                },
                else => {},
            }
        }

        Game.move();

        Game.render(renderer);

        if (Game.gameOver()) {
            quit = true;
        }

        _ = c.SDL_RenderPresent(renderer);

        c.SDL_Delay(100);
        speed -= 0.1;
    }
}
