const std = @import("std");
const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_ttf.h");
});

const ButtonType = enum {
    number,
    operator,
    theme,
};

const Button = struct {
    rect: c.SDL_Rect,
    text: []const u8,
    btn_type: ButtonType,
};

const WINDOW_WIDTH = 400;
const WINDOW_HEIGHT = 600;
const PADDING = 15;
const BUTTON_SIZE = 80;
const MARGIN = 20;

const display_rect = c.SDL_Rect{
    .x = MARGIN,
    .y = MARGIN + 50,
    .w = WINDOW_WIDTH - (MARGIN * 2),
    .h = 80,
};

const Theme = struct {
    background: c.SDL_Color,
    button_bg: c.SDL_Color,
    button_border: c.SDL_Color,
    text: c.SDL_Color,
};

const light_theme = Theme{
    .background = .{ .r = 240, .g = 240, .b = 240, .a = 255 },
    .button_bg = .{ .r = 220, .g = 220, .b = 220, .a = 255 },
    .button_border = .{ .r = 180, .g = 180, .b = 180, .a = 255 },
    .text = .{ .r = 0, .g = 0, .b = 0, .a = 255 },
};

const dark_theme = Theme{
    .background = .{ .r = 30, .g = 30, .b = 30, .a = 255 },
    .button_bg = .{ .r = 45, .g = 45, .b = 45, .a = 255 },
    .button_border = .{ .r = 70, .g = 70, .b = 70, .a = 255 },
    .text = .{ .r = 255, .g = 255, .b = 255, .a = 255 },
};

