const std = @import("std");
const testing = @import("std").testing;
const MultiArrayList = @import("std").MultiArrayList;

pub fn ComponentOf(comptime T: type) type {
    return struct {
        storage: MultiArrayList(T) = MultiArrayList(T){},
        const Self = @This();
        const alloc = std.heap.page_allocator;

        pub fn create(self: *Self, instance: T) !usize {
            try self.storage.append(alloc, instance);
            return self.storage.len;
        }

        pub fn free(self: *Self) void {
            self.storage.deinit(alloc);
        }
    };
}

test "define" {
    var positions = ComponentOf(struct {
        x: f32,
        y: f32,
    }){};
    errdefer positions.free();

    const id = try positions.create(.{ .x = 10, .y = 10 });

    std.debug.print("id {}", .{id});
    try testing.expectEqual(@as(usize, 1), positions.storage.items(.x).len);

    _ = try positions.create(.{ .x = 10, .y = 10 });
    try testing.expectEqual(@as(usize, 2), positions.storage.items(.x).len);
}

// test "insert elements" {
//     const ally = testing.allocator;

//     var positions = MultiArrayList(Position){};
//     defer positions.deinit(ally);

//     try positions.append(ally, .{ .x = 1, .y = 2 });
// }
// const Monster = struct {
//     element: enum { fire, water, earth, wind },
//     hp: u32,
// };

// const MonsterList = std.MultiArrayList(Monster);

// pub fn main() !void {
//     var gpa = std.heap.GeneralPurposeAllocator(.{}){};

//     var soa = MonsterList{};
//     defer soa.deinit(&gpa);

//     // Normally you would want to append many monsters
//     try soa.append(gpa, .{
//         .element = .fire,
//         .hp = 20,
//     });

//     // Count the number of fire monsters
//     var total_fire: usize = 0;
//     for (soa.items(.element)) |t| {
//         if (t == .fire) total_fire += 1;
//     }

//     // Heal all monsters
//     for (soa.items(.hp)) |*hp| {
//         hp.* = 100;
//     }
// }
