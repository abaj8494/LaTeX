#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Render a static map around an address using Cairo + OpenStreetMap raster tiles.

Usage:
  python cairo_osm_map.py --address "80 Anzac Avenue, West Ryde NSW 2114" \
      --width 1024 --height 1024 --zoom 17 --out map_westr yde.png

Notes:
- For one-off personal use, tiles from tile.openstreetmap.org are fine.
  For apps/heavier use, run your own tile server or use a paid provider.
- Required attribution is added automatically: "© OpenStreetMap contributors".
"""
import argparse
import io
import math
import sys
from typing import Tuple

import requests
from PIL import Image
import cairo

# -------------------- Config --------------------
TILE_URL = "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
UA = "cairo-osm-example/1.0 (+https://example.com; contact: local-user)"
TILE_SIZE = 256

# -------------------- Helpers --------------------
def geocode_nominatim(address: str) -> Tuple[float, float]:
    """Return (lat, lon) using Nominatim."""
    url = "https://nominatim.openstreetmap.org/search"
    params = {"q": address, "format": "json", "limit": 1}
    headers = {"User-Agent": UA}
    r = requests.get(url, params=params, headers=headers, timeout=15)
    r.raise_for_status()
    data = r.json()
    if not data:
        raise RuntimeError(f"Geocoding failed for address: {address}")
    lat = float(data[0]["lat"])
    lon = float(data[0]["lon"])
    return lat, lon

def deg2num(lat_deg: float, lon_deg: float, zoom: int) -> Tuple[int, int]:
    """Convert lat/lon to slippy tile x,y at given zoom."""
    lat_rad = math.radians(lat_deg)
    n = 2.0 ** zoom
    xtile = int((lon_deg + 180.0) / 360.0 * n)
    ytile = int((1.0 - math.log(math.tan(lat_rad) + 1.0 / math.cos(lat_rad)) / math.pi) / 2.0 * n)
    return xtile, ytile

def deg2pixel(lat_deg: float, lon_deg: float, zoom: int) -> Tuple[float, float]:
    """Pixel position in global mercator pixel space at given zoom (tile=256px)."""
    lat_rad = math.radians(lat_deg)
    n = 2.0 ** zoom
    x = (lon_deg + 180.0) / 360.0 * n * TILE_SIZE
    y = (1.0 - math.log(math.tan(lat_rad) + 1.0 / math.cos(lat_rad)) / math.pi) / 2.0 * n * TILE_SIZE
    return x, y

def meters_per_pixel(lat_deg: float, zoom: int) -> float:
    """Approx meters per pixel at given latitude & zoom for Web Mercator."""
    return 156543.03392 * math.cos(math.radians(lat_deg)) / (2 ** zoom)

def fetch_tile(z: int, x: int, y: int) -> Image.Image:
    """Fetch a single OSM tile and return as a PIL Image."""
    max_index = (1 << z)
    if y < 0 or y >= max_index:
        # Tile is outside the Mercator coverage; return empty
        return Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (255, 255, 255, 255))
    x = x % max_index  # wrap x around dateline
    url = TILE_URL.format(z=z, x=x, y=y)
    headers = {"User-Agent": UA, "Referer": "https://www.openstreetmap.org/"}
    r = requests.get(url, headers=headers, timeout=15)
    r.raise_for_status()
    img = Image.open(io.BytesIO(r.content)).convert("RGBA")
    return img

def pil_to_cairo_surface(img: Image.Image) -> cairo.ImageSurface:
    """Convert a RGBA PIL image to a Cairo ImageSurface."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    buf = img.tobytes("raw", "BGRA")
    surface = cairo.ImageSurface.create_for_data(bytearray(buf), cairo.FORMAT_ARGB32, img.width, img.height, img.width * 4)
    return surface

