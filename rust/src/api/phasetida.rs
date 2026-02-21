use std::cell::RefCell;

use phasetida_core::BufferWithCursor;

const BUFFER_SIZE: usize = 16384;

thread_local! {
    static DRAW_BUFFER: RefCell<[u8; 16384]> = RefCell::new([0;16384]);
}

#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_level(json: String) -> Result<(f64, f64, i32), String> {
    phasetida_core::clear_states();
    phasetida_core::init_line_states_from_json(json)
        .map(|it| (it.length_in_second, it.offset, it.format_version))
        .map_err(|it| it.to_string())
}

#[flutter_rust_bridge::frb(sync)]
pub fn tick_lines(time_in_second: f64, delta_time_in_second: f64, auto: bool) -> [u8; 16384] {
    phasetida_core::tick_all(time_in_second, delta_time_in_second, auto);
    DRAW_BUFFER.with_borrow_mut(|it| {
        let mut buffer = BufferWrapper {
            buffer: it,
            cursor: 0,
        };
        phasetida_core::process_state_to_drawable(&mut buffer);
        it.clone()
    })
}

#[flutter_rust_bridge::frb(sync)]
pub fn touch_action(state: u8, id: u8, x: f32, y: f32) {
    let id = id as usize;
    match state {
        0 => phasetida_core::set_touch_down(id, x, y),
        1 => phasetida_core::set_touch_move(id, x, y),
        2 => phasetida_core::set_touch_up(id),
        _ => {}
    };
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_image_offset(
    hold_head_height: f64,
    hold_head_highlight_height: f64,
    hold_end_height: f64,
    hold_end_highlight_height: f64,
) {
    phasetida_core::load_image_offset(
        hold_head_height,
        hold_head_highlight_height,
        hold_end_height,
        hold_end_highlight_height,
    );
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_buffer_size() -> usize {
    BUFFER_SIZE
}

#[flutter_rust_bridge::frb(sync)]
pub fn reset_note_state(before_time_in_second: f64) {
    phasetida_core::reset_note_state(before_time_in_second);
}

#[flutter_rust_bridge::frb(sync)]
pub fn reset_touch_state() {
    phasetida_core::clear_touch();
}

#[flutter_rust_bridge::frb(sync)]
pub fn clear_states() {
    phasetida_core::clear_states();
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

struct BufferWrapper<'a> {
    cursor: usize,
    buffer: &'a mut [u8],
}

impl<'a> BufferWithCursor for BufferWrapper<'a> {
    fn write(&mut self, slice: &[u8]) {
        for it in slice.iter() {
            self.buffer[self.cursor] = *it;
            self.cursor += 1;
        }
    }
}