var is_dark_theme = true;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const font_paths = [_][]const u8{
        "/Library/Fonts/SF-Pro.ttf", // macOS
        "/Library/Fonts/SF-Pro-Italic.ttf", // macOS
        "/Library/Fonts/SourceCodePro-Regular.ttf", // macOS
        "/Library/Fonts/SourceCodePro-Bold.ttf", // macOS
        "/Library/Fonts/SourceCodePro-Italic.ttf", // macOS
        "/System/Library/Fonts/SFNS.ttf", // macOS
        "/System/Library/Fonts/SFNSItalic.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", // Linux
        "C:\\Windows\\Fonts\\arial.ttf", // Windows
    };

    var font_path: ?[]const u8 = null;
    for (font_paths) |path| {
        if (std.fs.accessAbsolute(path, .{})) {
            font_path = path;
            break;
        } else |_| {
            continue;
        }
    }

    if (font_path == null) {
        std.debug.print("Error: Could not find a suitable system font\n", .{});
        return error.FontNotFound;
    }

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    if (c.TTF_Init() != 0) {
        c.SDL_Log("Unable to initialize SDL_ttf: %s", c.TTF_GetError());
        return error.SDLTTFInitializationFailed;
    }
    defer c.TTF_Quit();

    const window = c.SDL_CreateWindow(
        "Calculator",
        c.SDL_WINDOWPOS_UNDEFINED,
        c.SDL_WINDOWPOS_UNDEFINED,
        WINDOW_WIDTH,
        WINDOW_HEIGHT,
        c.SDL_WINDOW_SHOWN,
    ) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLWindowCreationFailed;
    };
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLRendererCreationFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const font = c.TTF_OpenFont(font_path.?.ptr, 24) orelse {
        c.SDL_Log("Unable to load font: %s", c.TTF_GetError());
        return error.SDLFontLoadFailed;
    };
    defer c.TTF_CloseFont(font);

    const buttons = [_]Button{
        .{ .rect = .{ .x = MARGIN, .y = 150, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "7", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + BUTTON_SIZE + PADDING, .y = 150, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "8", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + (BUTTON_SIZE + PADDING) * 2, .y = 150, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "9", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + (BUTTON_SIZE + PADDING) * 3, .y = 150, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "/", .btn_type = .operator },

        .{ .rect = .{ .x = MARGIN, .y = 150 + BUTTON_SIZE + PADDING, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "4", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + BUTTON_SIZE + PADDING, .y = 150 + BUTTON_SIZE + PADDING, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "5", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + (BUTTON_SIZE + PADDING) * 2, .y = 150 + BUTTON_SIZE + PADDING, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "6", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + (BUTTON_SIZE + PADDING) * 3, .y = 150 + BUTTON_SIZE + PADDING, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "*", .btn_type = .operator },

        .{ .rect = .{ .x = MARGIN, .y = 150 + (BUTTON_SIZE + PADDING) * 2, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "1", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + BUTTON_SIZE + PADDING, .y = 150 + (BUTTON_SIZE + PADDING) * 2, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "2", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + (BUTTON_SIZE + PADDING) * 2, .y = 150 + (BUTTON_SIZE + PADDING) * 2, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "3", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + (BUTTON_SIZE + PADDING) * 3, .y = 150 + (BUTTON_SIZE + PADDING) * 2, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "-", .btn_type = .operator },

        .{ .rect = .{ .x = MARGIN, .y = 150 + (BUTTON_SIZE + PADDING) * 3, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "0", .btn_type = .number },
        .{ .rect = .{ .x = MARGIN + BUTTON_SIZE + PADDING, .y = 150 + (BUTTON_SIZE + PADDING) * 3, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "C", .btn_type = .operator },
        .{ .rect = .{ .x = MARGIN + (BUTTON_SIZE + PADDING) * 2, .y = 150 + (BUTTON_SIZE + PADDING) * 3, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "=", .btn_type = .operator },
        .{ .rect = .{ .x = MARGIN + (BUTTON_SIZE + PADDING) * 3, .y = 150 + (BUTTON_SIZE + PADDING) * 3, .w = BUTTON_SIZE, .h = BUTTON_SIZE }, .text = "+", .btn_type = .operator },

        .{ .rect = .{ .x = WINDOW_WIDTH - MARGIN - 80, .y = MARGIN, .w = 90, .h = 45 }, .text = "Theme", .btn_type = .theme },
    };

    var display = [_]u8{0} ** 16;
    var display_len: usize = 0;
    var first_operand: f64 = 0;
    var operator: u8 = 0;

    var quit = false;
    while (!quit) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    quit = true;
                },
                c.SDL_MOUSEBUTTONDOWN => {
                    const mouse_x = event.button.x;
                    const mouse_y = event.button.y;
                    for (buttons) |button| {
                        if (mouse_x >= button.rect.x and mouse_x < button.rect.x + button.rect.w and
                            mouse_y >= button.rect.y and mouse_y < button.rect.y + button.rect.h)
                        {
                            switch (button.btn_type) {
                                .theme => {
                                    is_dark_theme = !is_dark_theme;
                                },
                                .number, .operator => {
                                    if (button.text.len == 1) {
                                        handleButtonPress(button.text[0], &display, &display_len, &first_operand, &operator);
                                    }
                                },
                            }
                            break;
                        }
                    }
                },
                else => {},
            }
        }

        const theme = if (is_dark_theme) dark_theme else light_theme;
        _ = c.SDL_SetRenderDrawColor(renderer, theme.background.r, theme.background.g, theme.background.b, theme.background.a);
        _ = c.SDL_RenderClear(renderer);

        renderText(renderer, font, &display, 50, 50, theme);

        for (buttons) |button| {
            renderButton(renderer, font, button, theme);
        }

        c.SDL_RenderPresent(renderer);
        c.SDL_Delay(16);
    }
}

fn handleButtonPress(key: u8, display: []u8, display_len: *usize, first_operand: *f64, operator: *u8) void {
    switch (key) {
        '0'...'9' => {
            if (display_len.* < display.len - 1) {
                display[display_len.*] = key;
                display_len.* += 1;
                display[display_len.*] = 0;
            }
        },
        '+', '-', '*', '/' => {
            first_operand.* = std.fmt.parseFloat(f64, display[0..display_len.*]) catch 0;
            operator.* = key;
            display_len.* = 0;
        },
        '=' => {
            const second_operand = std.fmt.parseFloat(f64, display[0..display_len.*]) catch 0;
            const result = switch (operator.*) {
                '+' => first_operand.* + second_operand,
                '-' => first_operand.* - second_operand,
                '*' => first_operand.* * second_operand,
                '/' => if (second_operand != 0) first_operand.* / second_operand else 0,
                else => second_operand,
            };
            const formatted = std.fmt.bufPrint(display, "{d:.2}", .{result}) catch |err| {
                std.debug.print("Error formatting result: {}\n", .{err});
                return;
            };
            display_len.* = formatted.len;
        },
        'C' => {
            display_len.* = 0;
            first_operand.* = 0;
            operator.* = 0;
        },
        else => {},
    }
}

fn renderText(renderer: *c.SDL_Renderer, font: *c.TTF_Font, text: []const u8, x: c_int, y: c_int, theme: Theme) void {
    if (text.len == 0) return;

    const surface = c.TTF_RenderText_Blended(font, text.ptr, theme.text) orelse return;
    defer c.SDL_FreeSurface(surface);

    const texture = c.SDL_CreateTextureFromSurface(renderer, surface) orelse return;
    defer c.SDL_DestroyTexture(texture);

    var text_rect = c.SDL_Rect{ .x = x, .y = y, .w = surface.*.w, .h = surface.*.h };
    _ = c.SDL_RenderCopy(renderer, texture, null, &text_rect);
}

fn renderButton(renderer: *c.SDL_Renderer, font: *c.TTF_Font, button: Button, theme: Theme) void {
    _ = c.SDL_SetRenderDrawColor(renderer, theme.button_bg.r, theme.button_bg.g, theme.button_bg.b, theme.button_bg.a);
    _ = c.SDL_RenderFillRect(renderer, &button.rect);

    _ = c.SDL_SetRenderDrawColor(renderer, theme.button_border.r, theme.button_border.g, theme.button_border.b, theme.button_border.a);
    _ = c.SDL_RenderDrawRect(renderer, &button.rect);

    var w: c_int = undefined;
    var h: c_int = undefined;
    _ = c.TTF_SizeText(font, button.text.ptr, &w, &h);

    const padding: c_int = if (button.btn_type == .theme) 5 else 0;
    const text_x = button.rect.x + padding + @divFloor(button.rect.w - w - (padding * 2), 2);
    const text_y = button.rect.y + padding + @divFloor(button.rect.h - h - (padding * 2), 2);

    renderText(renderer, font, button.text, text_x, text_y, theme);
}