def draw_attribution(ctx: cairo.Context, width: int, height: int) -> None:
    text = "© OpenStreetMap contributors"
    margin = 10
    ctx.select_font_face("Helvetica", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
    ctx.set_font_size(14)
    xbearing, ybearing, tw, th, xa, ya = ctx.text_extents(text)
    ctx.set_source_rgba(1, 1, 1, 0.8)
    ctx.rectangle(width - tw - 2*margin, height - th - 2*margin, tw + 2*margin, th + 2*margin)
    ctx.fill()
    ctx.set_source_rgb(0, 0, 0)
    ctx.move_to(width - tw - margin, height - th - margin/2)
    ctx.show_text(text)

def draw_scale_bar(ctx: cairo.Context, width: int, height: int, lat: float, zoom: int) -> None:
    mpp = meters_per_pixel(lat, zoom)
    target_px = 200  # ~200 px bar
    meters = target_px * mpp
    # Round meters to nice numbers: 25, 50, 100, 200, 500, 1km, 2km
    nice = [25, 50, 100, 200, 500, 1000, 2000, 5000]
    meters_rounded = min(nice, key=lambda n: abs(n - meters))
    px = meters_rounded / mpp
    # draw bar
    margin = 20
    y = height - 50
    x = margin
    ctx.set_source_rgb(0, 0, 0)
    ctx.set_line_width(2)
    ctx.move_to(x, y)
    ctx.line_to(x + px, y)
    ctx.stroke()
    # end ticks
    for t in (x, x + px):
        ctx.move_to(t, y - 6); ctx.line_to(t, y + 6); ctx.stroke()
    # label
    label = f"{int(meters_rounded)} m" if meters_rounded < 1000 else f"{meters_rounded/1000:.1f} km"
    ctx.select_font_face("Helvetica", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_NORMAL)
    ctx.set_font_size(14)
    xb, yb, tw, th, xa, ya = ctx.text_extents(label)
    ctx.move_to(x + px/2 - tw/2, y - 8)
    ctx.show_text(label)

def render_map(address: str, out_png: str, out_pdf: str, width: int, height: int, zoom: int) -> None:
    lat, lon = geocode_nominatim(address)
    # Global pixel position of center
    center_px, center_py = deg2pixel(lat, lon, zoom)
    # Top-left global pixel we want
    top_left_x = int(center_px - width / 2)
    top_left_y = int(center_py - height / 2)

    # Prepare Cairo surface
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, width, height)
    ctx = cairo.Context(surface)

    # Determine tile ranges to cover the viewport
    start_xtile = top_left_x // TILE_SIZE
    start_ytile = top_left_y // TILE_SIZE
    end_xtile = (top_left_x + width) // TILE_SIZE
    end_ytile = (top_left_y + height) // TILE_SIZE

    # Paint tiles
    for ty in range(start_ytile, end_ytile + 1):
        for tx in range(start_xtile, end_xtile + 1):
            tile_img = fetch_tile(zoom, tx, ty)
            tile_surface = pil_to_cairo_surface(tile_img)
            # Position of this tile (top-left) in global pixel space
            tile_x_global = tx * TILE_SIZE
            tile_y_global = ty * TILE_SIZE
            # Position in local image
            dest_x = tile_x_global - top_left_x
            dest_y = tile_y_global - top_left_y
            ctx.save()
            ctx.translate(dest_x, dest_y)
            ctx.set_source_surface(tile_surface, 0, 0)
            ctx.paint()
            ctx.restore()

    # Draw marker for the address
    marker_px = center_px - top_left_x
    marker_py = center_py - top_left_y
    r_outer, r_inner = 9, 5
    # white halo
    ctx.set_source_rgb(1, 1, 1)
    ctx.arc(marker_px, marker_py, r_outer, 0, 2*math.pi)
    ctx.set_line_width(5)
    ctx.stroke()
    # black dot
    ctx.set_source_rgb(0, 0, 0)
    ctx.arc(marker_px, marker_py, r_inner, 0, 2*math.pi)
    ctx.fill()

    # Label
    ctx.select_font_face("Helvetica", cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
    ctx.set_font_size(18)
    label = address
    xb, yb, tw, th, xa, ya = ctx.text_extents(label)
    ox, oy = 12, -12  # offset from marker
    tx = marker_px + ox
    ty = marker_py + oy
    # Draw text background for legibility
    pad = 6
    ctx.set_source_rgba(1, 1, 1, 0.85)
    ctx.rectangle(tx - pad, ty - th - pad, tw + 2*pad, th + 2*pad)
    ctx.fill()
    # Text
    ctx.set_source_rgb(0, 0, 0)
    ctx.move_to(tx, ty)
    ctx.show_text(label)

    # Scale bar + attribution
    draw_scale_bar(ctx, width, height, lat, zoom)
    draw_attribution(ctx, width, height)

    # Write PNG
    surface.write_to_png(out_png)

    # Also write a PDF with the same pixels embedded (for vector-friendly output)
    pdf = cairo.PDFSurface(out_pdf, width, height)
    pdf_ctx = cairo.Context(pdf)
    # paint the raster surface onto the PDF
    pdf_ctx.set_source_surface(surface, 0, 0)
    pdf_ctx.paint()
    pdf.finish()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--address", required=True, help="Address to center the map on")
    ap.add_argument("--width", type=int, default=1024, help="Output width in px")
    ap.add_argument("--height", type=int, default=1024, help="Output height in px")
    ap.add_argument("--zoom", type=int, default=17, help="Zoom level (1-19 typical)")
    ap.add_argument("--out", default="map.png", help="Output PNG filename")
    ap.add_argument("--out_pdf", default="map.pdf", help="Output PDF filename")
    args = ap.parse_args()

    render_map(args.address, args.out, args.out_pdf, args.width, args.height, args.zoom)
    print(f"Wrote {args.out} and {args.out_pdf}")

if __name__ == "__main__":
    main()
