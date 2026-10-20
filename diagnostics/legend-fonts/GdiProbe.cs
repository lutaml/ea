using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;
using System.Text;

public static class GdiProbe
{
    private const int MM_TEXT = 1;
    private const uint GDI_ERROR = 0xffffffff;
    private static readonly IntPtr HGDI_ERROR = new IntPtr(-1);

    public sealed class Measurement
    {
        public string RequestedFace;
        public string ActualFace;
        public int LogicalHeight;
        public int Weight;
        public bool Italic;
        public byte Charset;
        public string Text;
        public int Utf16Length;
        public int Width;
        public int Height;
        public int DpiX;
        public int DpiY;
        public int MappingMode;
        public int DrawTextWidth;
        public int DrawTextHeight;
        public string OutlineBoldStatus;
        public TextMetrics Metrics;
        public ushort[] GlyphIndices;
        public int[] MissingUtf16Indices;
        public CodepointMeasurement[] Codepoints;
    }

    public sealed class CodepointMeasurement
    {
        public int Codepoint;
        public string Unicode;
        public int Utf16Index;
        public int Utf16Length;
        public bool MissingInSelectedFace;
        public int? Width;
        public string WidthStatus;
        public int? WidthErrorCode;
        public int? AbcA;
        public uint? AbcB;
        public int? AbcC;
        public long? AbcAdvance;
        public string AbcStatus;
        public int? AbcErrorCode;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct Abc
    {
        public int A;
        public uint B;
        public int C;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct Rect
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct TextMetrics
    {
        public int Height;
        public int Ascent;
        public int Descent;
        public int InternalLeading;
        public int ExternalLeading;
        public int AverageCharWidth;
        public int MaximumCharWidth;
        public int Weight;
        public int Overhang;
        public int DigitizedAspectX;
        public int DigitizedAspectY;
        // TEXTMETRICW uses four 16-bit WCHARs, followed by five BYTEs.
        public ushort FirstChar;
        public ushort LastChar;
        public ushort DefaultChar;
        public ushort BreakChar;
        public byte Italic;
        public byte Underlined;
        public byte StruckOut;
        public byte PitchAndFamily;
        public byte Charset;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct Size
    {
        public int Width;
        public int Height;
    }

    public static Measurement Measure(string requestedFace, int logicalHeight,
        int weight, bool italic, byte charset, string text)
    {
        if (String.IsNullOrEmpty(requestedFace) || requestedFace.Length > 31 ||
            requestedFace.IndexOf('\0') >= 0)
            throw new ArgumentException("Face must contain 1 to 31 characters and no NUL.", "requestedFace");
        if (text == null)
            throw new ArgumentNullException("text");
        if (Marshal.SizeOf(typeof(TextMetrics)) != 60)
            throw new InvalidOperationException("TEXTMETRICW layout must be 60 bytes.");

        IntPtr dc = IntPtr.Zero;
        IntPtr font = IntPtr.Zero;
        IntPtr previousFont = IntPtr.Zero;
        Exception failure = null;
        try
        {
            dc = CreateCompatibleDC(IntPtr.Zero);
            if (dc == IntPtr.Zero) throw NativeFailure("CreateCompatibleDC");
            if (SetMapMode(dc, MM_TEXT) == 0) throw NativeFailure("SetMapMode");
            int mappingMode = GetMapMode(dc);
            if (mappingMode != MM_TEXT)
                throw new InvalidOperationException("GDI DC did not retain MM_TEXT mapping mode.");

            // Preserve the sign: negative heights request character height.
            font = CreateFontW(logicalHeight, 0, 0, 0, weight, italic ? 1u : 0u,
                0, 0, charset, 0, 0, 0, 0, requestedFace);
            if (font == IntPtr.Zero) throw NativeFailure("CreateFontW");
            previousFont = SelectObject(dc, font);
            if (InvalidObject(previousFont)) throw NativeFailure("SelectObject(font)");

            int faceLength = GetTextFaceW(dc, 0, null);
            if (faceLength <= 0) throw NativeFailure("GetTextFaceW(length)");
            StringBuilder actualFace = new StringBuilder(faceLength);
            if (GetTextFaceW(dc, actualFace.Capacity, actualFace) <= 0)
                throw NativeFailure("GetTextFaceW");

            Size extent;
            if (!GetTextExtentPoint32W(dc, text, text.Length, out extent))
                throw NativeFailure("GetTextExtentPoint32W");
            TextMetrics metrics;
            if (!GetTextMetricsW(dc, out metrics)) throw NativeFailure("GetTextMetricsW");
            int dpiX = GetDeviceCaps(dc, 88); // LOGPIXELSX
            int dpiY = GetDeviceCaps(dc, 90); // LOGPIXELSY
            if (dpiX <= 0 || dpiY <= 0)
                throw new InvalidOperationException("GetDeviceCaps returned invalid DPI.");

            ushort[] glyphs = new ushort[text.Length];
            if (text.Length > 0)
            {
                uint count = GetGlyphIndicesW(dc, text, text.Length, glyphs, 1);
                if (count == GDI_ERROR) throw NativeFailure("GetGlyphIndicesW");
                if (count != (uint)text.Length)
                    throw new InvalidOperationException("GetGlyphIndicesW returned an unexpected glyph count.");
            }
            List<int> missing = new List<int>();
            for (int i = 0; i < glyphs.Length; i++)
                if (glyphs[i] == 0xffff) missing.Add(i);

            List<CodepointMeasurement> codepoints = new List<CodepointMeasurement>();
            for (int i = 0; i < text.Length; i++)
            {
                bool pair = Char.IsHighSurrogate(text[i]) && i + 1 < text.Length &&
                    Char.IsLowSurrogate(text[i + 1]);
                int codepoint = pair ? Char.ConvertToUtf32(text[i], text[i + 1]) : text[i];
                CodepointMeasurement item = new CodepointMeasurement {
                    Codepoint = codepoint, Unicode = "U+" + codepoint.ToString("X4"),
                    Utf16Index = i, Utf16Length = pair ? 2 : 1,
                    MissingInSelectedFace = glyphs[i] == 0xffff || (pair && glyphs[i + 1] == 0xffff)
                };
                if (Char.IsSurrogate(text[i]))
                {
                    item.WidthStatus = item.AbcStatus = pair ?
                        "unsupported-supplementary-codepoint" : "unsupported-unpaired-surrogate";
                }
                else
                {
                    int width;
                    if (GetCharWidth32W(dc, (uint)codepoint, (uint)codepoint, out width))
                    {
                        item.Width = width;
                        item.WidthStatus = "ok";
                    }
                    else
                    {
                        item.WidthErrorCode = Marshal.GetLastWin32Error();
                        item.WidthStatus = "native-call-failed";
                    }
                    Abc abc;
                    if (GetCharABCWidthsW(dc, (uint)codepoint, (uint)codepoint, out abc))
                    {
                        item.AbcA = abc.A; item.AbcB = abc.B; item.AbcC = abc.C;
                        item.AbcAdvance = (long)abc.A + abc.B + abc.C;
                        item.AbcStatus = "ok";
                    }
                    else
                    {
                        item.AbcErrorCode = Marshal.GetLastWin32Error();
                        item.AbcStatus = "native-call-failed-or-font-unsupported";
                    }
                }
                codepoints.Add(item);
                if (pair) i++;
            }

            Rect drawRect = new Rect();
            // DrawText returns zero for empty input as well as for errors.
            if (text.Length > 0 && DrawTextW(dc, text, text.Length, ref drawRect, 0x20 | 0x400 | 0x800) == 0)
                throw NativeFailure("DrawTextW(DT_CALCRECT|DT_SINGLELINE|DT_NOPREFIX)");

            return new Measurement {
                RequestedFace = requestedFace, ActualFace = actualFace.ToString(),
                LogicalHeight = logicalHeight, Weight = weight, Italic = italic,
                Charset = charset, Text = text, Utf16Length = text.Length,
                Width = extent.Width, Height = extent.Height, DpiX = dpiX, DpiY = dpiY,
                MappingMode = mappingMode, Metrics = metrics, GlyphIndices = glyphs,
                MissingUtf16Indices = missing.ToArray(), Codepoints = codepoints.ToArray(),
                DrawTextWidth = drawRect.Right - drawRect.Left,
                DrawTextHeight = drawRect.Bottom - drawRect.Top,
                OutlineBoldStatus = "unsupported-not-probed-use-Metrics.Weight-and-glyph-evidence"
            };
        }
        catch (Exception ex)
        {
            failure = ex;
            throw;
        }
        finally
        {
            List<string> cleanupErrors = new List<string>();
            if (dc != IntPtr.Zero && !InvalidObject(previousFont))
                if (InvalidObject(SelectObject(dc, previousFont)))
                    cleanupErrors.Add("SelectObject(restore font)");
            if (dc != IntPtr.Zero && !DeleteDC(dc))
                cleanupErrors.Add("DeleteDC");
            // Destroy the DC first so the font is unselected even if restore failed.
            if (font != IntPtr.Zero && !DeleteObject(font))
                cleanupErrors.Add("DeleteObject(font)");
            if (cleanupErrors.Count > 0)
            {
                string operations = String.Join(", ", cleanupErrors.ToArray());
                if (failure == null)
                    throw new InvalidOperationException("GDI cleanup failed: " + operations);
                failure.Data["GdiCleanupFailures"] = operations;
            }
        }
    }

    public static int RegisterFont(string path)
    {
        if (String.IsNullOrEmpty(path)) throw new ArgumentException("Font path is required.", "path");
        int count = AddFontResourceExW(path, 0x10, IntPtr.Zero);
        if (count == 0) throw NativeFailure("AddFontResourceExW(FR_PRIVATE)");
        return count;
    }

    public static void UnregisterFont(string path)
    {
        if (String.IsNullOrEmpty(path)) throw new ArgumentException("Font path is required.", "path");
        if (!RemoveFontResourceExW(path, 0x10, IntPtr.Zero))
            throw NativeFailure("RemoveFontResourceExW(FR_PRIVATE)");
    }

    private static bool InvalidObject(IntPtr handle)
    {
        return handle == IntPtr.Zero || handle == HGDI_ERROR;
    }

    private static Exception NativeFailure(string operation)
    {
        return new Win32Exception(Marshal.GetLastWin32Error(), operation + " failed");
    }

    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern IntPtr CreateCompatibleDC(IntPtr hdc);
    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern int SetMapMode(IntPtr hdc, int mode);
    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern int GetMapMode(IntPtr hdc);
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
    private static extern IntPtr CreateFontW(int height, int width, int escapement,
        int orientation, int weight, uint italic, uint underline, uint strikeOut,
        uint charset, uint outputPrecision, uint clipPrecision, uint quality,
        uint pitchAndFamily, string faceName);
    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern IntPtr SelectObject(IntPtr hdc, IntPtr obj);
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
    private static extern int GetTextFaceW(IntPtr hdc, int count, StringBuilder faceName);
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetTextExtentPoint32W(IntPtr hdc, string text, int count, out Size size);
    [DllImport("gdi32.dll", ExactSpelling = true, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetTextMetricsW(IntPtr hdc, out TextMetrics metrics);
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
    private static extern uint GetGlyphIndicesW(IntPtr hdc, string text, int count,
        [Out] ushort[] glyphs, uint flags);
    [DllImport("gdi32.dll", SetLastError = true)]
    private static extern int GetDeviceCaps(IntPtr hdc, int index);
    [DllImport("gdi32.dll", ExactSpelling = true, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetCharWidth32W(IntPtr hdc, uint first, uint last, out int width);
    [DllImport("gdi32.dll", ExactSpelling = true, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool GetCharABCWidthsW(IntPtr hdc, uint first, uint last, out Abc abc);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
    private static extern int DrawTextW(IntPtr hdc, string text, int count, ref Rect rectangle, uint format);
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
    private static extern int AddFontResourceExW(string path, uint flags, IntPtr reserved);
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode, ExactSpelling = true, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool RemoveFontResourceExW(string path, uint flags, IntPtr reserved);
    [DllImport("gdi32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DeleteObject(IntPtr obj);
    [DllImport("gdi32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DeleteDC(IntPtr hdc);
}
