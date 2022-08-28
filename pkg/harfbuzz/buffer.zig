const std = @import("std");
const c = @import("c.zig");
const common = @import("common.zig");
const Error = @import("errors.zig").Error;
const Direction = common.Direction;
const Script = common.Script;
const Language = common.Language;

/// Buffers serve a dual role in HarfBuzz; before shaping, they hold the
/// input characters that are passed to hb_shape(), and after shaping they
/// hold the output glyphs.
pub const Buffer = struct {
    handle: *c.hb_buffer_t,

    /// Creates a new hb_buffer_t with all properties to defaults.
    pub fn create() Error!Buffer {
        const handle = c.hb_buffer_create() orelse return Error.HarfbuzzFailed;
        return Buffer{ .handle = handle };
    }

    /// Deallocate the buffer . Decreases the reference count on buffer by one.
    /// If the result is zero, then buffer and all associated resources are
    /// freed. See hb_buffer_reference().
    pub fn destroy(self: *Buffer) void {
        c.hb_buffer_destroy(self.handle);
    }

    /// Resets the buffer to its initial status, as if it was just newly
    /// created with hb_buffer_create().
    pub fn reset(self: Buffer) void {
        c.hb_buffer_reset(self.handle);
    }

    /// Sets the type of buffer contents. Buffers are either empty, contain
    /// characters (before shaping), or contain glyphs (the result of shaping).
    pub fn setContentType(self: Buffer, ct: ContentType) void {
        c.hb_buffer_set_content_type(self.handle, @enumToInt(ct));
    }

    /// Fetches the type of buffer contents. Buffers are either empty, contain
    /// characters (before shaping), or contain glyphs (the result of shaping).
    pub fn getContentType(self: Buffer) ContentType {
        return @intToEnum(ContentType, c.hb_buffer_get_content_type(self.handle));
    }

    /// Appends a character with the Unicode value of codepoint to buffer,
    /// and gives it the initial cluster value of cluster . Clusters can be
    /// any thing the client wants, they are usually used to refer to the
    /// index of the character in the input text stream and are output in
    /// hb_glyph_info_t.cluster field.
    ///
    /// This function does not check the validity of codepoint, it is up to
    /// the caller to ensure it is a valid Unicode code point.
    pub fn add(self: Buffer, cp: u32, cluster: u32) void {
        c.hb_buffer_add(self.handle, cp, cluster);
    }

    /// Appends characters from text array to buffer . The item_offset is the
    /// position of the first character from text that will be appended, and
    /// item_length is the number of character. When shaping part of a larger
    /// text (e.g. a run of text from a paragraph), instead of passing just
    /// the substring corresponding to the run, it is preferable to pass the
    /// whole paragraph and specify the run start and length as item_offset and
    /// item_length , respectively, to give HarfBuzz the full context to be
    /// able, for example, to do cross-run Arabic shaping or properly handle
    /// combining marks at stat of run.
    ///
    /// This function does not check the validity of text , it is up to the
    /// caller to ensure it contains a valid Unicode code points.
    pub fn addCodepoints(self: Buffer, text: []const u32) void {
        c.hb_buffer_add_codepoints(
            self.handle,
            text.ptr,
            @intCast(c_int, text.len),
            0,
            @intCast(c_int, text.len),
        );
    }

    /// See hb_buffer_add_codepoints().
    ///
    /// Replaces invalid UTF-32 characters with the buffer replacement code
    /// point, see hb_buffer_set_replacement_codepoint().
    pub fn addUTF32(self: Buffer, text: []const u32) void {
        c.hb_buffer_add_utf32(
            self.handle,
            text.ptr,
            @intCast(c_int, text.len),
            0,
            @intCast(c_int, text.len),
        );
    }

    /// See hb_buffer_add_codepoints().
    ///
    /// Replaces invalid UTF-16 characters with the buffer replacement code
    /// point, see hb_buffer_set_replacement_codepoint().
    pub fn addUTF16(self: Buffer, text: []const u16) void {
        c.hb_buffer_add_utf16(
            self.handle,
            text.ptr,
            @intCast(c_int, text.len),
            0,
            @intCast(c_int, text.len),
        );
    }

    /// See hb_buffer_add_codepoints().
    ///
    /// Replaces invalid UTF-8 characters with the buffer replacement code
    /// point, see hb_buffer_set_replacement_codepoint().
    pub fn addUTF8(self: Buffer, text: []const u8) void {
        c.hb_buffer_add_utf8(
            self.handle,
            text.ptr,
            @intCast(c_int, text.len),
            0,
            @intCast(c_int, text.len),
        );
    }

    /// Similar to hb_buffer_add_codepoints(), but allows only access to first
    /// 256 Unicode code points that can fit in 8-bit strings.
    pub fn addLatin1(self: Buffer, text: []const u8) void {
        c.hb_buffer_add_latin1(
            self.handle,
            text.ptr,
            @intCast(c_int, text.len),
            0,
            @intCast(c_int, text.len),
        );
    }

    /// Set the text flow direction of the buffer. No shaping can happen
    /// without setting buffer direction, and it controls the visual direction
    /// for the output glyphs; for RTL direction the glyphs will be reversed.
    /// Many layout features depend on the proper setting of the direction,
    /// for example, reversing RTL text before shaping, then shaping with LTR
    /// direction is not the same as keeping the text in logical order and
    /// shaping with RTL direction.
    pub fn setDirection(self: Buffer, dir: Direction) void {
        c.hb_buffer_set_direction(self.handle, @enumToInt(dir));
    }

    /// See hb_buffer_set_direction()
    pub fn getDirection(self: Buffer) Direction {
        return @intToEnum(Direction, c.hb_buffer_get_direction(self.handle));
    }

    /// Sets the script of buffer to script.
    ///
    /// Script is crucial for choosing the proper shaping behaviour for
    /// scripts that require it (e.g. Arabic) and the which OpenType features
    /// defined in the font to be applied.
    ///
    /// You can pass one of the predefined hb_script_t values, or use
    /// hb_script_from_string() or hb_script_from_iso15924_tag() to get the
    /// corresponding script from an ISO 15924 script tag.
    pub fn setScript(self: Buffer, script: Script) void {
        c.hb_buffer_set_script(self.handle, @enumToInt(script));
    }

    /// See hb_buffer_set_script()
    pub fn getScript(self: Buffer) Script {
        return @intToEnum(Script, c.hb_buffer_get_script(self.handle));
    }

    /// Sets the language of buffer to language .
    ///
    /// Languages are crucial for selecting which OpenType feature to apply to
    /// the buffer which can result in applying language-specific behaviour.
    /// Languages are orthogonal to the scripts, and though they are related,
    /// they are different concepts and should not be confused with each other.
    ///
    /// Use hb_language_from_string() to convert from BCP 47 language tags to
    /// hb_language_t.
    pub fn setLanguage(self: Buffer, language: Language) void {
        c.hb_buffer_set_language(self.handle, language.handle);
    }

    /// See hb_buffer_set_language()
    pub fn getLanguage(self: Buffer) Language {
        return Language{ .handle = c.hb_buffer_get_language(self.handle) };
    }
};

/// The type of hb_buffer_t contents.
pub const ContentType = enum(u2) {
    /// Initial value for new buffer.
    invalid = c.HB_BUFFER_CONTENT_TYPE_INVALID,

    /// The buffer contains input characters (before shaping).
    unicode = c.HB_BUFFER_CONTENT_TYPE_UNICODE,

    /// The buffer contains output glyphs (after shaping).
    glyphs = c.HB_BUFFER_CONTENT_TYPE_GLYPHS,
};

test "create" {
    const testing = std.testing;

    var buffer = try Buffer.create();
    defer buffer.destroy();
    buffer.reset();

    // Content type
    buffer.setContentType(.unicode);
    try testing.expectEqual(ContentType.unicode, buffer.getContentType());

    // Try add functions
    buffer.add('🥹', 27);
    var utf32 = [_]u32{ 'A', 'B', 'C' };
    var utf16 = [_]u16{ 'A', 'B', 'C' };
    var utf8 = [_]u8{ 'A', 'B', 'C' };
    buffer.addCodepoints(&utf32);
    buffer.addUTF32(&utf32);
    buffer.addUTF16(&utf16);
    buffer.addUTF8(&utf8);
    buffer.addLatin1(&utf8);

    // Try to set properties
    buffer.setDirection(.ltr);
    try testing.expectEqual(Direction.ltr, buffer.getDirection());

    buffer.setScript(.arabic);
    try testing.expectEqual(Script.arabic, buffer.getScript());

    buffer.setLanguage(Language.fromString("en"));
}